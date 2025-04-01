// Contract elements should be laid out in the following order:
// Pragma statements
// Import statements
// Events
// Errors
// Interfaces
// Libraries
// Contracts

// Inside each contract, library or interface, use the following order:
// Type declarations(enums)
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
    //Type Declarations(enums)
    enum RaffleState {
        OPEN, //0
        CALCULATING //1
    }

    //State Variables
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyhash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_lastBlockStamp;
    address payable[] private s_players; //payable address array
    address private s_winner;
    RaffleState private s_raffleState;

    //Events
    // rule of thumb- always emit an event whenverr we update a storage varaible
    //indexed parameters are called topics also and are easy to query and search
    // than non-indexed params, amd max 3 topics allowed inside a event
    event playerEnteredRaffle(address indexed player);
    event raffleWinner(address indexed player);

    // Errors
    error Raffle__NotEnoughFundForRaffle();
    error Raffle__RaffleIntervalNotPassed();
    error Raffle__WinAmountTransferFailed();
    error Raffle__RaffleIsNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyhash,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastBlockStamp = block.timestamp;

        i_keyhash = keyhash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    //private, external fn are bit more gas efficient than public functions
    function enterRaffle() external payable {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleIsNotOpen();
        }
        // require(msg.value<ENTRANCE_FEE,"not enough money to enter raffle");
        // require(msg.value<ENTRANCE_FEE,Raffle__NotEnoughFundForRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughFundForRaffle();
        }
        s_players.push(payable(msg.sender));
        emit playerEnteredRaffle(msg.sender);
    }

    /**
     * @dev This function will be called by Chainlink nodes to see if lottery is ready to pick a winner
     * The foloowing should be true for performKeep to run
     * Lottery interval has passed
     * Raffle State is Open
     * Raffle has 1 or more players/ Raffle has more than 0 fund 
     * @return upkeepNeeded - true if its time to pick winner
     */
    function checkUpkeep(
        bytes memory /* callData */
    ) public view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool intervalPassed=(block.timestamp-s_lastBlockStamp>=i_interval);
        bool isRaffleOpen=s_raffleState==RaffleState.OPEN;
        bool raffleHasPlayers=s_players.length>0;
        bool hasBalance=address(this).balance>0;
        upkeepNeeded=intervalPassed && isRaffleOpen && raffleHasPlayers && hasBalance;
        return (upkeepNeeded,"");
    }

    //Get a random number
    //From random no pick a player(winnner)
    //Be automatically called
    function performUpkeep(bytes calldata /*performData*/) external {
        //check if time to declare winner is correct
        // if (block.timestamp - s_lastBlockStamp < i_interval) {
        //     revert Raffle__RaffleIntervalNotPassed();
        // }

        //This check if for that anybody other than chainlik automation can also call this function
        (bool upkeepNeeded,)=checkUpkeep("");
        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
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

    // CEI Pattern for functions - it helps you defend against reentrancies.
    //Checks(conditionls at top), Effects(Internal Contract State changes), Interactions(External contracts interactions)
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        //checks at top are gas efficients due t reverts - None

        //Effects
        // 12%10 - rem from 0 to 9 , modulo
        uint256 winnerIdx = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIdx];
        s_winner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastBlockStamp = block.timestamp;
        emit raffleWinner(s_winner);

        //Interactions
        (bool transferStatus, ) = winner.call{value: address(this).balance}("");
        if (!transferStatus) {
            revert Raffle__WinAmountTransferFailed();
        }
    }
}
