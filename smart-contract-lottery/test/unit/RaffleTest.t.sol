// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

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
        // console.log("Entrance fee:", raffle.getEntranceFee());
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
}
