// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Errors {
    error Unauthorized(address caller);
    error InvalidSubscriptionType();
    error IncorrectPayment(uint256 sent, uint256 required);
    error InsufficientAttempts();
    error TransferFailed();
}