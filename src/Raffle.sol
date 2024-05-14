// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Layout of the contract
// Version
// Imports
// Errors
// Interface, Libraries, Contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of the functions:
// Constructor
// Receive function
// Fallback function
// External function
// Public function
// Internal function
// Private function
// View and Pure functions

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title Smart Contract Lottery
 * @author Aditya Bhattad
 * @notice This contract is for creating a lottery system
 * @dev Uses Chainlink VRF for random number generation and Chainlink automation for ending the lottery
 */
contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughETHSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    address payable[] public s_players;
    address payable public s_recentWinner;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private i_gasLane;
    uint256 private s_lastTimeStamp;
    uint64 private i_subscriptionId;
    uint32 private i_callbackgasLimit;
    RaffleState private s_raffleState;

    // Events
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackgasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackgasLimit = callbackgasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        if(s_raffleState!=RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    function checkUpkeep(
        bytes memory  /* checkData */
    ) public view returns (bool upkeepNeeded,bytes memory /* performData */) {
        bool timeHasPassed = block.timestamp - s_lastTimeStamp >= i_interval;
        bool isOpen  = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded,)=checkUpkeep("");
        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(
                address(this).balance, 
                s_players.length, 
                uint256(s_raffleState)
            );
        }
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }
        s_raffleState=RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackgasLimit, NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        (bool success,) = s_recentWinner.call{value:address(this).balance}("");
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(winner);

        if(!success){
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter function
     */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
