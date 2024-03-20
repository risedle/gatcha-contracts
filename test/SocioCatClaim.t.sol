// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {SocioCatClaim} from "../src/SocioCatClaim.sol";
import {Token} from "../src/mocks/Token.sol";

contract SocioCatClaimTest is Test {
    SocioCatClaim public claim;
    Token public token;
    address public signer;
    uint256 public signerKey;

    event Claimed(address indexed to, uint256 amount);

    function setUp() public {
        (signer, signerKey) = makeAddrAndKey("alice");
        token = new Token();
        claim = new SocioCatClaim(token, signer);
    }

    function test_claim() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        token.mint(address(claim), 100);
        // --

        uint256 nonce = vm.getBlockTimestamp();
        bytes memory signature = getSignature(vitalik, 100, nonce);

        vm.startPrank(vitalik);
        claim.claim(100, nonce, signature, address(0));

        assertEq(token.balanceOf(address(claim)), 0);
        assertEq(token.balanceOf(vitalik), 100);
    }

    function test_emitsClaimed() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        token.mint(address(claim), 100);
        // --

        uint256 nonce = vm.getBlockTimestamp();
        bytes memory signature = getSignature(vitalik, 100, nonce);

        vm.expectEmit(address(claim));
        emit Claimed(vitalik, 100);

        vm.startPrank(vitalik);
        claim.claim(100, nonce, signature, address(0));
    }

    function test_claimToReceiver() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        address receiver = 0x220866B1A2219f40e72f5c628B65D54268cA3A9D;
        token.mint(address(claim), 100);
        // --

        uint256 nonce = vm.getBlockTimestamp();
        bytes memory signature = getSignature(vitalik, 100, nonce);

        vm.startPrank(vitalik);
        claim.claim(100, nonce, signature, receiver);
        vm.stopPrank();

        assertEq(token.balanceOf(address(claim)), 0);
        assertEq(token.balanceOf(receiver), 100);
    }

    function test_rejectsInvalidSignature() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        token.mint(address(claim), 100);
        // --

        uint256 nonce = vm.getBlockTimestamp();
        bytes memory signature = getSignature(vitalik, 100, nonce);

        vm.expectRevert(SocioCatClaim.InvalidSignature.selector);

        vm.startPrank(vitalik);
        claim.claim(1000, nonce, signature, address(0));
        vm.stopPrank();
    }

    function test_rejectsReusingSameNonce() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        token.mint(address(claim), 100);
        // --

        uint256 nonce = vm.getBlockTimestamp();
        bytes memory signature = getSignature(vitalik, 100, nonce);

        vm.startPrank(vitalik);
        claim.claim(100, nonce, signature, address(0));

        vm.expectRevert(SocioCatClaim.InvalidNonce.selector);
        claim.claim(100, nonce, signature, address(0));
        vm.stopPrank();
    }

    function getSignature(
        address to,
        uint256 amount,
        uint256 nonce
    ) private returns (bytes memory signature) {
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            signerKey,
            keccak256(abi.encodePacked(to, amount, nonce))
        );
        signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
    }
}
