//SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

// Imports the Script and console2 from the forge-std library for script writing and debugging purposes in Foundry.
import {Script, console2} from "forge-std/Script.sol";
// Imports the AAE_Token contract from the specified path to enable deployment and interaction within this script.
import {AAE_Token} from "../src/AAE_Token.sol";
// Imports additional debugging tools from forge-std to facilitate development and testing.
import "forge-std/console.sol";

// Declares a new contract, AAE_TokenScript, for the purpose of deploying the AAE_Token contract, inheriting functionalities from the Script contract.
contract AAE_TokenScript is Script {
    // A setup function that can be used for pre-deployment configurations or initializations. It's empty by default, indicating no setup is required.
    function setUp() public {}

    // The run function, marked as external, defines the main logic to deploy the AAE_Token contract and returns the deployed contract instance.
    // This function can be called from outside the contract.
    function run() external returns (AAE_Token) {
        // Signals the start of contract deployment or other transaction broadcasts within this function.
        vm.startBroadcast();

        // Deploys the AAE_Token contract. This line initializes a new instance of AAE_Token, effectively deploying it to the blockchain.
        AAE_Token aae_token = new AAE_Token();

        // Signals the end of the deployment process or transaction broadcasts, finalizing the changes on the blockchain.
        vm.stopBroadcast();

        // Returns the instance of the deployed AAE_Token contract, allowing external callers to interact with the contract.
        return aae_token;
    }
}
