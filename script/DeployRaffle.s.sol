//SPDX-License-Identifier:MIT
pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script{
    function run() external{

    }
    function deployContract() public returns( Raffle, HelperConfig){
        HelperConfig helperConfig =new HelperConfig();
        //destructure above struct
        // HelperConfig.NetworkConfig memory config=helperConfig.activeConfig();
        HelperConfig.NetworkConfig memory config=helperConfig.getActiveNetworkConfig();

        if(config.subscriptionId==0){
            //create subscription id
        }
        vm.startBroadcast();
        Raffle raffle=new Raffle({
            entranceFee:config.entranceFee,
            interval:config.interval,
            vrfCoordinator:config.vrfCoordinator,
            subscriptionId:config.subscriptionId,
            callbackGasLimit:config.callbackGasLimit,
            keyhash:config.keyhash
        });
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}