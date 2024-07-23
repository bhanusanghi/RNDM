pragma solidity ^0.8.20;
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IRouter {
    // ### user functions ###

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
        uint[] memory despositAmounts
    ) external;

    /** 
     @notice withdraw `amount` from an ERC4626 vault.
     @param vault The ERC4626 vault to withdraw assets from.
     @param assets The amount of assets to withdraw from vault.
     @param receiver The destination of assets.
     @param owner The owner of shares.
     @return shares the amount of shares received by `receiver`.
     @dev The owner needs to approve the Router to spend enough shares.
    */
    function withdraw(
        IERC4626 vault,
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /** 
     @notice redeem `shares` shares from an ERC4626 vault.
     @param vault The ERC4626 vault to redeem shares from.
     @param receiver The destination of assets.
     @param owner The owner of shares.
     @param shares The amount of shares to redeem from vault.
     @return assets the amount of assets received by `receiver`.
     @dev The owner needs to approve the Router to spend enough shares.
    */
    function redeem(
        IERC4626 vault,
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    // ### view functions ###

    function isWhitelistedVault(address vault) external view returns (bool);

    function isWhitelistedCurator(address curator) external view returns (bool);

    function getExecutionFee(address token) external view returns (uint256);

    // ### admin function ###

    function whitelistVault(address vault, bool isWhitelisted) external;

    function whitelistCurator(address curator, bool isWhitelisted) external;

    function setIntentExecutionFee(address token, uint256 fee) external;

    function setIntentManager(address intentManager) external;

    function setAdmin(address newAdmin) external;
}
