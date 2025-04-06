//SPDX-License-Identifier:MIT
pragma solidity 0.8.19;
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants{
    uint96 public constant BASE_FEE=0.01 ether;
    uint96 public constant GAS_PRICE=500000;
    int256 public constant WEI_UNIT_PER_LINK=1e16;
}

contract HelperConfig is Script,CodeConstants{
    error HelperConfig__InvalidChain();

    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyhash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }
    NetworkConfig public activeConfig;

    function getActiveNetworkConfig() external view returns(NetworkConfig memory){
        return activeConfig;
    }

    constructor(){
        if(block.chainid==11155111){
            activeConfig=getEthSepoliaConfig();
        }else if(block.chainid==31337){
            activeConfig=getOrCreateAnvilConfigs();
        }else{
            revert HelperConfig__InvalidChain();
        }
    }

    function getEthSepoliaConfig() pure public returns(NetworkConfig memory){
        NetworkConfig memory ethSepoliaConfig = NetworkConfig({
            entranceFee:0.01 ether,
            interval:30,
            vrfCoordinator:0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyhash:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            // subscriptionId:0,
            subscriptionId:713520647678177244439584085944237866096991846195801158385721621244661266636,
            callbackGasLimit:150000
        });
        return ethSepoliaConfig;
    }

    function getOrCreateAnvilConfigs() public returns(NetworkConfig memory){
        //to avoid re deploying on anvil
        if(activeConfig.vrfCoordinator!=address(0)){
            return activeConfig;
        }
        //deploy mock on anvil chain
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfMock=new VRFCoordinatorV2_5Mock(BASE_FEE,GAS_PRICE,WEI_UNIT_PER_LINK);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig=NetworkConfig({
            entranceFee:0.01 ether,
            interval:30,
            vrfCoordinator:address(vrfMock),
            keyhash:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId:0,
            callbackGasLimit:150000
        });
        return anvilConfig;
    }
}