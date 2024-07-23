pragma solidity ^0.8.20;

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
        address token,
        uint amount,
        uint validFrom,
        uint expiry,
        bytes memory intent
    ) external returns (uint);

    function executeIntent(
        uint intentId,
        address agent,
        address user,
        address token,
        uint amount,
        uint validFrom,
        uint expiry,
        bytes calldata intent
    ) external;

    function reclaimTokens(uint intentId) external;

    // function revokeIntent(
    //     uint intentId
    // ) external returns (bool);

    // ### view functions ###

    function getIntent(uint intentId) external view returns (Intent memory);

    function isValidIntent(
        uint intentId,
        address user,
        address token,
        uint amount,
        uint validFrom,
        uint expiry,
        bytes calldata intent
    ) external view returns (bool);

    // ### Admin functions ###

    function setMinExpiry(uint minExpiry) external;

    function whitelistToken(
        address token,
        bool isWhitelisted,
        uint minAmount
    ) external;

    function whitelistExecutor(address executor, bool isWhitelisted) external;

    function setMinTokenAmount(address token, uint minAmount) external;

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
