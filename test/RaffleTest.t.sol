//SPDX-License-Identifier:MIT
pragma solidity 0.8.19;
import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract RaffleTest is Test{
    Raffle public raffle;
    HelperConfig public helperConfig;

    address USER=makeAddr("USER");
    function setUp() external{
        DeployRaffle deployRaffle=new DeployRaffle();
        (raffle,helperConfig)=deployRaffle.deployContract();

        vm.deal(USER,10 ether);
    }

    function testRaffleIsOpenAtStart() external{
        vm.prank(USER);
        raffle.
    }
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
