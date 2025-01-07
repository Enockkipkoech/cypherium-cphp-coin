// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CypherPup} from "../src/CypherPup.sol";

contract CypherPupTest is Test {
    CypherPup public cypherPup;

    // address public owner = address(1);
    address _multisigWallet = makeAddr("_multisigWallet");
    address _liquidityWallet = makeAddr("_liquidityWallet");
    address _publicSale = makeAddr("_publicSale");
    address _communityRewards = makeAddr("_communityRewards");
    address _liquidityPools = makeAddr("_liquidityPools");
    address _developmentFund = makeAddr("_developmentFund");
    address _marketingPartnership = makeAddr("_marketingPartnership");
    address _teamAdvisors = makeAddr("_teamAdvisors");
    address _charitableFund = makeAddr("_charitableFund");

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    uint256 constant TOTAL_SUPPLY = 50_000_000_000 * 10 ** 18;
    uint256 constant MAX_WALLET_CAP = (TOTAL_SUPPLY * 2) / 100;
    uint256 constant TRANSACTION_LIMIT = (TOTAL_SUPPLY * 5) / 1000;

    // WALLET PARAMS

    function setUp() public {
        console.log("Testing CypherPup contract...");

        vm.label(_multisigWallet, "Owner");
        vm.label(user1, "User1");
        vm.label(user2, "User2");

        // Deploy CypherPup contract

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

        assertEq(cypherPup.owner(), _multisigWallet);
        assertEq(cypherPup.liquidityWallet(), _liquidityWallet);
        assertEq(cypherPup.totalSupply(), TOTAL_SUPPLY);
    }

    // Test setting redistribution fee
    function testSetRedistributionFee() public {
        vm.startPrank(_multisigWallet);
        cypherPup.setRedistributionFee(2);
        assertEq(cypherPup.redistributionFee(), 2);
        vm.stopPrank();
    }

    // Test setting redistribution fee above limit
    function testSetRedistributionFeeAboveLimit() public {
        vm.startPrank(_multisigWallet);
        vm.expectRevert("Fee cannot exceed 10%");
        cypherPup.setRedistributionFee(15);
        vm.stopPrank();
    }

    // Test setting burn fee
    function testSetBurnFee() public {
        vm.startPrank(_multisigWallet);
        cypherPup.setBurnFee(1);
        assertEq(cypherPup.burnFee(), 1);
        vm.stopPrank();
    }

    // Test setting burn fee above limit
    function testSetBurnFeeAboveLimit() public {
        vm.startPrank(_multisigWallet);
        vm.expectRevert("Fee cannot exceed 10%");
        cypherPup.setBurnFee(15);
        vm.stopPrank();
    }

    // Test excluding address from fees
    function testExcludeFromFees() public {
        vm.startPrank(_multisigWallet);
        cypherPup.excludeFromFees(user1, true);
        assertTrue(cypherPup.isExcludedFromFees(user1));
        vm.stopPrank();
    }

    // Test transferring tokens exceeding transaction limit
    function testTransferExceedingTransactionLimit() public {
        vm.startPrank(_multisigWallet);
        uint256 largeAmount = TRANSACTION_LIMIT + 1;
        vm.expectRevert("Exceeds transaction limit");
        cypherPup.transfer(user2, largeAmount);
        vm.stopPrank();
    }

    // Test transferring tokens within transaction limit
    // function testTransferWithinTransactionLimit() public {
    //     vm.startPrank(multisigWallet);
    //     uint256 validAmount = TRANSACTION_LIMIT;
    //     cypherPup.transfer(multisigWallet, user1, validAmount);
    //     // vm.expectCall(user1, "transfer", validAmount);
    //     cypherPup.transfer(user1, user2, validAmount);
    //     vm.stopPrank();
    // }

    // Test wallet exceeding max cap
    function testWalletExceedsMaxCap() public {
        vm.startPrank(_multisigWallet);
        uint256 amount = MAX_WALLET_CAP + 1;
        vm.expectRevert("Exceeds max wallet cap");
        cypherPup.transfer(user2, amount);
        vm.stopPrank();
    }

    // Test transfer with fees applied when contract is not paused
    // function testTransferWithFeesNotPaused() public {
    //     vm.startPrank(multisigWallet);
    //     uint256 amount = 5000;
    //     cypherPup.transfer(multisigWallet, user1, amount);
    //     uint256 initialBalance = cypherPup.balanceOf(user1);
    //     console.log("Initial balance of user1: ", initialBalance);
    //     cypherPup.transfer(user1, user2, amount);

    //     uint256 finalBalance = cypherPup.balanceOf(user1);
    //     assertEq(finalBalance, initialBalance - amount);
    //     vm.stopPrank();
    // }

    // Test contract pause/unpause
    function testPauseAndUnpause() public {
        vm.startPrank(_multisigWallet);
        cypherPup.pause();
        assertTrue(cypherPup.paused());

        cypherPup.unpause();
        assertFalse(cypherPup.paused());
        vm.stopPrank();
    }

    function test_getPauseStatus() public view {
        bool isPaused = cypherPup.paused();
        console.log("Is CypherPup paused? ", isPaused);
    }

    // Test minting tokens
    function testMint() public {
        vm.startPrank(_multisigWallet);
        uint256 mintAmount = 1000;
        uint256 initialBalance = cypherPup.balanceOf(user1);

        cypherPup.mint(user1, mintAmount);

        uint256 finalBalance = cypherPup.balanceOf(user1);
        assertEq(finalBalance, initialBalance + mintAmount);
        vm.stopPrank();
    }
}
