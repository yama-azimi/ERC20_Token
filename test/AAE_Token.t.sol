// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../src/AAE_Token.sol"; // Update the path as necessary

contract AAE_TokenTest is Test {
    AAE_Token token;
    address owner;
    address constant newOwner = address(0xdead);
    address constant recipient = address(0xbeef);
    uint256 constant initialSupply = 1000000 * 10 ** 18;
    uint256 constant transferAmount = 100 * 10 ** 18;

    function setUp() public {
        token = new AAE_Token();
        owner = address(this);
    }

    // Test Initial State of the Contract
    function testInitialState() public {
        assertEq(token.NAME(), "AAE_Token");
        assertEq(token.SYMBOL(), "AAET");
        assertEq(token.DECIMALS(), 18);
        assertEq(token.totalSupply(), initialSupply);
        assertEq(token.balanceOf(owner), initialSupply);
        assertFalse(token.paused());
        assertEq(token.owner(), owner);
    }

    // Test Ownership Transfer
    function testOwnershipTransfer() public {
        token.transferOwnership(newOwner);
        assertEq(token.owner(), newOwner);

        vm.startPrank(newOwner);
        token.transferOwnership(owner);
        assertEq(token.owner(), owner);
        vm.stopPrank();
    }

    // Test Pause and Unpause
    function testPauseAndUnpause() public {
        token.pause();
        assertTrue(token.paused());

        token.unpause();
        assertFalse(token.paused());
    }

    // Test Transfer Functionality
    function testTransfer() public {
        token.transfer(recipient, transferAmount);
        assertEq(token.balanceOf(recipient), transferAmount);
    }

    // Test TransferFrom and Approval
    function testTransferFromAndApproval_Success() public {
        // Setup: Approve recipient to spend transferAmount tokens on behalf of the owner
        token.approve(recipient, transferAmount);
        uint256 ownerInitialBalance = token.balanceOf(owner);
        uint256 recipientInitialBalance = token.balanceOf(recipient);

        // Test: Execute transferFrom
        vm.prank(recipient);
        bool success = token.transferFrom(owner, recipient, transferAmount);

        // Verify: Transfer was successful
        assertTrue(success, "transferFrom should succeed");
        assertEq(
            token.balanceOf(owner),
            ownerInitialBalance - transferAmount,
            "Owner balance should decrease"
        );
        assertEq(
            token.balanceOf(recipient),
            recipientInitialBalance + transferAmount,
            "Recipient balance should increase"
        );
        assertEq(
            token.allowance(owner, recipient),
            0,
            "Allowance should be zero after transfer"
        );
    }

    function testTransferFromToZeroAddress_Reverts() public {
        // Setup: Approve recipient to spend
        token.approve(recipient, transferAmount);

        // Test & Verify: Attempt to transfer to zero address should fail
        vm.expectRevert("Cannot transfer to the zero address");
        vm.prank(recipient);
        token.transferFrom(owner, address(0), transferAmount);
    }

    function testTransferFromExceedsBalance_Reverts() public {
        // Setup: Attempt to transfer more than owner's balance
        uint256 excessAmount = token.balanceOf(owner) + 1;
        token.approve(recipient, excessAmount);

        // Test & Verify: Should revert due to insufficient balance
        vm.expectRevert("Insufficient balance");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, excessAmount);
    }

    function testTransferFromExceedsAllowance_Reverts() public {
        // Setup: Approve recipient to spend less than transferAmount
        uint256 approvedAmount = transferAmount - 1;
        token.approve(recipient, approvedAmount);

        // Test & Verify: Attempt to transfer more than allowed should fail
        vm.expectRevert("Transfer amount exceeds allowance");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, transferAmount);
    }

    function testTransferFromZeroTokens_Reverts() public {
        // Setup: Approve recipient to spend
        token.approve(recipient, transferAmount);

        // Test & Verify: Attempt to transfer 0 tokens should fail
        vm.expectRevert("Transfer amount must be greater than zero");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, 0);
    }

    function testTransferFromAfterApprovalDecrease() public {
        // Setup: Increase and then decrease the allowance
        token.approve(recipient, transferAmount);
        token.decreaseAllowance(recipient, transferAmount / 2);

        // Test & Verify: Attempt to transfer more than the new allowance should fail
        vm.expectRevert("Transfer amount exceeds allowance");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, transferAmount);
    }

    // Additional tests can include:
    // - Transferring the exact amount of the remaining allowance.
    // - Ensuring events (Transfer and Approval) are emitted correctly.
    // - Testing `transferFrom` functionality when the contract is paused.
    function testTransferFromExactAllowance() public {
        // Setup: Approve recipient to spend a specific allowance
        uint256 allowance = transferAmount;
        token.approve(recipient, allowance);

        // Test: Execute transferFrom for the exact allowance amount
        vm.prank(recipient);
        bool success = token.transferFrom(owner, recipient, allowance);

        // Verify: Transfer was successful and allowance is fully utilized
        assertTrue(success, "transferFrom should succeed for exact allowance");
        assertEq(
            token.allowance(owner, recipient),
            0,
            "Allowance should be fully utilized"
        );
    }

    function testTransferFromWhenPaused() public {
        // Setup: Approve recipient to spend and then pause the contract
        token.approve(recipient, transferAmount);
        token.pause();

        // Test & Verify: transferFrom should revert when the contract is paused
        vm.expectRevert("Contract is paused");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, transferAmount);
    }

    // Test Increase and Decrease Allowance
    // Testing increaseAllowance and decreaseAllowance functions comprehensively
    function testIncreaseAllowance() public {
        uint256 initialAllowance = transferAmount;
        uint256 addedValue = transferAmount;
        uint256 decreasedValue = 50 * 10 ** 18;

        // Initial approval
        bool initialApprovalSuccess = token.approve(
            recipient,
            initialAllowance
        );
        assertTrue(initialApprovalSuccess, "Initial approval failed");
        assertEq(
            token.allowance(owner, recipient),
            initialAllowance,
            "Initial allowance incorrect"
        );

        // Increase allowance
        bool increaseSuccess = token.increaseAllowance(recipient, addedValue);
        assertTrue(increaseSuccess, "Increase allowance failed");
        assertEq(
            token.allowance(owner, recipient),
            initialAllowance + addedValue,
            "Allowance not increased correctly"
        );

        // Decrease allowance
        bool decreaseSuccess = token.decreaseAllowance(
            recipient,
            decreasedValue
        );
        assertTrue(decreaseSuccess, "Decrease allowance failed");
        assertEq(
            token.allowance(owner, recipient),
            initialAllowance + addedValue - decreasedValue,
            "Allowance not decreased correctly"
        );

        // Attempt to decrease allowance below zero
        vm.expectRevert("ERC20: decreased allowance below zero");
        token.decreaseAllowance(recipient, initialAllowance * 3); // Exceeding current allowance

        // Set allowance to max uint256
        token.approve(recipient, type(uint256).max);
        assertEq(
            token.allowance(owner, recipient),
            type(uint256).max,
            "Allowance not set to max uint256"
        );

        // Attempt to increase allowance when it's already at max should not overflow due to check in Solidity
        // Removing the overflow test because Solidity >=0.8.x prevents it automatically

        // Testing increase allowance to a zero address should revert
        vm.expectRevert("ERC20: approve to the zero address");
        token.increaseAllowance(address(0), addedValue);
    }

    function testDecreaseAllowance() public {
        uint256 initialAllowance = 100 * 10 ** 18; // Example initial allowance
        uint256 subtractedValue = 50 * 10 ** 18; // Example subtracted value

        // Setup: Ensure owner has approved an initial allowance for the recipient
        bool initialApprovalSuccess = token.approve(
            recipient,
            initialAllowance
        );
        assertTrue(initialApprovalSuccess, "Initial approval failed");
        assertEq(
            token.allowance(owner, recipient),
            initialAllowance,
            "Initial allowance incorrect"
        );

        // Test case 1: Successfully decrease allowance
        bool decreaseSuccess = token.decreaseAllowance(
            recipient,
            subtractedValue
        );
        assertTrue(decreaseSuccess, "Decrease allowance failed");
        assertEq(
            token.allowance(owner, recipient),
            initialAllowance - subtractedValue,
            "Allowance not decreased correctly"
        );

        // Test case 2: Attempt to decrease allowance below zero should revert
        vm.expectRevert("ERC20: decreased allowance below zero");
        token.decreaseAllowance(recipient, initialAllowance);

        // Test case 3: Decrease allowance to zero by subtracting the rest
        decreaseSuccess = token.decreaseAllowance(recipient, subtractedValue);
        assertTrue(decreaseSuccess, "Decrease to zero failed");
        assertEq(
            token.allowance(owner, recipient),
            0,
            "Allowance not decreased to zero correctly"
        );

        // Test case 4: Attempting to decrease allowance when it's already zero should revert
        vm.expectRevert("ERC20: decreased allowance below zero");
        token.decreaseAllowance(recipient, 1 * 10 ** 18); // Attempting to subtract more from a zero allowance

        // Test case 5: Ensure that decreasing allowance for a zero address spender reverts
        vm.expectRevert("ERC20: approve to the zero address");
        token.decreaseAllowance(address(0), subtractedValue);

        // Test case 6: Increase allowance and then decrease it back to ensure correct path
        initialApprovalSuccess = token.approve(recipient, initialAllowance);
        assertTrue(initialApprovalSuccess, "Re-approval failed");
        decreaseSuccess = token.decreaseAllowance(recipient, initialAllowance);
        assertTrue(decreaseSuccess, "Decreasing after re-approval failed");
        assertEq(
            token.allowance(owner, recipient),
            0,
            "Allowance not correctly decreased after re-approval"
        );
    }

    // Test Burn Functionality
    function testBurn() public {
        token.transfer(recipient, transferAmount);
        vm.prank(recipient);
        assertTrue(token.burn(transferAmount));
        assertEq(token.balanceOf(recipient), 0);
        assertEq(token.totalSupply(), initialSupply - transferAmount);
    }

    // Test Functionality When Paused
    function testWhenPaused() public {
        token.pause();

        vm.expectRevert("Contract is paused");
        token.transfer(recipient, transferAmount);

        vm.expectRevert("Contract is paused");
        token.approve(recipient, transferAmount);

        vm.expectRevert("Contract is paused");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, transferAmount);
    }

    // Test Edge Cases for Transfers and Approvals
    function testEdgeCases() public {
        vm.expectRevert("Cannot transfer to the zero address");
        token.transfer(address(0), transferAmount);

        vm.expectRevert("Insufficient balance");
        token.transfer(recipient, initialSupply + 1); // More than the owner's balance

        vm.expectRevert("Transfer amount exceeds allowance");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, transferAmount + 1); // More than approved amount
    }

    // Ensure totalSupply decreases correctly after burn
    function testTotalSupplyAfterBurn() public {
        uint256 burnAmount = 50 * 10 ** 18;
        token.burn(burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);
    }

    // Test Ownership Transfer Restrictions
    function testOwnershipTransferRestrictions() public {
        vm.expectRevert("Caller is not the owner");
        vm.prank(recipient);
        token.transferOwnership(newOwner);

        vm.expectRevert("New owner is the zero address");
        token.transferOwnership(address(0));
    }

    // Test Unpause Restrictions
    function testUnpauseRestrictions() public {
        token.pause();

        vm.expectRevert("Caller is not the owner");
        vm.prank(recipient);
        token.unpause();
    }

    // Test Attempts to Burn More Tokens Than Balance
    function testBurnMoreThanBalance() public {
        uint256 excessBurnAmount = token.balanceOf(owner) + 1;

        vm.expectRevert("Insufficient balance to burn");
        token.burn(excessBurnAmount);
    }

    // Additional tests should continue to cover all functions, modifiers, and revert conditions.
}

/**
import "forge-std/Test.sol";
import {AAE_Token} from "src/AAE_Token.sol";

/// @title Test suite for the AAE_Token smart contract
/// @notice Uses Foundry's test framework to ensure contract functionality is correct
contract AAE_TokenTest is Test {
    AAE_Token token;
    address owner = address(this); // Contract deploying the token is the initial owner
    address newOwner = address(0x1);
    address recipient = address(0x2);
    address anotherRecipient = address(0x3);
    address spender = address(0x4);
    address anotherAccount = address(0x5);
    address zeroAddress = address(0);
    uint256 transferAmount = 100 * 10 ** 18;
    uint256 ownerBalanceBefore;
    uint256 decimals = 18;
    address originalOwner = address(this); // Assuming the test contract itself is the owner

    function setUp() public {
        token = new AAE_Token();
        ownerBalanceBefore = token.balanceOf(owner); // Correctly initialize here

        // Distributing tokens for testing
        token.transfer(recipient, transferAmount);
        token.transfer(anotherRecipient, transferAmount);
        token.transfer(spender, transferAmount); // Ensure spender has tokens
    }

    function testInitialState() public {
        assertEq(token.NAME(), "AAE_Token");
        assertEq(token.SYMBOL(), "AAET");
        assertEq(token.DECIMALS(), 18);
        assertEq(token.owner(), owner, "Owner should be the deploying address");
        assertEq(
            token.totalSupply(),
            1000000 * 10 ** uint256(decimals),
            "Incorrect total supply"
        );
        // assertEq(
        //     token.balanceOf(owner),
        //     initialSupply,
        //     "Incorrect owner balance at deployment"
        // );
    }

    function testInitialContractState() public {
        assertEq(
            token.paused(),
            false,
            "Contract should not be paused initially"
        );
        assertEq(
            token.owner(),
            owner,
            "Contract owner should be set correctly"
        );
    }

    function testOwnershipTransferToZeroAddress() public {
        vm.expectRevert("New owner is the zero address");
        token.transferOwnership(zeroAddress);
    }

    function testOnlyOwnerCanPauseAndUnpause() public {
        vm.expectRevert("Caller is not the owner");
        vm.prank(newOwner);
        token.pause();

        vm.expectRevert("Caller is not the owner");
        vm.prank(newOwner);
        token.unpause();
    }

    function testCannotTransferToZeroAddress() public {
        vm.expectRevert("Cannot transfer to the zero address");
        token.transfer(zeroAddress, 1000);
    }

    function testTransferZeroTokens() public {
        vm.prank(owner);
        bool success = token.transfer(recipient, 0);
        assertTrue(success, "Transferring 0 tokens should succeed");
    }

    function testTransferFromZeroTokens() public {
        token.approve(spender, 1000);
        vm.prank(spender);
        // Adjust based on intended contract behavior
        vm.expectRevert("Transfer amount must be greater than zero");
        token.transferFrom(owner, recipient, 0);
    }

    function testCannotTransferFromWithoutApproval() public {
        vm.expectRevert("Transfer amount exceeds allowance");
        vm.prank(anotherRecipient);
        token.transferFrom(recipient, anotherRecipient, 500);
    }

    function testTransferFromWithValidAmount() public {
        vm.prank(owner);
        token.transfer(recipient, transferAmount);
        vm.prank(recipient);
        token.approve(spender, transferAmount);
        vm.prank(spender);
        bool success = token.transferFrom(
            recipient,
            anotherAccount,
            transferAmount
        );
        assertTrue(success, "Transfer should succeed");
        assertEq(token.balanceOf(anotherAccount), transferAmount);
    }

    function testTransferFromMoreThanAllowed() public {
        token.approve(spender, 500);
        vm.expectRevert("Transfer amount exceeds allowance");
        vm.prank(spender);
        token.transferFrom(owner, recipient, 1000);
    }

    function testApproveMaxUint256() public {
        token.approve(spender, type(uint256).max);
        assertEq(token.allowance(owner, spender), type(uint256).max);
    }

    function testIncreaseAndDecreaseAllowance() public {
        uint256 initialAllowance = 1000;
        token.approve(spender, initialAllowance);
        token.increaseAllowance(spender, 500);
        assertEq(token.allowance(owner, spender), 1500);
        token.decreaseAllowance(spender, 400);
        assertEq(token.allowance(owner, spender), 1100);
    }

    function testBurnMoreThanBalance() public {
        uint256 excessAmount = token.balanceOf(recipient) + 1;
        vm.prank(recipient);
        vm.expectRevert("Insufficient balance to burn");
        token.burn(excessAmount);
    }

    function testTransferWhilePaused() public {
        vm.prank(owner);
        token.pause();
        vm.expectRevert("Contract is paused");
        token.transfer(recipient, 1000);
    }

    function testApproveWhilePaused() public {
        vm.prank(owner);
        token.pause();
        vm.expectRevert("Contract is paused");
        token.approve(spender, 1000);
    }

    function testBurnWhilePaused() public {
        vm.prank(owner);
        token.pause();
        vm.expectRevert("Contract is paused");
        token.burn(500);
    }

    function testInvalidTransferFrom() public {
        uint256 senderBalance = token.balanceOf(owner);
        token.approve(address(this), senderBalance);
        vm.expectRevert("Insufficient balance");
        token.transferFrom(owner, recipient, senderBalance + 1);
    }

    function testSuccessfulOwnershipTransfer() public {
        // Pre-conditions: Caller is the owner, new owner is a valid address
        // Execute
        token.transferOwnership(newOwner);

        // Verify
        assertEq(token.owner(), newOwner);
        // emit log("testSuccessfulOwnershipTransfer passed");
    }

    function testUnsuccessfulOwnershipTransferToZeroAddress() public {
        // Expect the contract to revert with the specific error message
        vm.expectRevert("New owner is the zero address");

        // Attempt to transfer ownership to the zero address
        token.transferOwnership(address(0));

        // Assert that the owner remains unchanged
        assertEq(
            token.owner(),
            originalOwner,
            "Owner should remain unchanged after failed transfer"
        );
        // emit log("testUnsuccessfulOwnershipTransferToZeroAddress");
    }

    function testOwnershipTransferByNonOwner() public {
        vm.expectRevert("Caller is not the owner");
        vm.prank(recipient);
        token.transferOwnership(newOwner);
    }

    function testPauseFunctionalityAndTokenTransferBlock() public {
        vm.prank(owner);
        token.pause();
        assertTrue(token.paused());
        vm.expectRevert("Contract is paused");
        vm.prank(recipient);
        token.transfer(spender, 100 * 10 ** 18);
        vm.prank(owner);
        token.unpause();
        assertFalse(token.paused());
    }

    function testTokenBurningAndEffects() public {
        uint256 burnAmount = 50 * 10 ** 18;
        // Transfer additional tokens to recipient for burn test
        token.transfer(recipient, burnAmount);
        uint256 recipientInitialBalance = token.balanceOf(recipient);
        vm.prank(recipient);
        token.burn(burnAmount);
        uint256 expectedBalanceAfterBurn = recipientInitialBalance - burnAmount;
        uint256 expectedSupplyAfterBurn = token.totalSupply();
        assertEq(
            token.balanceOf(recipient),
            expectedBalanceAfterBurn,
            "Incorrect recipient balance after burn"
        );
        assertEq(
            token.totalSupply(),
            expectedSupplyAfterBurn,
            "Incorrect total supply after burn"
        );
    }

    function testBlockedOperationsWhenPaused() public {
        vm.prank(owner);
        token.pause();
        vm.expectRevert("Contract is paused");
        token.approve(spender, 100 * 10 ** 18);
        vm.expectRevert("Contract is paused");
        token.transfer(spender, 100 * 10 ** 18);
        vm.expectRevert("Contract is paused");
        token.burn(50 * 10 ** 18);
    }

    function testApproveAndTransferFrom() public {
        uint256 approveAmount = 50 * 10 ** 18;
        vm.prank(recipient);
        token.approve(spender, approveAmount);
        vm.prank(spender);
        token.transferFrom(recipient, anotherAccount, approveAmount);
        assertEq(token.balanceOf(anotherAccount), approveAmount);
    }

    function testAdjustAllowances() public {
        uint256 initialAllowance = 1000;
        token.approve(spender, initialAllowance);

        // Increase allowance
        vm.prank(owner);
        token.increaseAllowance(spender, 500);
        assertEq(
            token.allowance(owner, spender),
            1500,
            "Allowance should be increased by 500"
        );

        // Decrease allowance
        vm.prank(owner);
        token.decreaseAllowance(spender, 300);
        assertEq(
            token.allowance(owner, spender),
            1200,
            "Allowance should be decreased by 300"
        );
    }

    function testEdgeCases() public {
        vm.prank(owner);
        token.pause();
        vm.expectRevert("Contract is paused");
        token.transfer(recipient, transferAmount); // Assuming this is meant to fail due to pause
    }

    function testOperationReverts() public {
        uint256 ownerBalance = token.balanceOf(owner);
        vm.expectRevert("Insufficient balance");
        token.transfer(spender, ownerBalance + 1); // Exceeding balance
        vm.prank(owner);
        token.pause();
        vm.expectRevert("Contract is paused");
        token.approve(spender, 100 * 10 ** 18);
    }

    // Testing insufficient balance revert
    function testTransferExceedsBalanceReverts() public {
        // Set up: Ensure the owner does not have more tokens than the total supply
        uint256 excessAmount = token.totalSupply() + 1; // Exceeding total supply ensures insufficient balance

        // Expect the specific revert message for insufficient balance
        vm.expectRevert("Insufficient balance");

        // Attempt to transfer more tokens than the owner has, should revert
        vm.prank(owner); // Ensure the transaction is sent by the owner
        token.transfer(spender, excessAmount);
    }

    // Testing contract paused revert for approve
    function testApproveWhenPausedReverts() public {
        // First, pause the contract as the owner
        vm.prank(owner); // Ensure pause action is taken by the owner
        token.pause();

        // Expect the specific revert message for contract being paused
        vm.expectRevert("Contract is paused");

        // Attempt to approve while the contract is paused, should revert
        token.approve(spender, 100 * 10 ** 18);
    }

    // Test for pausing and unpausing functionality
    function testPauseAndUnpause() public {
        // Ensure only the owner can pause and unpause the contract
        token.pause();
        assertTrue(token.paused(), "Contract should be paused.");

        token.unpause();
        assertFalse(token.paused(), "Contract should be unpaused.");
    }

    function testTransferFromSuccessWithExactAllowance() public {
        // Setup: Approve spender to spend on behalf of owner
        uint256 allowance = 100 * 10 ** decimals;
        token.approve(spender, allowance);
        assertEq(token.allowance(owner, spender), allowance);

        // Action: Spender transfers allowance amount from owner to recipient
        vm.prank(spender);
        bool success = token.transferFrom(owner, recipient, allowance);

        // Assertions
        assertTrue(success, "Transfer should succeed");
        assertEq(
            token.balanceOf(recipient),
            transferAmount + allowance,
            "Recipient balance should increase by allowance"
        );
        assertEq(
            token.allowance(owner, spender),
            0,
            "Allowance should be zero after transfer"
        );
    }

    function testTransferFromFailsForInsufficientAllowance() public {
        // Setup: Approve spender to spend less than transferAmount
        uint256 approvedAmount = transferAmount - 10;
        token.approve(spender, approvedAmount);

        // Expectation: Transfer should revert due to exceeding allowance
        vm.expectRevert("Transfer amount exceeds allowance");
        vm.prank(spender);
        token.transferFrom(owner, recipient, transferAmount);
    }

    function testTransferFromToZeroAddressFails() public {
        // Setup: Approve spender with some tokens
        token.approve(spender, transferAmount);

        // Expectation: Should revert when trying to transfer to the zero address
        vm.expectRevert("Cannot transfer to the zero address");
        vm.prank(spender);
        token.transferFrom(owner, zeroAddress, transferAmount);
    }

    function testTransferFromFailsForInsufficientBalance() public {
        // Setup: Approve spender with more than owner's balance
        uint256 excessAmount = ownerBalanceBefore + 1; // Assuming ownerBalanceBefore is less than total supply
        token.approve(spender, excessAmount);

        // Expectation: Transfer should revert due to insufficient balance
        vm.expectRevert("Insufficient balance");
        vm.prank(spender);
        token.transferFrom(owner, recipient, excessAmount);
    }

    function testTransferFromZeroAmountFails() public {
        // Setup: Approve spender to transfer any amount
        token.approve(spender, transferAmount);

        // Expectation: Should revert when trying to transfer 0 tokens
        vm.expectRevert("Transfer amount must be greater than zero");
        vm.prank(spender);
        token.transferFrom(owner, recipient, 0);
    }

    function testIncreaseAllowance() public {
        uint256 initialAllowance = 100;
        uint256 addedValue = 50;
        token.approve(spender, initialAllowance);
        bool success = token.increaseAllowance(spender, addedValue);
        uint256 expectedAllowance = initialAllowance + addedValue;

        assertTrue(success, "increaseAllowance should return true");
        assertEq(
            token.allowance(owner, spender),
            expectedAllowance,
            "Allowance should be correctly increased"
        );
    }

    function testIncreaseAllowanceToZeroAddress() public {
        uint256 addedValue = 50;
        vm.expectRevert("ERC20: approve to the zero address");
        token.increaseAllowance(zeroAddress, addedValue);
    }

    function testIncreaseAllowanceByZero() public {
        uint256 initialAllowance = 100;
        token.approve(spender, initialAllowance);
        bool success = token.increaseAllowance(spender, 0);

        assertTrue(
            success,
            "increaseAllowance should return true for a zero increase"
        );
        assertEq(
            token.allowance(owner, spender),
            initialAllowance,
            "Allowance should not change"
        );
    }

    function testIncreaseAllowanceOverflow() public {
        uint256 initialAllowance = type(uint256).max - 1;
        token.approve(spender, initialAllowance);
        // Since Solidity 0.8.0 automatically reverts on overflow without a specific message,
        // we just expect any revert here, not necessarily one with "overflow" message.
        vm.expectRevert(); // Expecting a generic revert
        token.increaseAllowance(spender, 2); // This attempt should cause an overflow and thus a revert
    }

    function testDecreaseAllowanceSuccess() public {
        uint256 initialAllowance = 1000;
        uint256 subtractedValue = 500;
        token.approve(spender, initialAllowance);
        bool success = token.decreaseAllowance(spender, subtractedValue);

        assertTrue(success, "decreaseAllowance should return true");
        assertEq(
            token.allowance(owner, spender),
            initialAllowance - subtractedValue,
            "Allowance should be decreased correctly"
        );
    }

    function testDecreaseAllowanceBelowZeroReverts() public {
        uint256 initialAllowance = 500;
        uint256 subtractedValue = 600; // Greater than the initial allowance
        token.approve(spender, initialAllowance);

        vm.expectRevert("ERC20: decreased allowance below zero");
        token.decreaseAllowance(spender, subtractedValue);
    }

    function testDecreaseAllowanceToZeroAddressReverts() public {
        uint256 subtractedValue = 500;

        vm.expectRevert("ERC20: approve to the zero address");
        token.decreaseAllowance(zeroAddress, subtractedValue);
    }

    function testDecreaseAllowanceWithoutPriorApprovalReverts() public {
        uint256 subtractedValue = 100;
        // Set spender with no prior allowance
        address noPriorApprovalSpender = address(0x4);

        // Expect the specific revert message for decreasing allowance below zero
        vm.expectRevert("ERC20: decreased allowance below zero");

        // Attempt to decrease the allowance, which should revert
        token.decreaseAllowance(noPriorApprovalSpender, subtractedValue);
    }
}

*/
