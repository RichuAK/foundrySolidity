// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    /**Event Declarations */
    event EnteredRaffle(address indexed player);

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callBackGasLimit;
    address linkToken;

    address PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 1 ether;

    modifier PlayerEnter() {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        _;
    }

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        vm.deal(PLAYER, STARTING_BALANCE);
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callBackGasLimit,
            linkToken
        ) = helperConfig.activeNetworkConfig();
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /////////////////////////////////////
    // enter raffle test suite  /////////
    ////////////////////////////////////

    function testEnterRaffleRevertsWhenNotPaidEnough() public {
        // Arrange
        uint256 lessThanEntranceFee = raffle.getEntranceFee() - 100;
        console.log("Entrance fee:", raffle.getEntranceFee());
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle{value: lessThanEntranceFee}();
    }

    function testPlayerGetsAddedToPlayers() public {
        // Arrange
        uint256 initPlayersLength = raffle.getPlayersSize();
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: entranceFee}();
        // Assert
        assertEq(PLAYER, raffle.getPlayerAtIndex(initPlayersLength));
    }

    /* Events a bit tricky to test in foundry. 

    expectemit cheatcode: https://book.getfoundry.sh/cheatcodes/expect-emit?highlight=expectemit#expectemit
    You do expect emit, then you emit the event in your test itself, and then you do the transaction that does the event emit.
    
    which means you have to declare the event outside the functions in the test file.

    */

    function testEnteredRaffleEventIsEmitted() public {
        vm.prank(PLAYER);
        // the address paremeter/property is not exactly strongly binded(?)
        vm.expectEmit(true, false, false, false, address(raffle));
        // vm.expectEmit(true, false, false, false);
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testRaffleRevertsWhenRaffleStateIsCalculating()
        public
        PlayerEnter
    {
        // Act
        vm.warp(block.timestamp + raffle.getInterval());
        vm.roll(block.number + 1);
        raffle.performUpKeep("");
        // Assert
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}(); // same player entering again. Should have been a different one. Meh.
    }

    ////////////////////////////////
    ///checkUpKeep test suite //////  -|---|-
    ///////////////////////////////

    function testCheckUpKeepReturnsFalseIfNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleIsCalculating()
        public
        PlayerEnter
    {
        // Act
        vm.warp(block.timestamp + raffle.getInterval());
        vm.roll(block.number + 1);
        raffle.performUpKeep("");
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded == false);
    }

    function testCheckUpKeepReturnsFalseIfEnoughTimeHaventPassed()
        public
        PlayerEnter
    {
        // Act
        vm.warp(block.timestamp + (raffle.getInterval() - 23));
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfNoPlayerEntered() public {
        // Watch the modifier. Or the absence of it.
        vm.warp(block.timestamp + raffle.getInterval());
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsTrueOnSunnyDay() public PlayerEnter {
        // Act
        vm.warp(block.timestamp + raffle.getInterval());
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded);
    }

    ////////////////////////
    ////performUpKeep //////
    ///////////////////////

    modifier PlayerEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + raffle.getInterval());
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpKeepRevertsIfCheckUpKeepIsFalse() public PlayerEnter {
        // Enough time hasn't passed at this point
        // Arrange
        uint256 balance = entranceFee;
        uint256 length = 1;
        Raffle.RaffleState raffleState = Raffle.RaffleState.OPEN;
        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                balance,
                length,
                raffleState
            )
        );
        raffle.performUpKeep("");
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitsRequestId()
        public
        PlayerEnteredAndTimePassed
    {
        // Arrange is already done
        // Act
        vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // all logs are stored as bytes32 in foundry
        // index 0 is the index of the 'native' event from Mock, 1 is for the redundant event (just know this)
        // topics[0] refers to the entire event, so topics[1] is the paremater. Again, weird stuff.
        bytes32 requestId = entries[1].topics[1];
        Raffle.RaffleState rState = raffle.getRaffleState();

        // Assert
        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    /**
     * @dev An intro to fuzz testing
     * @param requestId a number which foundry will randomly generate and test multiple times
     * @dev 256 times, in my experience
     *
     */
    function testFullFillRandomWorldsCanOnlyBeCalledAfterPerformUpKeep(
        uint256 requestId
    ) public PlayerEnteredAndTimePassed {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );
    }

    // One Big Test!
    function testFullFillRandomWordsPicksAWinnerResetsAndSendThePrize()
        public
        PlayerEnteredAndTimePassed
    {
        // Arrange
        uint256 i = 1;
        uint256 numberOfEntrants = 8;
        // 7 additional players. Magic number, but beat with me this time
        for (i = 1; i < numberOfEntrants; i++) {
            address player = address(uint160(i)); //why uint160 can be converted to address, but not uint256?
            hoax(player, STARTING_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        // bytes32 winnerbytes = entries[2].topics[1];
        // for(i =0; i< entries.length; i++){
        //     console.log("Entry ",i, " ", uint256(entries[i]));
        // }
        console.log("Entries length: ", entries[0].topics.length);
        // console.log("Winner bytes: ", uint256(winnerbytes));
        // address winner = address(uint160(bytes20(winnerbytes)));
        // assembly {
        //     winner := mload(add(winnerbytes, 20))
        // }
        uint256 prize = entranceFee * numberOfEntrants;
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );
        // uint256 previousTimeStamp = raffle.getTimeStamp();

        // console.log("Players length: ", raffle.getPlayersSize());

        // console.log("Raffle State: ", uint256(raffle.getRaffleState()));

        // Asserts
        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getPlayersSize() == 0);
        // assert(address(uint160(bytes20(winner))) != address(0));
        assert(raffle.getRecentWinner() != address(0));
        assert(
            raffle.getRecentWinner().balance ==
                prize + STARTING_BALANCE - entranceFee
        );
        // you need to warp a bit to get this true
        // assert(raffle.getTimeStamp() > previousTimeStamp);
    }
}
