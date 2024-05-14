// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64, address) {
        HelperConfig helperConfig = new HelperConfig();
        (, , , , , address vrfCoordinatorV2, ) = helperConfig
            .activeNetworkConfig();
        return createSubscription(vrfCoordinatorV2);
    }

    function createSubscription(
        address vrfCoordinatorV2
    ) public returns (uint64, address) {
        console.log("Creating subscription on chain Id: %e", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinatorV2)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Subscription created with id: %e", subId);
        return (subId, vrfCoordinatorV2);
    }

    function run() external returns (uint64, address) {
        return createSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address contractToAddToVrf,
        address vrfCoordinator,
        uint64 subId
    ) public {
        console.log(
            "Adding consumer to subscription on chain Id: %e",
            block.chainid
        );
        console.log("Contract to add to VRF: %e", contractToAddToVrf);
        console.log("VRF Coordinator: %e", vrfCoordinator);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(
            subId,
            contractToAddToVrf
        );
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint64 subscriptionId,
            ,
            ,
            ,
            ,
            address vrfCoordinatorV2,

        ) = helperConfig.activeNetworkConfig();
        addConsumer(mostRecentlyDeployed, vrfCoordinatorV2, subscriptionId);
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint64 subscriptionId,
            ,
            ,
            ,
            ,
            address vrfCoordinatorV2,
            address link
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (uint64 updatedSubId, address updatedVRFv2) = createSubscription
                .run();
            subscriptionId = updatedSubId;
            vrfCoordinatorV2 = updatedVRFv2;
            console.log("Subscription Id: %e", subscriptionId);
            console.log("VRF Coordinator: ", vrfCoordinatorV2);
        }

        fundSubscription(vrfCoordinatorV2, subscriptionId, link);
    }

    function fundSubscription(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        address link
    ) public {
        if (block.chainid == 31337) {
            console.log("Funding subscription on chain Id: %e", block.chainid);
            console.log("VRF Coordinator: ", vrfCoordinatorV2);
            console.log("Subscription Id: ", subscriptionId);
            console.log("Link Token: ", link);
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinatorV2).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        }else{
            revert("This script is only for local testing");
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}
