//SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {AAE_Token} from "src/AAE_Token.sol";
import "forge-std/console.sol";

contract AAE_TokenScript is Script {
    function setUp() public {}

    function run() public returns (AAE_Token) {
        vm.startBroadcast();
        AAE_Token aae_token = new AAE_Token();
        vm.stopBroadcast();
        return aae_token;
    }
}
