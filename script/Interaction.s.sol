//SPDX-License-Identifier
pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubsciption is Script{
    function run() public{
        createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns(uint256,address){
        HelperConfig helperConfig=new HelperConfig();
        address vrfCoordinator=helperConfig.getActiveNetworkConfig().vrfCoordinator;
        vm.startBroadcast();
        uint256 subId=VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        return (subId,vrfCoordinator);
    }
}