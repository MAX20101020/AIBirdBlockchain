// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SubscriptionManager} from "../src/Subscription.sol";
import {Errors} from "../error/Errors.sol";

contract SubscriptionManagerTest is Test {
    SubscriptionManager public subManager;

    address public owner;
    address public user;

    uint256 public constant BASIC_PRICE = 99.99 ether;
    uint256 public constant PRO_PRICE = 449.99 ether;
    uint256 public constant PRO_PLUS_PRICE = 799.99 ether;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        vm.deal(owner, 10_000 ether);
        vm.deal(user, 10_000 ether);

        vm.prank(owner);
        subManager = new SubscriptionManager();
    }

    function test_BuyBasicSubscription() public {
        vm.prank(user);
        subManager.buySubscription{value: BASIC_PRICE}(SubscriptionManager.SubscriptionType.BASIC);
        assertEq(subManager.getAttempts(user), 10);
    }

    function test_BuyProSubscription() public {
        vm.prank(user);
        subManager.buySubscription{value: PRO_PRICE}(SubscriptionManager.SubscriptionType.PRO);
        assertEq(subManager.getAttempts(user), 50);
    }

    function test_BuyProPlusSubscription() public {
        vm.prank(user);
        subManager.buySubscription{value: PRO_PLUS_PRICE}(SubscriptionManager.SubscriptionType.PRO_PLUS);
        assertEq(subManager.getAttempts(user), 100);
    }

    function test_StackSubscriptions() public {
        vm.startPrank(user);
        subManager.buySubscription{value: BASIC_PRICE}(SubscriptionManager.SubscriptionType.BASIC);
        subManager.buySubscription{value: PRO_PRICE}(SubscriptionManager.SubscriptionType.PRO);
        vm.stopPrank();

        assertEq(subManager.getAttempts(user), 60);
    }

    function test_RevertWhen_IncorrectPayment() public {
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.IncorrectPayment.selector, 0.005 ether, BASIC_PRICE)
        );
        subManager.buySubscription{value: 0.005 ether}(SubscriptionManager.SubscriptionType.BASIC);
    }

    function test_ConsumeAttempt() public {
        vm.prank(user);
        subManager.buySubscription{value: BASIC_PRICE}(SubscriptionManager.SubscriptionType.BASIC);

        vm.prank(owner);
        subManager.consumeAttempt(user);

        assertEq(subManager.getAttempts(user), 9);
    }

    function test_RevertWhen_NoAttempts() public {
        vm.prank(owner);
        vm.expectRevert(Errors.InsufficientAttempts.selector);
        subManager.consumeAttempt(user);
    }

    function test_Withdraw() public {
        vm.prank(user);
        subManager.buySubscription{value: BASIC_PRICE}(SubscriptionManager.SubscriptionType.BASIC);

        uint256 initialOwnerBalance = owner.balance;

        vm.prank(owner);
        subManager.withdraw();

        assertEq(owner.balance, initialOwnerBalance + BASIC_PRICE);
        assertEq(address(subManager).balance, 0);
    }
}