// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SubscriptionManager} from "../src/Subscription.sol";

contract Subscription is Script {
    function run() external {
        vm.startBroadcast();

        SubscriptionManager subManager = new SubscriptionManager();
        console.log("SubscriptionManager deployed at:", address(subManager));

        vm.stopBroadcast();
    }
}