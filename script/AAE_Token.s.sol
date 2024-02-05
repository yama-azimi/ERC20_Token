// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// scripts/DeployAAE_Token.s.sol
import "forge-std/Script.sol";
import "../src/AAE_Token.sol";

contract DeployAAE_Token is Script {
    function run() external {
        vm.startBroadcast();
        new AAE_Token();
        vm.stopBroadcast();
    }
}
