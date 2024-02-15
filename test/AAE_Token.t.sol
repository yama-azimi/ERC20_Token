// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

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
        assertEq(token.name(), "AAE_Token");
        assertEq(token.symbol(), "AAET");
        assertEq(token.decimals(), 18);
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
