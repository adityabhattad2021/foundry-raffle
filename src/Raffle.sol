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

    // Events
    event EnteredRaffle(address indexed player);

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
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() external {
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackgasLimit, NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        (bool success,) = s_recentWinner.call{value:address(this).balance}("");
        if(!success){
            revert();
        }
    }

    /**
     * Getter function
     */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
