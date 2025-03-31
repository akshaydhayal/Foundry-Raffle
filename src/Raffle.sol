// Contract elements should be laid out in the following order:
// Pragma statements
// Import statements
// Events
// Errors
// Interfaces
// Libraries
// Contracts

// Inside each contract, library or interface, use the following order:
// Type declarations
// State variables
// Events
// Errors
// Modifiers
// Functions

// Functions should be grouped according to their visibility and ordered:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// Within a grouping, place the view and pure functions last.

//SPDX-License-Identifier:MIT
pragma solidity 0.8.19;
//wrong import due to mentioned version in package
// import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.1.1/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle Contract
 * @author Akshay
 * @notice This Contract is for creating simple raffle
 * @dev Implements Chainlink VRF v2.5
 *
 */
contract Raffle is VRFConsumerBaseV2Plus {
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS=1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyhash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_lastBlockStamp;
    address payable[] private s_players; //payable address array
    address private s_winner;

    // rule of thumb- always emit an event whenverr we update a storage varaible
    //indexed parameters are called topics also and are easy to query and search
    // than non-indexed params, amd max 3 topics allowed inside a event
    event playerEnteredRaffle(address indexed player);

    // errors
    error Raffle__NotEnoughFundForRaffle();
    error Raffle__RaffleIntervalNotPassed();
    error Raffle__WinAmountTransferFailed();

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 keyhash, uint256 subscriptionId,uint32 callbackGasLimit)
        VRFConsumerBaseV2Plus(vrfCoordinator)
    {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastBlockStamp = block.timestamp;

        i_keyhash = keyhash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit=callbackGasLimit;
    }

    //private, external fn are bit more gas efficient than public functions
    function enterRaffle() external payable {
        // require(msg.value<ENTRANCE_FEE,"not enough money to enter raffle");
        // require(msg.value<ENTRANCE_FEE,Raffle__NotEnoughFundForRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughFundForRaffle();
        }
        s_players.push(payable(msg.sender));
        emit playerEnteredRaffle(msg.sender);
    }

    //Get a random number
    //From random no pick a player(winnner)
    //Be automatically called

    // CEI Pattern - Checks, Effects, Interactions, and it helps you defend against reentrancies.
    function pickWinner() external {
        //check if time to declare winner is correct
        if (block.timestamp - s_lastBlockStamp < i_interval) {
            revert Raffle__RaffleIntervalNotPassed();
        }

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyhash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });
        // uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // 12%10 - rem from 0 to 9 , modulo
        uint256 winnerIdx=randomWords[0] % s_players.length;
        address payable winner=s_players[winnerIdx];
        s_winner=winnner;
        (bool transferStatus,)=winner.call{value:address(this).balance}("");
        if(!transferStatus){
            revert Raffle__WinAmountTransferFailed();
        }
    }
}
