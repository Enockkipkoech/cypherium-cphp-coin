// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CypherPup} from "../src/CypherPup.sol";

contract CypherPupTest is Test {
    CypherPup public cypherPup;

    address public owner = address(0x123);
    address public multisigWallet = address(0x456);
    address public liquidityWallet = address(0x789);

    function setUp() public {
        console.log("Testing CypherPup contract...");
        cypherPup = new CypherPup(liquidityWallet, multisigWallet);
        console.log(
            "CypherPup contract deployed at: ",
            address(cypherPup),
            " with owner: ",
            owner
        );
    }

    function test_getPauseStatus() public {
        bool isPaused = cypherPup.paused();
        console.log("Is CypherPup paused? ", isPaused);
    }
}
