pragma solidity ^0.8.13;

import "./interfaces/IIntentManager.sol";

contract IntentManager is IIntentManager {
    uint public intentCount;
    uint public minExpiry;
    // uint public maxExpiry;
    address public routerAddress;
    mapping(uint => Intent) public intents;
    mapping(address => bool) public tokenWhitelist;
    mapping(address => uint) public minTokenAmount;

    constructor() {}

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
            intentId,
            _amount,
            _validFrom,
            _expiry,
            keccak256(
                abi.encodePacked(
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
        emit IntentCreated(
            msg.sender,
            intentId,
            _token,
            _amount,
            _validFrom,
            _expiry,
            keccak256(
                abi.encodePacked(
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
}
