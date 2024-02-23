# AAE Token Smart Contract

## Overview

The AAE Token demonstrates a robust implementation of the ERC20 standard, enhanced with advanced features like ownership management, pausability, and burnability. Developed using the Foundry framework and deployed on the Ethereum Sepolia testnet, this project is designed to illustrate a comprehensive approach to smart contract development for decentralized applications.

## Features

- **ERC20 Standard Compliance**: Adheres to the widely recognized ERC20 standard, ensuring interoperability with Ethereum's ecosystem.
- **Ownership Transfer**: Facilitates secure transitions of contract ownership, essential for administrative control.
- **Pausable Operations**: Introduces mechanisms to halt and resume contract interactions, enhancing security and manageability.
- **Token Burnability**: Incorporates a burn function to decrease the total token supply, a common feature for managing token economics.

## Contract Specifications

The AAE Token is built with the following core specifications:

- **Token Name**: `AAE_Token`
- **Symbol**: `AAET`
- **Decimals**: 18, allowing for fractional transactions.
- **Initial Supply**: Set at 100,000 tokens, accounting for decimal precision.
- **Total Supply**: Starts at 1,000,000 tokens, adjustable through burning actions.

## Core Functions

- `transferOwnership(address newOwner)`: Changes the contract's ownership to a new account, reinforcing security protocols.
- `pause() / unpause()`: Enables or disables the contract's transactional capabilities, controlled exclusively by the owner.
- `burn(uint256 amount)`: Permanently removes a specified amount of tokens from circulation, affecting the total supply.
- `transfer(address to, uint256 amount)`: Conducts token transfers, moving funds between accounts securely.
- `transferFrom(address from, address to, uint256 amount)`: Facilitates third-party transfers with prior authorization.
- `approve(address spender, uint256 amount)`: Authorizes another account to spend tokens on behalf of the token holder.
- `allowance(address _owner, address _spender)`: Queries the approved spending limit set by the token owner for another account.
- `balanceOf(address account)`: Retrieves the current token balance of a given account.

## Events

The contract emits events for significant actions:

- **Transfer**: Indicates successful token transfers.
- **Approval**: Signals the approval of a spender by the token owner.
- **OwnershipTransferred**: Marks the change of contract ownership.
- **Paused / Unpaused**: Reflects the pausing or unpausing of contract functions.
- **Burn**: Announces the burning of tokens, reducing the total supply.

## Using Foundry for Development

Foundry provides a powerful, efficient environment for smart contract development and testing. Follow these steps to work with the AAE Token:

1. **Installation**: Ensure Foundry is installed. Refer to the [Foundry installation guide](https://book.getfoundry.sh/getting-started/installation.html).
2. **Deployment**: Use Foundry's `forge create` command to deploy the contract to the Sepolia testnet, adjusting parameters as necessary.
3. **Interaction**: After deployment, the contract can be verified and interacted with on the Sepolia testnet via the Sepolia Etherscan.

## License

This project is licensed under the MIT License, supporting open and permissive software use, modification, and distribution.

---

Deployment Scripts: forge script script/1_Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY -- etherscan-api $ETHERSCAN_API_KEY --broadcast -vvv
