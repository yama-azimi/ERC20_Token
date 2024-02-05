// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../src/AAE_Token.sol";

/// @title AAE_TokenTest
/// @notice A test suite for the AAE_Token smart contract
contract AAE_TokenTest is Test {
    AAE_Token public token;
    address public owner;
    address public alice;
    address public bob;

    /// @notice Setup runs before each test case
    function setUp() public {
        owner = address(this); // Test contract is the owner
        alice = address(0x1);
        bob = address(0x2);
        token = new AAE_Token();
    }

    /// @notice Test initial token distribution
    function testInitialSupply() public {
        // Check that the total supply is correct
        assertEq(token.totalSupply(), 1e6 ether);
        // Check that the owner received the initial circulating supply
        assertEq(token.balanceOf(owner), 100000 ether);
    }

    /// @notice Test token transfer functionality
    function testTransfer() public {
        uint256 transferAmount = 100 ether;
        token.transfer(alice, transferAmount);

        // Verify balances after transfer
        assertEq(token.balanceOf(owner), 100000 ether - transferAmount);
        assertEq(token.balanceOf(alice), transferAmount);
    }

    /// @notice Test failing transfer when contract is paused
    function testFailTransferWhenPaused() public {
        token.pause();
        token.transfer(alice, 100 ether); // This should fail
    }

    /// @notice Test pausing and unpausing the contract
    function testPauseAndUnpause() public {
        token.pause();
        assertTrue(token.paused());

        token.unpause();
        assertFalse(token.paused());
    }

    /// @notice Test the burn functionality
    function testBurn() public {
        uint256 burnAmount = 50 ether;
        uint256 initialBalance = token.balanceOf(owner);

        token.burn(burnAmount);

        // Verify balances after burn
        assertEq(token.balanceOf(owner), initialBalance - burnAmount);
        // Verify total supply after burn
        assertEq(token.totalSupply(), 1e6 ether - burnAmount);
    }

    /// @notice Test the approve and transferFrom functionality
    function testApproveAndTransferFrom() public {
        token.approve(alice, 100 ether);
        // Simulate the next call coming from `alice`
        vm.prank(alice);
        token.transferFrom(owner, bob, 100 ether);

        // Verify balances after transferFrom
        assertEq(token.balanceOf(bob), 100 ether);
        assertEq(token.allowance(owner, alice), 0);
    }

    /// @notice Test ownership transfer
    function testOwnershipTransfer() public {
        token.transferOwnership(alice);
        assertEq(token.owner(), alice);
    }

    /// @notice Test failing ownership transfer by non-owner
    function testFailTransferOwnershipByNonOwner() public {
        vm.prank(alice); // Next call comes from alice
        token.transferOwnership(bob); // Should fail
    }
}
