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

    function executeIntent(uint _intentId) external returns (bool);

    function reclaimFunds(uint _intentId) external returns (bool);

    // function revokeIntent(
    //     uint _intentId
    // ) external returns (bool);

    // ### view functions ###

    function getIntent(uint _intentId) external view returns (Intent memory);

    // ### Admin functions ###

    // setRouterAddress
    // setMinExpiry
    // setMaxExpiry
    // setMinAmount
    // whitelistToken

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
        address indexed user,
        address indexed agent,
        uint indexed intentId,
        bytes32 intentHash
    );

    event FundsReclaimed(
        address indexed user,
        uint indexed intentId,
        bytes32 intentHash
    );
}
