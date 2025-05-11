// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    
    Raffle raffle;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig config;

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
        (helperConfig, raffle, config) = deploy.deployRaffle();

        entranceFee = config.entranceFee;
        interval = config.interval;
        keyHash = config.keyHash; // gas lane
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinator = 0x34A1D3fff3958843C43aD80F30b94c510645C316;

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

    /** ============================================================================
    *                          🛠️  Perform Upkeep  🛠️
    *   ============================================================================ */

    function testCheckPerformUpkeepOnlyIfCheckUpKeepIsTrue() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.EnterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        raffle.performUpkeep("");
        // if able to execute the function successfully, means checkUpkeep is true
    }

    function testPerformUpKeepRevertsIfUpKeepIsNotNeeded() public {
        // Testing the revert - custom error with params
        // Arrange
        uint256 balance = 0;
        uint256 players_array_length = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.EnterRaffle{value: entranceFee}();
        balance = balance + entranceFee;
        players_array_length = 1;

        // Act / Assert
        /* For custom errors with arguments
        vm.expectRevert(
            abi.encodeWithSelector(CustomErrorName.selector, 1, 2, 3, 4...)
        );
        1,2,3,4... are the arguments
        */
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__PerformUpkeepNotNeeded.selector, balance, players_array_length, rState)
        );
        raffle.performUpkeep("");
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitsRequestId() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.EnterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        /**
         * 🧪 vm.recordLogs() — Captures all events emitted during this transaction.
         * - Use vm.getRecordedLogs() to retrieve them after execution.
         * - Logs are returned as Vm.Log structs:
         *     struct Log {
         *         bytes32[] topics;
         *         bytes data;
         *         address emitter;
         *     }
         *
         * Log flow in this test:
         * - entries[0] → Internal VRFCoordinator event (ignore)
         * - entries[1] → Our contract's `RequestedRaffleWinner` event
         *     topics[0] → keccak256 of event signature (can ignore)
         *     topics[1] → requestId (indexed param we're interested in)
         *     data      → empty (since requestId is indexed)
         *
         * We extract requestId from: entries[1].topics[1]
         */
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Debug logs
        console2.log("Total events emitted: %s", entries.length);
        console2.log("Event Signature Hash (topics[0]):");
        console2.logBytes32(entries[1].topics[0]);
        console2.log("Request ID (topics[0]):");
        console2.logBytes32(requestId);

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(raffleState == Raffle.RaffleState.CALCULATING);
    }

    modifier enteredRaffle() {
        vm.prank(PLAYER);
        raffle.EnterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }
    
    /** ============================================================================
    *                          🛠️  FulfillRandomWords  🛠️
    *   ============================================================================ */

/*    function testFulFillRandomWordsCanOnlyBeCalledAfterPerformUpkeep() public enteredRaffle {

        // Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(0, address(raffle));

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1, address(raffle));

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(2, address(raffle));

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(3, address(raffle));

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(4, address(raffle));

    } Instead of this use a fuzz test like below */

    /**
     * 🧪 Fuzz Testing in Foundry
     *
     * - Fuzz tests run at the file level, not just per function.
     * - Foundry automatically generates random inputs for all test functions
     *   that accept parameters and follow the `test*` naming convention.
     * - These tests help uncover edge cases by exploring a wide range of inputs.
     * - All eligible functions in the file are executed with fuzzed data.
     *
     * Useful for validating robustness against unexpected inputs.
     */
    function testFulFillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 RandomNums) public enteredRaffle {

        // Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(RandomNums, address(raffle));        
    }

    function testFulFillRandomWordsPickWinnerResetsArrayAndSendMoney() public enteredRaffle {

        // Arrange
        uint256 additionalEntrant = 3; // total 4
        for (uint256 i = 1; i <= additionalEntrant; i++){
            address newPlayer = address(uint160(i)); // convert any number to address, dont start with 0
            hoax(newPlayer, 1 ether);
            raffle.EnterRaffle{value: entranceFee}();
        }
        uint256 startingTimestamp = raffle.getLastTimestamp();
        address expectedWinner = address(1);
        uint256 winnerStartingBalance = expectedWinner.balance;

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        console2.log("Subscription ID in RaffleTest.sol is :", subscriptionId);
        console2.log("VRF Coordinator address in RaffleTest.sol is :", vrfCoordinator);

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimestamp = raffle.getLastTimestamp();
        uint256 price = entranceFee * (additionalEntrant + 1);


        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + price);
        assert(endingTimestamp > startingTimestamp);
    }

}