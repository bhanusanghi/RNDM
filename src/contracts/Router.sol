pragma solidity ^0.8.20;
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {IIntentManager} from "../interfaces/IIntentManager.sol";

contract Router is IRouter {
    using SafeERC20 for IERC20;
    address public admin;
    IIntentManager public intentManager;
    mapping(address => bool) public vaultWhitelist;
    mapping(address => bool) public curatorWhitelist;
    // This is the fee that the Router awards to agents for executing intents. Its in absolute value, not percentage.
    mapping(address => uint256) public intentExecutionFee;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Router: Only Admin");
        _;
    }
    modifier onlyWhitelistedVaults(address vault) {
        require(vaultWhitelist[vault], "Router: Only whitelisted vaults");
        _;
    }
    modifier onlyWhitelistedCurators() {
        require(
            curatorWhitelist[msg.sender],
            "Router: Only whitelisted curators"
        );
        _;
    }

    constructor(address _intentManager) {
        admin = msg.sender;
        intentManager = IIntentManager(_intentManager);
    }

    function executeIntent(
        uint intentId,
        address agent,
        address user,
        address token,
        uint amount,
        uint validFrom,
        uint expiry,
        bytes calldata intent,
        address[] memory vaults,
        uint[] memory depositAmounts
    ) external override onlyWhitelistedCurators {
        uint totalAmountProcessed;
        require(
            vaults.length == depositAmounts.length && vaults.length > 0,
            "Router: Invalid input"
        );
        // Checks if the intent is valid
        // updates the intent state to executed
        // transfers token from user to Router
        intentManager.executeIntent(
            intentId,
            agent,
            user,
            token,
            amount,
            validFrom,
            expiry,
            intent
        );
        // Transfers fee from Router to agent
        totalAmountProcessed += intentExecutionFee[token];
        IERC20(token).safeTransfer(agent, intentExecutionFee[token]);
        // Deposits the token to the vaults

        for (uint i = 0; i < vaults.length; i++) {
            require(vaultWhitelist[vaults[i]], "Router: Vault not whitelisted");
            require(
                token == IERC4626(vaults[i]).asset(),
                "Router: Token != vault asset"
            );
            totalAmountProcessed += depositAmounts[i];
            IERC20(token).approve(vaults[i], depositAmounts[i]);
            IERC4626(vaults[i]).deposit(depositAmounts[i], user);
        }
        // Invariant check -  totalAmountProcessed is equal to the amount in the intent
        require(
            totalAmountProcessed == amount,
            "Router: Total amount processed != intent amount"
        );
    }

    // The owner needs to approve the Router to spend the shares
    function withdraw(
        IERC4626 vault,
        uint256 assets,
        address receiver,
        address owner
    )
        external
        override
        onlyWhitelistedVaults(address(vault))
        returns (uint256 shares)
    {
        shares = vault.withdraw(assets, receiver, owner);
    }

    // The owner needs to approve the Router to spend the shares
    function redeem(
        IERC4626 vault,
        uint256 shares,
        address receiver,
        address owner
    )
        external
        override
        onlyWhitelistedVaults(address(vault))
        returns (uint256 assets)
    {
        assets = vault.redeem(shares, receiver, owner);
    }

    // ### view function ###

    function isWhitelistedVault(
        address vault
    ) external view override returns (bool) {
        return vaultWhitelist[vault];
    }

    function isWhitelistedCurator(
        address curator
    ) external view override returns (bool) {
        return curatorWhitelist[curator];
    }

    function getExecutionFee(
        address token
    ) external view override returns (uint256) {
        return intentExecutionFee[token];
    }

    // ### admin function ###

    function whitelistVault(
        address vault,
        bool isWhitelisted
    ) external override onlyAdmin {
        require(vault != address(0), "Router: zero address");
        vaultWhitelist[vault] = isWhitelisted;
    }

    function whitelistCurator(
        address curator,
        bool isWhitelisted
    ) external override onlyAdmin {
        require(curator != address(0), "Router: zero address");
        curatorWhitelist[curator] = isWhitelisted;
    }

    function setIntentExecutionFee(
        address token,
        uint256 fee
    ) external override onlyAdmin {
        intentExecutionFee[token] = fee;
    }

    function setIntentManager(
        address _intentManager
    ) external override onlyAdmin {
        require(_intentManager != address(0), "Router: zero address");
        intentManager = IIntentManager(_intentManager);
    }

    function setAdmin(address newAdmin) external override onlyAdmin {
        require(newAdmin != address(0), "Router: zero address");
        admin = newAdmin;
    }
}

// Notes :
// what happens when you update the intent manager with pending intents.
// what happens when you remove an earlier whitelisted vault.
// Make the contract pausable
