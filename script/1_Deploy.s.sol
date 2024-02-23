// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import "../src/AAE_Token.sol";

contract AAE_TokenScript is Script {
    function run() external {
        vm.startBroadcast();

        new AAE_Token();

        vm.stopBroadcast();
    }
}
