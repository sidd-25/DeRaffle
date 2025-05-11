// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployRaffle();
    }
    
    function deployRaffle() public returns (HelperConfig, Raffle, HelperConfig.NetworkConfig memory networkConfig) {
        HelperConfig helperConfig = new HelperConfig();
        networkConfig = helperConfig.getConfig();

        // I think this is meant for live networks only not anvil
        if (networkConfig.subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (networkConfig.subscriptionId, networkConfig.vrfCoordinator) = createSub.createSubscription(networkConfig.vrfCoordinator);

            // Fund Subscription
            FundSubscription fundSub = new FundSubscription();
            fundSub.fundSubscriptionUsingConfig();
        }


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

        console2.log("VRF Coordinator address in DeployRaffle.sol is :", networkConfig.vrfCoordinator);
        console2.log("Subscription ID in DeployRaffle is:", networkConfig.subscriptionId);
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), networkConfig.vrfCoordinator, networkConfig.subscriptionId);

        return (helperConfig, raffle, networkConfig);
    }
}