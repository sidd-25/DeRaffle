// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    bytes32 keyHash;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address vrfCoordinator;
    
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deploy = new DeployRaffle();
        (helperConfig, raffle) = deploy.deployRaffle();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        keyHash = config.keyHash;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinator = config.vrfCoordinator;
    }

    function testCheckIfRaffleStateIntializedAsOPEN() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        //OR
        assert(uint256(raffle.getRaffleState()) == 0);
    }

    function testRaffleRevertsWhenDontSendEnoughEth() external {
        //Arrange
        vm.prank(PLAYER);
        // Act, Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEth.selector);
        raffle.EnterRaffle();
    }

}