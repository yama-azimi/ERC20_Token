// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../src/AAE_Token.sol";

/// @title Test suite for the AAE_Token smart contract
/// @notice Uses Foundry's test framework to ensure contract functionality is correct
contract AAE_TokenTest is Test {
    AAE_Token public token;
    address public owner;
    address public newOwner;
    address public recipient;
    address public anotherRecipient;
    address public spender;
    address public zeroAddress = address(0x0);
    uint256 public initialTransferAmount = 100 * 10 ** 18;
    uint256 public initialSupply = 100000 * 10 ** 18;
    address public anotherAccount = address(0x5); // Added declaratio

    /// @notice Sets up the test environment by deploying the token contract and setting initial addresses
    function setUp() public {
        owner = address(this); // Contract deploying the token is the initial owner
        newOwner = address(0x1);
        recipient = address(0x2);
        anotherRecipient = address(0x3);
        spender = address(0x4);
        token = new AAE_Token();
    }

    /// @notice Tests the initial state of the token contract to ensure correct setup
    /// @dev Checks token name as an example; other state variables should be checked similarly
    function testInitialState() public {
        assertEq(token.name(), "AAE_Token");
        // Other state checks omitted for brevity
    }

    /// @notice Tests that ownership cannot be transferred to the zero address
    /// @dev Simulates the owner calling transferOwnership with the zero address and expects a revert
    function testOwnershipTransferToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("New owner is the zero address");
        token.transferOwnership(address(0));
    }

    /// @notice Ensures that only the current owner can pause and unpause the contract
    /// @dev Attempts to pause and unpause the contract from a non-owner address and checks for reverts
    function testOnlyOwnerCanPauseAndUnpause() public {
        // Attempting to pause by non-owner
        vm.prank(newOwner);
        vm.expectRevert("Caller is not the owner");
        token.pause();

        // Attempting to unpause by non-owner
        vm.prank(newOwner);
        vm.expectRevert("Caller is not the owner");
        token.unpause();
    }

    /// @notice Verifies that tokens cannot be transferred to the zero address
    /// @dev Expects a revert when trying to transfer tokens to the zero address
    function testCannotTransferToZeroAddress() public {
        vm.expectRevert("Cannot transfer to the zero address");
        token.transfer(address(0), 1000);
    }

    /// @notice Tests that a transfer from an address without approval should fail
    /// @dev First transfers tokens to a recipient, then attempts an unapproved transfer from them
    function testCannotTransferFromWithoutApproval() public {
        token.transfer(recipient, 1000); // Ensure recipient has some tokens
        vm.prank(anotherRecipient); // Attempt transfer without approval
        vm.expectRevert("Transfer amount exceeds allowance");
        token.transferFrom(recipient, anotherRecipient, 500);
    }

    /// @notice Checks that transferring more than the approved amount is not allowed
    /// @dev Approves a spender for a certain amount and attempts to transfer more than that
    function testTransferFromMoreThanAllowed() public {
        token.approve(spender, 500);
        vm.prank(spender);
        vm.expectRevert("Transfer amount exceeds allowance");
        token.transferFrom(owner, recipient, 1000);
    }

    /// @notice Tests that the maximum uint256 value can be approved and checked
    /// @dev Approves a spender with the max uint256 value and verifies the allowance
    function testApproveMaxUint256() public {
        token.approve(spender, type(uint256).max);
        assertEq(token.allowance(owner, spender), type(uint256).max);
    }

    /// @notice Verifies that allowances can be successfully increased and decreased
    /// @dev Increases and decreases an allowance and checks for correct allowance adjustment
    function testIncreaseAndDecreaseAllowance() public {
        uint256 initialAllowance = 1000;
        token.approve(spender, initialAllowance);

        // Increasing allowance
        uint256 increaseAmount = 500;
        token.increaseAllowance(spender, increaseAmount);
        assertEq(
            token.allowance(owner, spender),
            initialAllowance + increaseAmount
        );

        // Decreasing allowance
        uint256 decreaseAmount = 400;
        token.decreaseAllowance(spender, decreaseAmount);
        assertEq(
            token.allowance(owner, spender),
            initialAllowance + increaseAmount - decreaseAmount
        );

        // Attempting to decrease allowance below zero
        vm.expectRevert("ERC20: decreased allowance below zero");
        token.decreaseAllowance(spender, initialAllowance + increaseAmount);
    }

    /// @notice Ensures that attempting to burn more tokens than one's balance results in a revert
    /// @dev Attempts to burn a token amount greater than the owner's balance
    function testBurnMoreThanBalance() public {
        uint256 burnAmount = token.balanceOf(owner) + 1; // More than available balance
        vm.expectRevert("Insufficient balance to burn");
        token.burn(burnAmount);
    }

    /// @notice Tests that token transfers are not allowed when the contract is paused
    /// @dev Pauses the contract and attempts a token transfer, expecting it to fail
    function testTransferWhilePaused() public {
        vm.prank(owner);
        token.pause();

        vm.expectRevert("Contract is paused");
        token.transfer(recipient, 1000);
    }

    /// @notice Checks that token approvals are blocked when the contract is paused
    /// @dev Pauses the contract and attempts to approve a spender, expecting failure
    function testApproveWhilePaused() public {
        vm.prank(owner);
        token.pause();

        vm.expectRevert("Contract is paused");
        token.approve(spender, 1000);
    }

    /// @notice Verifies that tokens cannot be burned when the contract is paused
    /// @dev Pauses the contract and attempts to burn tokens, expecting a revert
    function testBurnWhilePaused() public {
        vm.prank(owner);
        token.pause();

        vm.expectRevert("Contract is paused");
        token.burn(500);
    }

    /// @notice Tests for a revert when attempting to transfer more tokens than available from an account
    /// @dev Approves a transfer for the exact balance and then attempts to transfer more, expecting a revert
    function testInvalidTransferFrom() public {
        uint256 senderBalance = token.balanceOf(owner);
        uint256 transferAmount = senderBalance + 1; // More than available balance
        token.approve(address(this), senderBalance); // Approve up to the balance

        vm.expectRevert("Insufficient balance");
        token.transferFrom(owner, recipient, transferAmount);
    }

    /// @notice Validates the initial contract setup.
    /// @dev Asserts on the contract's initial state variables for correctness.
    function testInitialContractState() public {
        assertEq(token.name(), "AAE_Token", "Should match the token name.");
        assertEq(token.symbol(), "AAET", "Should match the token symbol.");
        assertEq(token.decimals(), 18, "Should match the token decimals.");
        assertEq(
            token.totalSupply(),
            initialSupply,
            "Should reflect the initial total supply."
        );
        assertEq(
            token.balanceOf(owner),
            initialSupply - initialTransferAmount,
            "Owner's balance should account for the initial transfer."
        );
        assertFalse(token.paused(), "Contract should initially be unpaused.");
    }

    /// @notice Tests the functionality of ownership transfer including event emission.
    function testSuccessfulOwnershipTransfer() public {
        // Set up expectations for the event emission
        vm.expectEmit(true, true, true, true);
        // Parameters are: expect log (bool), expect caller (bool), expect topic (bool), expect data (bool)

        // No need to manually emit the event in the test - just specify the expected event
        // The OwnershipTransferred event should be defined in the AAE_Token contract

        // Simulate calling the function as the owner
        vm.prank(owner);
        token.transferOwnership(newOwner);

        // Assert that the ownership has successfully been transferred
        assertEq(
            token.owner(),
            newOwner,
            "Ownership should transfer to newOwner."
        );
    }

    /// @notice Confirms that only the current owner can initiate ownership transfer.
    function testOwnershipTransferByNonOwner() public {
        vm.prank(recipient);
        vm.expectRevert("Caller is not the owner");
        token.transferOwnership(newOwner);
    }

    /// @notice Tests the pause functionality and ensures it blocks token transfers.
    function testPauseFunctionalityAndTokenTransferBlock() public {
        vm.prank(owner);
        token.pause();
        assertTrue(token.paused(), "Contract should be paused.");

        vm.prank(recipient);
        vm.expectRevert("Contract is paused");
        token.transfer(spender, 100 * 10 ** 18);

        vm.prank(owner);
        token.unpause();
        assertFalse(
            token.paused(),
            "Contract should be unpaused after calling unpause."
        );
    }

    /// @notice Ensures that token burning is correctly implemented and affects total supply and balances.
    function testTokenBurningAndEffects() public {
        uint256 burnAmount = 500 * 10 ** 18;
        vm.prank(recipient);
        token.burn(burnAmount);

        assertEq(
            token.totalSupply(),
            initialSupply - initialTransferAmount - burnAmount,
            "Total supply should decrease by burn amount."
        );
        assertEq(
            token.balanceOf(recipient),
            initialTransferAmount - burnAmount,
            "Recipient's balance should decrease by burn amount."
        );
    }

    /// @notice Verifies that actions such as approve, transfer, and burn are blocked when the contract is paused.
    function testBlockedOperationsWhenPaused() public {
        vm.prank(owner);
        token.pause();

        vm.prank(recipient);
        vm.expectRevert("Contract is paused");
        token.approve(spender, 100 * 10 ** 18);

        vm.expectRevert("Contract is paused");
        token.transfer(spender, 100 * 10 ** 18);

        vm.expectRevert("Contract is paused");
        token.burn(50 * 10 ** 18);
    }

    /// @notice Tests the approve and transferFrom functionality respecting allowances.
    function testApproveAndTransferFrom() public {
        uint256 approveAmount = 500 * 10 ** 18;
        vm.prank(recipient);
        token.approve(spender, approveAmount);

        vm.prank(spender);
        token.transferFrom(recipient, anotherAccount, approveAmount);
        assertEq(
            token.balanceOf(anotherAccount),
            approveAmount,
            "Balance should match the approved transfer amount."
        );
    }

    /// @notice Verifies that increaseAllowance and decreaseAllowance work as expected.
    function testAdjustAllowances() public {
        uint256 approveAmount = 500 * 10 ** 18;
        uint256 increaseAmount = 200 * 10 ** 18;
        uint256 decreaseAmount = 100 * 10 ** 18;

        vm.prank(recipient);
        token.approve(spender, approveAmount);

        vm.prank(recipient);
        token.increaseAllowance(spender, increaseAmount);
        assertEq(
            token.allowance(recipient, spender),
            approveAmount + increaseAmount,
            "Allowance should be increased correctly."
        );

        vm.prank(recipient);
        token.decreaseAllowance(spender, decreaseAmount);
        assertEq(
            token.allowance(recipient, spender),
            approveAmount + increaseAmount - decreaseAmount,
            "Allowance should be decreased correctly."
        );
    }

    /// @notice Tests edge cases such as transferring to the zero address and burning with insufficient balance.
    function testEdgeCases() public {
        // Transfer to zero address
        vm.prank(recipient);
        vm.expectRevert("Cannot transfer to the zero address");
        token.transfer(zeroAddress, 100 * 10 ** 18);

        // Burn more than balance
        vm.prank(recipient);
        vm.expectRevert("Insufficient balance to burn");
        token.burn(initialSupply); // Attempt to burn more than the recipient's balance
    }

    /// @notice Ensures operations revert correctly under various failure conditions.
    function testOperationReverts() public {
        // Transfer more than balance
        vm.prank(recipient);
        vm.expectRevert("Insufficient balance");
        token.transfer(spender, initialSupply); // Attempt to transfer more than the current balance

        // Approve from paused state
        vm.prank(owner);
        token.pause();
        vm.prank(recipient);
        vm.expectRevert("Contract is paused");
        token.approve(spender, 100 * 10 ** 18);
    }

    // Additional tests for specific edge cases and state transitions can be added here
}
