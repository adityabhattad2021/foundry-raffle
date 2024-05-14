// SPDX-License-Indentifer: UNLICENSED
pragma solidity ^0.8.19;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";

contract RaffleTest is Test {

    event RaffleEnter(address indexed players);

    Raffle raffle;
    HelperConfig helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    uint64 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 raffleEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2;
    address link;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            subscriptionId,
            gasLane,
            automationUpdateInterval,
            raffleEntranceFee,
            callbackGasLimit,
            vrfCoordinatorV2,
            link
        ) = helperConfig.activeNetworkConfig();
    }

    function testRaffleInitializeInOpenState() public view {
        assert(raffle.getRaffleState()==Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__ETHNotSufficient.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        vm.deal(PLAYER,100 ether);
        raffle.enterRaffle{value:raffleEntranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.deal(PLAYER,100 ether);
        vm.expectEmit(true,false,false,false,address(raffle));
        emit RaffleEnter(PLAYER);
        raffle.enterRaffle{value:raffleEntranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        vm.prank(PLAYER);
        vm.deal(PLAYER,100 ether);
        raffle.enterRaffle{value:raffleEntranceFee}();
        vm.warp(block.timestamp+automationUpdateInterval+1);
        vm.roll(block.number+1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        vm.deal(PLAYER,100 ether);
        raffle.enterRaffle{value:raffleEntranceFee}();
    }

    function testCheckUpKeepReturnsFalseIfNoBalance() public {
        vm.warp(block.timestamp+automationUpdateInterval+1);
        vm.roll(block.number+1);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepReturnsFalseRaffleIsntOpen() public {
        vm.prank(PLAYER);
        vm.deal(PLAYER,100 ether);
        raffle.enterRaffle{value:raffleEntranceFee}();
        vm.warp(block.timestamp+automationUpdateInterval+1);
        vm.roll(block.number+1);
        raffle.performUpkeep("");

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed()public{
        vm.prank(PLAYER);
        vm.deal(PLAYER,100 ether);
        raffle.enterRaffle{value:raffleEntranceFee}();

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepReturnsTrueIfPrametersCorrect() public {
        vm.prank(PLAYER);
        vm.deal(PLAYER,100 ether);
        raffle.enterRaffle{value:raffleEntranceFee}();
        vm.warp(block.timestamp+automationUpdateInterval+1);
        vm.roll(block.number+1);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(upkeepNeeded == true);
    }

    function testCheckPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {

        // CheckUpkeep is false
        vm.expectRevert(abi.encodeWithSelector(
            Raffle.Raffle__UpkeepNotNeeded.selector,
            address(raffle).balance,
            raffle.getNumPlayers(),
            uint256(raffle.getRaffleState())
        ));
        raffle.performUpkeep("");

        // CheckUpkeep is true
        vm.prank(PLAYER);
        vm.deal(PLAYER,100 ether);
        raffle.enterRaffle{value:raffleEntranceFee}();
        vm.warp(block.timestamp+automationUpdateInterval+1);
        vm.roll(block.number+1);
        raffle.performUpkeep("");
        
    }


}
