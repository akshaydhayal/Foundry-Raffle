//SPDX-License-Identifier:MIT
pragma solidity 0.8.19;
import {Test,console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test{
    event playerEnteredRaffle(address indexed player);

    Raffle public raffle;
    HelperConfig public helperConfig;

    address USER=makeAddr("USER");
    HelperConfig.NetworkConfig config;

    function setUp() external{
        DeployRaffle deployRaffle=new DeployRaffle();
        (raffle,helperConfig)=deployRaffle.deployContract();
        config=helperConfig.getActiveNetworkConfig();

        vm.deal(USER,10 ether);
    }

    function testRaffleIsInitialisedInOpenState() public view{
        Raffle.RaffleState raffleState =raffle.getRaffleState();
        assertEq(uint256(raffleState),uint256(Raffle.RaffleState.OPEN));  //assertEq dont work for enums
        // assert(raffle.getRaffleState()==Raffle.RaffleState.OPEN);
    }

    function testEnterRaffleRevertsWithoutEnoughEntranceFee() external{
        //Arrange
        vm.prank(USER);
        //Act
        vm.expectRevert(Raffle.Raffle__NotEnoughFundForRaffle.selector);
        //Assert
        raffle.enterRaffle();
    }

    function testEnterRaffleUpdatesPlayersArray() external{
        console.log('entranceFee : ',config.entranceFee);
        vm.prank(USER);
        raffle.enterRaffle{value:config.entranceFee}();
        address player=raffle.getPlayer(0);
        assertEq(USER,player);
    }

    function testEmitEventPlayerEnteredRaffle() external{
        vm.prank(USER);
        //expectEmit(first topic bool,2nd topic, 3rd topic bool, any additional data bool, address of contract)
        vm.expectEmit(true,false,false,false,address(raffle));
        emit playerEnteredRaffle(USER);
        //we have to first tell which event will be emitted for the next tx, and not vice versa. Can place the expectEmit below the nterRaffle fn
        raffle.enterRaffle{value:config.entranceFee}();
    }

    function testDontAllowPlayersToEnterRaffleIfCalculating() external {
        vm.prank(USER);
        raffle.enterRaffle{value:config.entranceFee}();
        //warp sets block timestamp and roll sets block blockhash
        vm.warp(block.timestamp+config.interval+1);
        vm.roll(block.number+1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleIsNotOpen.selector);
        raffle.enterRaffle{value:config.entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfNoBalance() public{
        vm.warp(block.timestamp+config.interval+1);
        vm.roll(block.number+1);

        (bool upKeepneeded,)=raffle.checkUpkeep("");
        assertEq(upKeepneeded,false);
    }

    // function testCheckUpkeepReturnsFalseItIsNotOpen() public{
    //     vm.prank(USER);
    //     raffle.enterRaffle{value:config.entranceFee}();
    //     vm.warp(block.timestamp+config.interval+1);
    //     vm.roll(block.number+1);

    //     raffle.performUpkeep("");
    //     bool (upkeepNeeded,)=raffle.checkUpkeep("");
    //     assert(!upkeepNeeded);
    // }




    //Challenge to reach near 100% test coverage nd check solution after than
}




// pragma solidity ^0.8.13;

// import {Test, console} from "forge-std/Test.sol";
// import {Counter} from "../src/Counter.sol";

// contract CounterTest is Test {
//     Counter public counter;

//     function setUp() public {
//         counter = new Counter();
//         counter.setNumber(0);
//     }

//     function test_Increment() public {
//         counter.increment();
//         assertEq(counter.number(), 1);
//     }

//     function testFuzz_SetNumber(uint256 x) public {
//         counter.setNumber(x);
//         assertEq(counter.number(), x);
//     }
// }
