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

/**
 * @title Raffle contract
 * @author Siddharth Jain
 * @notice 
 * @dev Implementation of Raffle contract
 */ 
contract Raffle {
    /* Errors */
    error Raffle__NotEnoughEth();

    uint256 private immutable i_entranceFee;
    address payable[] private s_participants; // payable, because we'll send reward money to the winner of raffle

    /* EVENTS */
    event EnteredRaffle(address indexed participant);


    constructor(uint256 _entranceFee) {
        i_entranceFee = _entranceFee;
    }

    function EnterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH to participate");

        //from verion 0.8.0
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth();
        }

        // //from version 0.8.26 (less gas efficient than above's method)
        // require(msg.value >= i_entranceFee, NotEnoughEth());

        s_participants.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function SelectWinner() public {

    }





    // Getter Functions

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}