// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CypherPup} from "../src/CypherPup.sol";

contract CypherPupScript is Script {
    CypherPup public cypherPup;

    function setUp() public {
        address owner = vm.envAddress("OWNER_ADDRESS");
        address multisigWallet = vm.envAddress("MULTISIG_WALLET");
        address liquidityWallet = vm.envAddress("LIQUIDITY_WALLET");

        cypherPup = new CypherPup(liquidityWallet, multisigWallet);
        console.log(
            "CypherPup contract deployed at: ",
            address(cypherPup),
            " with owner: ",
            owner
        );
    }

    function run() public {
        vm.startBroadcast();
        console.log("Setting up CypherPup contract & deploying it...");
        setUp();

        vm.stopBroadcast();
    }
}
