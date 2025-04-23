// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() public {}
    
    function deployRaffle() public returns (HelperConfig, Raffle) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            networkConfig.entranceFee, 
            networkConfig.interval, 
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId, 
            networkConfig.keyHash, 
            networkConfig.callbackGasLimit
            );
        vm.stopBroadcast();
        return (helperConfig, raffle);
    }
}