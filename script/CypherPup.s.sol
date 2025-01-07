// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CypherPup} from "../src/CypherPup.sol";

contract CypherPupScript is Script {
    CypherPup public cypherPup;

    function setUp() public {
        // address _owner = vm.envAddress("OWNER_ADDRESS");
        address _multisigWallet = vm.envAddress("MULTISIG_WALLET");
        address _liquidityWallet = vm.envAddress("LIQUIDITY_WALLET");
        address _publicSale = makeAddr("_publicSale");
        address _communityRewards = makeAddr("_communityRewards");
        address _liquidityPools = makeAddr("_liquidityPools");
        address _developmentFund = makeAddr("_developmentFund");
        address _marketingPartnership = makeAddr("_marketingPartnership");
        address _teamAdvisors = makeAddr("_teamAdvisors");
        address _charitableFund = makeAddr("_charitableFund");

        cypherPup = new CypherPup(
            _multisigWallet,
            _liquidityWallet,
            _publicSale,
            _communityRewards,
            _liquidityPools,
            _developmentFund,
            _marketingPartnership,
            _teamAdvisors,
            _charitableFund
        );
        console.log(
            "CypherPup contract deployed at: ",
            address(cypherPup),
            " with owner: ",
            _multisigWallet
        );
    }

    function run() public {
        vm.startBroadcast();
        console.log("Setting up CypherPup contract & deploying it...");
        setUp();

        vm.stopBroadcast();
    }
}
