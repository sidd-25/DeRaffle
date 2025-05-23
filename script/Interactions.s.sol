// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import{LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";


contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        /* getConfig() returns a struct but getConfig().vrfCoordinator 
        returns a specific value of that struct which is address of vrfCoordinator */

        // Create Subscription
        (uint256 subscriptionId,) = createSubscription(vrfCoordinator, account);
        return (subscriptionId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        console.log("Creating Subscription on chainId:", block.chainid);
        vm.startBroadcast(account);
        uint256 subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription(); // refer to notes/Type-Casting-in-Solidity.md
        vm.stopBroadcast();

        console.log("Created Subscription with ID:", subscriptionId);
        // read notes/Why-Return-vrfCoordinator.md
        return (subscriptionId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 10 ether; // 10 LINK, ether in solidity is 1e18 not eth
    
    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;
        
        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    // refer notes/LinkToken_And_FundSubscription.md
    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken, address account) public {
        console.log("Funding Subscription on chainId:", block.chainid);
        console.log("Using VRF Coordinator in FundSubscription contracts:", vrfCoordinator);
        console.log("Funding Subscription Id:", subscriptionId);

        if(block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 10000);
            vm.stopBroadcast();
        }
        else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();  
        }

    }


    function run() public {
        fundSubscriptionUsingConfig();
    }
}


contract AddConsumer is Script{
    function AddConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address account = helperConfig.getConfig().account;

        addConsumer(mostRecentlyDeployed, vrfCoordinator, subscriptionId, account);


    }

    function addConsumer(address consumerContract, address vrfCoordinator, uint256 subscriptionId, address account) public {
        console.log("Adding to consumer contract:", consumerContract);
        console.log("Adding to VRF Coordinator:", vrfCoordinator);
        console.log("Adding to Subscription ID:", subscriptionId);
        console.log("On the chainId:", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subscriptionId, consumerContract);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        AddConsumerUsingConfig(mostRecentlyDeployed);
    }
}