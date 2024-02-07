// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {AAE_Token} from "../src/AAE_Token.sol";
import "forge-std/console.sol";

contract DeployAAE_Token is Script {
    function setUp() public {}

    function run() external returns (AAE_Token) {
        vm.startBroadcast();

        // Deploy the ABD_Token contract with the specified total supply
        AAE_Token aae_token = new AAE_Token();

        vm.stopBroadcast();
        return aae_token;
    }
}
