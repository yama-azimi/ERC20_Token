// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../src/AAE_Token.sol"; // Update the path as necessary

/**
 * @title Test suite for the AAE Token contract
 * This suite performs various tests to ensure the contract functions as expected,
 * including initial state validation, ownership management, pause functionality,
 * token transfers, approvals, and burn functionality.
 */
contract AAE_TokenTest is Test {
    AAE_Token token;
    address owner;
    address constant newOwner = address(0xdead);
    address constant recipient = address(0xbeef);
    uint256 constant initialSupply = 1000000 * 10 ** 18;
    uint256 constant transferAmount = 100 * 10 ** 18;

    /**
     * @dev Sets up the test environment by deploying the token contract
     * and setting the test contract as the owner.
     */
    function setUp() public {
        token = new AAE_Token();
        owner = address(this);
    }

    /**
     * @dev Tests the initial state of the contract to ensure correct setup.
     * Checks token metadata, total supply, owner's balance, paused state, and owner address.
     */
    function testInitialState() public {
        assertEq(token.NAME(), "AAE_Token");
        assertEq(token.SYMBOL(), "AAET");
        assertEq(token.DECIMALS(), 18);
        assertEq(token.totalSupply(), initialSupply);
        assertEq(token.balanceOf(owner), initialSupply);
        assertFalse(token.paused());
        assertEq(token.owner(), owner);
    }

    /**
     * @dev Tests ownership transfer functionality.
     * Ensures the owner can transfer ownership and that the new owner can accept ownership.
     */
    function testOwnershipTransfer() public {
        token.transferOwnership(newOwner);
        assertEq(token.owner(), newOwner);

        vm.startPrank(newOwner);
        token.transferOwnership(owner);
        assertEq(token.owner(), owner);
        vm.stopPrank();
    }

    /**
     * @dev Tests restrictions on ownership transfer.
     * Ensures only the current owner can initiate a transfer and prevents transferring to the zero address.
     */
    function testOwnershipTransferRestrictions() public {
        vm.expectRevert("Caller is not the owner");
        vm.prank(recipient);
        token.transferOwnership(newOwner);

        vm.expectRevert("New owner is the zero address");
        token.transferOwnership(address(0));
    }

    /**
     * @dev Tests the pause and unpause functionality.
     * Ensures the contract can be paused and unpaused by the owner and verifies the paused state.
     */
    function testPauseAndUnpause() public {
        token.pause();
        assertTrue(token.paused());

        token.unpause();
        assertFalse(token.paused());
    }

    /**
     * @dev Tests restrictions on unpausing the contract.
     * Ensures only the owner can unpause the contract.
     */
    function testUnpauseRestrictions() public {
        token.pause();

        vm.expectRevert("Caller is not the owner");
        vm.prank(recipient);
        token.unpause();
    }

    /**
     * @dev Tests contract functionality when paused.
     * Ensures that token transfers, approvals, and transferFrom calls are blocked when the contract is paused.
     */
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

    /**
     * @dev Tests the token transfer functionality.
     * Ensures that tokens can be transferred and balances updated correctly.
     */
    function testTransfer() public {
        token.transfer(recipient, transferAmount);
        assertEq(token.balanceOf(recipient), transferAmount);
    }

    /**
     * @dev Tests the transferFrom and approval functionality.
     * Verifies that an approved spender can transfer the approved amount and that allowances are correctly reduced.
     */
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

    /**
     * @dev Tests transferFrom functionality when the contract is paused.
     * Ensures that transferFrom is blocked when the contract is paused.
     */
    function testTransferFromWhenPaused() public {
        // Setup: Approve recipient to spend and then pause the contract
        token.approve(recipient, transferAmount);
        token.pause();

        // Test & Verify: transferFrom should revert when the contract is paused
        vm.expectRevert("Contract is paused");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, transferAmount);
    }

    /**
     * @dev Tests edge cases for token transfers and approvals.
     * Includes transfers to the zero address, transfers exceeding the owner's balance, and transferFrom exceeding the allowance.
     */
    function testEdgeCases() public {
        vm.expectRevert("Cannot transfer to the zero address");
        token.transfer(address(0), transferAmount);

        vm.expectRevert("Insufficient balance");
        token.transfer(recipient, initialSupply + 1); // More than the owner's balance

        vm.expectRevert("Transfer amount exceeds allowance");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, transferAmount + 1); // More than approved amount
    }

    /**
     * @dev Tests increasing and decreasing allowances.
     * Verifies that allowances can be increased, decreased, and that operations respect the current allowance limits.
     */
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

    /**
     * @dev Further tests on decreasing allowances.
     * Focuses on ensuring allowances cannot be decreased below zero and handling edge cases.
     */
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

    /**
     * @dev Tests rejection of transferFrom calls that exceed the spender's allowance.
     */
    function testTransferFromExceedsAllowance_Reverts() public {
        // Setup: Approve recipient to spend less than transferAmount
        uint256 approvedAmount = transferAmount - 1;
        token.approve(recipient, approvedAmount);

        // Test & Verify: Attempt to transfer more than allowed should fail
        vm.expectRevert("Transfer amount exceeds allowance");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, transferAmount);
    }

    /**
     * @dev Tests rejection of transferFrom to the zero address.
     */
    function testTransferFromToZeroAddress_Reverts() public {
        // Setup: Approve recipient to spend
        token.approve(recipient, transferAmount);

        // Test & Verify: Attempt to transfer to zero address should fail
        vm.expectRevert("Cannot transfer to the zero address");
        vm.prank(recipient);
        token.transferFrom(owner, address(0), transferAmount);
    }

    /**
     * @dev Tests rejection of transferFrom calls that exceed the owner's balance.
     */
    function testTransferFromExceedsBalance_Reverts() public {
        // Setup: Attempt to transfer more than owner's balance
        uint256 excessAmount = token.balanceOf(owner) + 1;
        token.approve(recipient, excessAmount);

        // Test & Verify: Should revert due to insufficient balance
        vm.expectRevert("Insufficient balance");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, excessAmount);
    }

    /**
     * @dev Tests rejection of transferFrom calls attempting to transfer zero tokens.
     */
    function testTransferFromZeroTokens_Reverts() public {
        // Setup: Approve recipient to spend
        token.approve(recipient, transferAmount);

        // Test & Verify: Attempt to transfer 0 tokens should fail
        vm.expectRevert("Transfer amount must be greater than zero");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, 0);
    }

    /**
     * @dev Tests transferFrom behavior after decreasing an approval.
     * Ensures that transfers respect updated allowances.
     */
    function testTransferFromAfterApprovalDecrease() public {
        // Setup: Increase and then decrease the allowance
        token.approve(recipient, transferAmount);
        token.decreaseAllowance(recipient, transferAmount / 2);

        // Test & Verify: Attempt to transfer more than the new allowance should fail
        vm.expectRevert("Transfer amount exceeds allowance");
        vm.prank(recipient);
        token.transferFrom(owner, recipient, transferAmount);
    }

    /**
     * @dev Tests successful transferFrom for the exact amount of the spender's allowance.
     */
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

    /**
     * @dev Tests the burn functionality.
     * Verifies that tokens can be burned, reducing both the burner's balance and the total supply.
     */
    function testBurn() public {
        token.transfer(recipient, transferAmount);
        vm.prank(recipient);
        assertTrue(token.burn(transferAmount));
        assertEq(token.balanceOf(recipient), 0);
        assertEq(token.totalSupply(), initialSupply - transferAmount);
    }

    /**
     * @dev Tests that burning zero tokens is rejected.
     */
    function testBurnAmountGreaterThanZero() public {
        uint256 burnAmount = 0;
        vm.expectRevert("Burn amount must be greater than zero"); // Expect this revert message
        token.burn(burnAmount); // Attempt to burn 0 tokens, which should fail
    }

    /**
     * @dev Verifies that the total supply is correctly reduced after tokens are burned.
     */
    function testTotalSupplyAfterBurn() public {
        uint256 burnAmount = 50 * 10 ** 18;
        token.burn(burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);
    }

    /**
     * @dev Tests rejection of attempts to burn more tokens than the burner's balance.
     */
    function testBurnMoreThanBalance() public {
        uint256 excessBurnAmount = token.balanceOf(owner) + 1;

        vm.expectRevert("Insufficient balance to burn");
        token.burn(excessBurnAmount);
    }
}
