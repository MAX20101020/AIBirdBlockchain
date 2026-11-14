// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Errors} from "../error/Errors.sol";

contract SubscriptionManager {
    enum SubscriptionType {
        BASIC,
        PRO,
        PRO_PLUS
    }

    struct Subscription {
        uint256 attemptsLeft;
        SubscriptionType planType;
    }

    address public owner;

    mapping(SubscriptionType => uint256) public planPrices;
    mapping(SubscriptionType => uint256) public planAttempts;
    mapping(address => Subscription) public subscriptions;

    event SubscriptionPurchased(
        address indexed user,
        SubscriptionType indexed planType,
        uint256 attemptsAdded,
        uint256 totalAttempts
    );
    event AttemptConsumed(address indexed user, uint256 attemptsLeft);

    modifier onlyOwner() {
        if (msg.sender != owner) revert Errors.Unauthorized(msg.sender);
        _;
    }

    constructor() {
        owner = msg.sender;

        planAttempts[SubscriptionType.BASIC] = 10;
        planAttempts[SubscriptionType.PRO] = 50;
        planAttempts[SubscriptionType.PRO_PLUS] = 100;

        planPrices[SubscriptionType.BASIC] = 99.99 ether;
        planPrices[SubscriptionType.PRO] = 449.99 ether;
        planPrices[SubscriptionType.PRO_PLUS] = 799.99 ether;
    }

    function buySubscription(SubscriptionType _type) external payable {
        uint256 requiredPrice = planPrices[_type];
        if (requiredPrice == 0) revert Errors.InvalidSubscriptionType();

        if (msg.value != requiredPrice) {
            revert Errors.IncorrectPayment(msg.value, requiredPrice);
        }

        uint256 attemptsToAdd = planAttempts[_type];

        Subscription storage userSub = subscriptions[msg.sender];
        userSub.attemptsLeft += attemptsToAdd;
        userSub.planType = _type;

        emit SubscriptionPurchased(msg.sender, _type, attemptsToAdd, userSub.attemptsLeft);
    }

    function consumeAttempt(address _user) external onlyOwner {
        if (subscriptions[_user].attemptsLeft == 0) {
            revert Errors.InsufficientAttempts();
        }

        subscriptions[_user].attemptsLeft -= 1;
        emit AttemptConsumed(_user, subscriptions[_user].attemptsLeft);
    }

    function getAttempts(address _user) external view returns (uint256) {
        return subscriptions[_user].attemptsLeft;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        if (!success) revert Errors.TransferFailed();
    }
}