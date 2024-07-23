pragma solidity ^0.8.13;

enum IntentState {
    Active,
    Expired,
    Executed
    // Executed,
    // Revoked
}

struct Intent {
    address user;
    address token;
    address agent;
    uint intentId;
    uint amount;
    uint validFrom;
    uint expiry;
    bytes32 intentHash;
    IntentState state;
    bytes intent;
}

interface IIntentManager {
    function createIntent(
        address _token,
        uint _amount,
        uint _validFrom,
        uint _expiry,
        bytes memory _intent
    ) external returns (uint);

    function executeIntent(
        uint _intentId,
        address _agent,
        address _user,
        address _token,
        uint _amount,
        uint _validFrom,
        uint _expiry,
        bytes calldata _intent
    ) external;

    function reclaimTokens(uint _intentId) external;

    // function revokeIntent(
    //     uint _intentId
    // ) external returns (bool);

    // ### view functions ###

    function getIntent(uint _intentId) external view returns (Intent memory);

    function isValidIntent(
        uint _intentId,
        address _user,
        address _token,
        uint _amount,
        uint _validFrom,
        uint _expiry,
        bytes calldata _intent
    ) external view returns (bool);

    // ### Admin functions ###

    function setMinExpiry(uint _minExpiry) external;

    function whitelistToken(
        address _token,
        bool _isWhitelisted,
        uint _minAmount
    ) external;

    function whitelistExecutor(address _executor, bool _isWhitelisted) external;

    function setMinTokenAmount(address _token, uint _minAmount) external;

    // ### Events ###
    event IntentCreated(
        address indexed user,
        uint indexed intentId,
        address indexed token,
        uint amount,
        uint validFrom,
        uint expiry,
        bytes32 intentHash,
        bytes intent
    );

    event IntentExecuted(
        uint indexed intentId,
        address indexed agent,
        address indexed user,
        bytes32 intentHash,
        address token,
        uint amount,
        uint executedAt
    );

    event TokensReclaimed(
        uint indexed intentId,
        address indexed user,
        address indexed token,
        uint amount
    );
}
