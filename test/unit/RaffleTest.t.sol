// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
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

        /* EVENTS */
    event EnteredRaffle(address indexed participant);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deploy = new DeployRaffle();
        (helperConfig, raffle) = deploy.deployRaffle();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        keyHash = config.keyHash; // gas lane
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinator = config.vrfCoordinator;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    /** ============================================================================
    *                          🛠️  Constructor  🛠️
    *   ============================================================================ */

    function testCheckIfRaffleStateIntializedAsOPEN() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        //OR
        assert(uint256(raffle.getRaffleState()) == 0);
    }

    /** ============================================================================
    *                          🛠️  Enter Raffle  🛠️
    *   ============================================================================ */

    function testRaffleRevertsWhenDontSendEnoughEth() external {
        /**
         * vm.expectRevert(bytes4 selector)
         * - Tells Foundry to expect a revert with a specific custom error.
         * - Use this before calling a function that is expected to revert with a custom error.
         *
         * Syntax:
         *     vm.expectRevert(ContractName.CustomErrorName.selector);
         *
         * Explanation:
         * - In Solidity, custom errors are identified by a unique 4-byte selector.
         * - `.selector` gives you the function selector (first 4 bytes of the keccak256 hash of the error signature).
         * - Foundry uses this to match the exact custom error thrown by the function.
         *
         * Example:
         *     // Custom error in contract
         *     error Raffle__RaffleIsNotOpen();
         *
         *     // Expect the revert in test
         *     vm.expectRevert(Raffle.Raffle__RaffleIsNotOpen.selector);
         *     raffle.enterRaffle();  // This must revert with the above custom error
         *
         * Use Case:
         * - Ensures your contract reverts for the **right reason**, not just any revert.
         * - Great for precise unit testing of custom error handling logic.
         */

        //Arrange
        vm.prank(PLAYER);
        // Act, Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEth.selector);
        raffle.EnterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() external {
        //Arrange
        vm.prank(PLAYER);
        // Act
        raffle.EnterRaffle{value: entranceFee}();
        // Assert
        assert(raffle.getPlayer(0) == PLAYER);
    }

    function testRaffleEmitsEventOnEnter() external {
        //Arrange
        vm.prank(PLAYER);
        // Act
        /**
         * vm.expectEmit(
         *     checkTopic1,  // Checks the 1st indexed parameter of the emitted event (true to match, false to ignore)
         *     checkTopic2,  // Checks the 2nd indexed parameter (only if present in the event)
         *     checkTopic3,  // Checks the 3rd indexed parameter (only if present in the event)
         *     checkData,    // Checks the non-indexed data (true if your event has any non-indexed params you want to validate)
         *     emitter       // The address expected to emit the event (usually the contract under test)
         * );
         *
         * Details:
         * - Solidity events can have up to **3 indexed parameters** stored as topics.
         * - The first three booleans determine whether to match each of those indexed topics.
         * - The `checkData` flag tells Foundry whether to match the **non-indexed** event data.
         * - The `emitter` specifies the contract expected to emit the event — useful when multiple contracts could emit similar events.
         */
        vm.expectEmit(true,false,false,false,address(raffle));
        emit EnteredRaffle(address(PLAYER));
        //Assert
        raffle.EnterRaffle{value: entranceFee}();
    } 

    /** ============================================================================
    *                          🛠️  Perform Upkeep  🛠️
    *   ============================================================================ */

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() external {
        /**
         * vm.warp(uint256 timestamp)
         * - Sets the block timestamp (i.e., block.timestamp) to the specified value.
         * - Useful for testing time-dependent logic like unlock times, vesting, or timeouts.
         *
         * vm.roll(uint256 blockNumber)
         * - Sets the current block number (i.e., block.number) to the specified value.
         * - Useful for simulating chain progression, especially when block-based logic is used (e.g., mining rewards, block delays).
         *
         * Notes:
         * - Both functions only affect the **local test environment** and are extremely useful for simulating real-world blockchain behavior in unit tests.
         * - Use `vm.warp` to simulate the passage of **time** and `vm.roll` to simulate the passage of **blocks**.
         */

        //Arrange
        vm.prank(PLAYER);
        // Act
        raffle.EnterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        // Assert
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__RaffleIsNotOpen.selector);
        raffle.EnterRaffle{value: entranceFee}();
    }
    /** ============================================================================
    *                          🛠️  Check Upkeep  🛠️
    *   ============================================================================ */

    function testCheckUpKeepReturnsFalseIfHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepWhenRaffleIsntOpen() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.EnterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfEnoughTimeHasPassed() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.EnterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval - 10);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsTrueWhenAllParamsSatisified() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.EnterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded);
    }

}