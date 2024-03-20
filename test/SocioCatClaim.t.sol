// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {SocioCatClaim} from "../src/SocioCatClaim.sol";
import {Token} from "../src/mocks/Token.sol";

contract SocioCatClaimTest is Test {
    SocioCatClaim public claim;
    Token public token;
    function setUp() public {
        token = new Token();
        claim = new SocioCatClaim(token);
    }

    function test_claim() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        token.mint(address(claim), 100);
        // --

        vm.startPrank(vitalik);
        claim.claim(100, address(0));
        claim.claim(100, vitalik);

        assertEq(token.balanceOf(address(claim)), 0);
        assertEq(token.balanceOf(vitalik), 100);
    }

    function test_claimToReceiver() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        address receiver = 0x220866B1A2219f40e72f5c628B65D54268cA3A9D;
        token.mint(address(claim), 100);
        // --

        vm.startPrank(vitalik);
        claim.claim(100, receiver);
        vm.stopPrank();

        assertEq(token.balanceOf(address(claim)), 0);
        assertEq(token.balanceOf(receiver), 100);
    }
}
