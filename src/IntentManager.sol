pragma solidity ^0.8.13;

import "./interfaces/IIntentManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IntentManager is IIntentManager {
    using SafeERC20 for IERC20;

    uint public intentCount;
    uint public minExpiry;
    // uint public maxExpiry;
    address public admin;
    mapping(uint => Intent) public intents;
    mapping(address => bool) public executorWhitelist;
    mapping(address => bool) public tokenWhitelist;
    mapping(address => uint) public minTokenAmount;

    constructor() {
        admin = msg.sender;
    }

    // ### Modifiers ###

    modifier onlyWhitelistedExecutors() {
        require(
            executorWhitelist[msg.sender],
            "IntentManager: Only whitelisted executor"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "IntentManager: Only Admin");
        _;
    }

    // ### Public functions ###
    function createIntent(
        address _token,
        uint _amount,
        uint _validFrom,
        uint _expiry,
        bytes memory _intent
    ) external override returns (uint intentId) {
        require(
            _expiry > _validFrom && _expiry >= block.timestamp,
            "IntentManager: invalid expiry"
        );
        require(
            _expiry - block.timestamp >= minExpiry,
            "IntentManager: expiry too low"
        );
        require(tokenWhitelist[_token], "IntentManager: token not whitelisted");
        require(
            _amount >= minTokenAmount[_token],
            "IntentManager: amount too low"
        );

        intentId = intentCount++;
        intents[intentId] = Intent(
            msg.sender,
            _token,
            address(0),
            intentId,
            _amount,
            _validFrom,
            _expiry,
            keccak256(
                abi.encode(
                    msg.sender,
                    _token,
                    _amount,
                    _validFrom,
                    _expiry,
                    _intent
                )
            ),
            IntentState.Active,
            _intent
        );
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit IntentCreated(
            msg.sender,
            intentId,
            _token,
            _amount,
            _validFrom,
            _expiry,
            keccak256(
                abi.encode(
                    msg.sender,
                    _token,
                    _amount,
                    _validFrom,
                    _expiry,
                    _intent
                )
            ),
            _intent
        );
    }

    function executeIntent(
        uint _intentId,
        address _agent,
        address _user,
        address _token,
        uint _amount,
        uint _validFrom,
        uint _expiry,
        bytes calldata _intent
    ) external override onlyWhitelistedExecutors {
        Intent storage intent = intents[_intentId];
        require(
            _intentId <= intentCount &&
                _isValidIntentHash(
                    intent.intentHash,
                    _user,
                    _token,
                    _amount,
                    _validFrom,
                    _expiry,
                    _intent
                ),
            "IntentManager: invalid intent"
        );
        require(
            intent.state == IntentState.Active,
            "IntentManager: Inactive intent"
        );
        require(
            block.timestamp >= intent.validFrom &&
                block.timestamp <= intent.expiry,
            "IntentManager: intent expired / early execution"
        );
        intent.state = IntentState.Executed;
        intent.agent = _agent;
        IERC20(intent.token).safeTransfer(msg.sender, intent.amount);
        emit IntentExecuted(
            _intentId,
            _agent,
            _user,
            intent.intentHash,
            _token,
            _amount,
            block.timestamp
        );
    }

    function reclaimTokens(uint _intentId) external override {
        require(_intentId <= intentCount, "IntentManager: Invalid intentId");
        require(
            intents[_intentId].user == msg.sender,
            "IntentManager: Not Intent owner"
        );
        require(
            intents[_intentId].state == IntentState.Active,
            "IntentManager: Inactive intent"
        );
        require(
            block.timestamp > intents[_intentId].expiry,
            "IntentManager: Intent not expired"
        );
        intents[_intentId].state = IntentState.Expired;
        IERC20(intents[_intentId].token).safeTransfer(
            msg.sender,
            intents[_intentId].amount
        );
        emit TokensReclaimed(
            _intentId,
            msg.sender,
            intents[_intentId].token,
            intents[_intentId].amount
        );
    }

    // ### View functions ###

    function getIntent(
        uint _intentId
    ) public view override returns (Intent memory) {
        return intents[_intentId];
    }

    function isValidIntent(
        uint _intentId,
        address _user,
        address _token,
        uint _amount,
        uint _validFrom,
        uint _expiry,
        bytes calldata _intent
    ) external view override returns (bool) {
        return
            _intentId <= intentCount &&
            _isValidIntentHash(
                intents[_intentId].intentHash,
                _user,
                _token,
                _amount,
                _validFrom,
                _expiry,
                _intent
            );
    }

    // ### Admin functions ###

    function setMinExpiry(uint _minExpiry) external override onlyAdmin {
        require(_minExpiry > 0, "IntentManager: zero expiry");
        minExpiry = _minExpiry;
    }

    function whitelistToken(
        address _token,
        bool _isWhitelisted,
        uint _minAmount
    ) external override onlyAdmin {
        require(_token != address(0), "IntentManager: zero address");
        tokenWhitelist[_token] = _isWhitelisted;
        minTokenAmount[_token] = _minAmount;
    }

    function whitelistExecutor(
        address _executor,
        bool _isWhitelisted
    ) external override onlyAdmin {
        require(_executor != address(0), "IntentManager: zero address");
        executorWhitelist[_executor] = _isWhitelisted;
    }

    function setMinTokenAmount(
        address _token,
        uint _minAmount
    ) external override onlyAdmin {
        require(tokenWhitelist[_token], "IntentManager: token not whitelisted");
        minTokenAmount[_token] = _minAmount;
    }

    //### Private functions ###
    function _isValidIntentHash(
        bytes32 _intentHash,
        address _user,
        address _token,
        uint _amount,
        uint _validFrom,
        uint _expiry,
        bytes calldata _intent
    ) private pure returns (bool) {
        return
            keccak256(
                abi.encode(_user, _token, _amount, _validFrom, _expiry, _intent)
            ) == _intentHash;
    }
}
