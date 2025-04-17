// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle contract
 * @author Siddharth Jain
 * @notice
 * @dev Implementation of Raffle contract
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__NotEnoughEth();

    /* State variables */
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant NUM_WORDS = 1;

    address payable[] private s_participants; // payable, because we'll send reward money to the winner of raffle

    /* EVENTS */
    event EnteredRaffle(address indexed participant);

    constructor(uint256 _entranceFee, uint256 _interval, address _vrfCoordinator, uint256 _subscriptionId, bytes32 _keyHash, uint32 _callbackGasLimit)
        VRFConsumerBaseV2Plus(_vrfCoordinator)
    {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
        i_subscriptionId = _subscriptionId;
        i_keyHash = _keyHash;
        i_callbackGasLimit = _callbackGasLimit;
    }

    function EnterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH to participate");

        //from verion 0.8.0
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth();
        }

        // //from version 0.8.26 (less gas efficient than above's method)
        // require(msg.value >= i_entranceFee, NotEnoughEth());

        s_participants.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    // 1. Get a random number
    // 2. Use this random number to pick the winner
    // 3. Be automatically called
    function SelectWinner() external {
        //  check if enough time has passed to run a new lottery
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        // 1. Get a random number
        // i. Request an RNG (Random Number Generator)
        // ii. Get a random number from RNG

        // Create a new request struct for requesting randomness
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            // 🔑 Gas lane key hash – defines which Chainlink job to call
            // Also indirectly sets the max gas price you're willing to pay
            keyHash: i_keyHash,
            // 💰 Subscription ID used to pay for the request
            // Must be funded with LINK (or ETH if nativePayment is true)
            subId: i_subscriptionId,
            // ⏳ Number of block confirmations to wait before fulfilling the request
            // Higher = more secure randomness, but also slower
            requestConfirmations: REQUEST_CONFIRMATIONS,
            // ⛽ Max gas allowed for the callback (fulfillRandomWords function)
            // Needs to be high enough to avoid running out of gas
            callbackGasLimit: i_callbackGasLimit,
            // 🎲 Number of random words (uint32) to request
            // You can request multiple for better gas efficiency
            numWords: NUM_WORDS,
            // 🧩 Extra arguments (encoded)
            // Here, nativePayment: false → using LINK for payment instead of ETH
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        // 🎯 Submit the request to Chainlink VRF Coordinator
        // This kicks off the randomness generation process
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override{} // Added this because it was not compiling if this was missing

    // Getter Functions

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
