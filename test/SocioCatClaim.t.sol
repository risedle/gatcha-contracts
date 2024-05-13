// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {SocioCatClaim} from "../src/SocioCatClaim.sol";
import {Token} from "../src/mocks/Token.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SocioCatClaimTest is Test {
    SocioCatClaim public claim;
    Token public token;
    address public signer;
    address public owner;
    uint256 public signerKey;

    event Claimed(bytes32 indexed signatureHash, address indexed to, uint256 amount);
    event SignerUpdated(address indexed signer);

    function setUp() public {
        (signer, signerKey) = makeAddrAndKey("alice");
        (owner, ) = makeAddrAndKey("owner");
        token = new Token();
        claim = new SocioCatClaim(token, signer, owner);
    }

    function test_claim() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        token.mint(address(claim), 100);
        // --

        uint256 expiredAt = block.timestamp + 1;
        bytes memory signature = getSignature(vitalik, 100, 100, expiredAt);

        vm.startPrank(vitalik);
        claim.claim(100, 100, expiredAt, signature, address(0));

        assertEq(token.balanceOf(address(claim)), 0);
        assertEq(token.balanceOf(vitalik), 100);
    }

    function test_emitsClaimed() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        token.mint(address(claim), 100);
        // --

        uint256 expiredAt = block.timestamp + 1;
        bytes memory signature = getSignature(vitalik, 100, 100, expiredAt);

        vm.expectEmit(address(claim));
        emit Claimed(keccak256(signature), vitalik, 100);

        vm.startPrank(vitalik);
        claim.claim(100, 100, expiredAt, signature, address(0));
    }

    function test_claimToReceiver() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        address receiver = 0x220866B1A2219f40e72f5c628B65D54268cA3A9D;
        token.mint(address(claim), 100);
        // --

        uint256 expiredAt = block.timestamp + 1;
        bytes memory signature = getSignature(vitalik, 100, 100, expiredAt);

        vm.startPrank(vitalik);
        claim.claim(100, 100, expiredAt, signature, receiver);
        vm.stopPrank();

        assertEq(token.balanceOf(address(claim)), 0);
        assertEq(token.balanceOf(receiver), 100);
    }

    function test_rejectsInvalidSignature_invalidAmount() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        token.mint(address(claim), 100);
        // --

        uint256 expiredAt = block.timestamp + 1;
        bytes memory signature = getSignature(vitalik, 100, 100, expiredAt);

        vm.expectRevert(SocioCatClaim.InvalidSignature.selector);

        vm.startPrank(vitalik);
        claim.claim(1000, 100, expiredAt, signature, address(0));
        vm.stopPrank();
    }

    function test_rejectsInvalidSignature_invalidMaxAmount() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        token.mint(address(claim), 100);
        // --

        uint256 expiredAt = block.timestamp + 1;
        bytes memory signature = getSignature(vitalik, 100, 100, expiredAt);

        vm.expectRevert(SocioCatClaim.InvalidSignature.selector);

        vm.startPrank(vitalik);
        claim.claim(100, 1000, expiredAt, signature, address(0));
        vm.stopPrank();
    }

    function test_rejectsInvalidSignature_sender() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        token.mint(address(claim), 100);
        // --

        uint256 expiredAt = block.timestamp + 1;
        bytes memory signature = getSignature(vitalik, 100, 100, expiredAt);

        vm.expectRevert(SocioCatClaim.InvalidSignature.selector);
        claim.claim(100, 100, expiredAt, signature, address(0));
    }

    function test_rejectsReusingSignature() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        token.mint(address(claim), 100);
        // --

        uint256 expiredAt = block.timestamp + 1;
        bytes memory signature = getSignature(vitalik, 100, 100, expiredAt);

        vm.startPrank(vitalik);
        claim.claim(100, 100, expiredAt, signature, address(0));

        vm.expectRevert(SocioCatClaim.ExceedingMaxAmount.selector);
        claim.claim(100, 100, expiredAt, signature, address(0));
        vm.stopPrank();
    }

    function test_rejectsExpiredSignature() public {
        address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        token.mint(address(claim), 100);
        // --

        uint256 expiredAt = block.timestamp;
        bytes memory signature = getSignature(vitalik, 100, 100, expiredAt);

        vm.startPrank(vitalik);
        vm.expectRevert(SocioCatClaim.ExpiredSignature.selector);
        claim.claim(100, 100, expiredAt, signature, address(0));
        vm.stopPrank();
    }

    function test_setSigner() public {
        (address newSigner, ) = makeAddrAndKey("newSigner");
        // --

        vm.startPrank(owner);
        claim.setSigner(newSigner);
        vm.stopPrank();

        assertEq(claim.signer(), newSigner);
    }

    function test_setSigner_rejectsZeroSigner() public {
        vm.expectRevert(SocioCatClaim.ZeroAddress.selector);

        vm.startPrank(owner);
        claim.setSigner(address(0));
        vm.stopPrank();
    }

    function test_setSigner_rejectsNotOwner() public {
        (address newSigner, ) = makeAddrAndKey("newSigner");
        // --

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(this)
            )
        );
        claim.setSigner(newSigner);
    }

    function test_setSigner_emitsSignerUpdated() public {
        (address newSigner, ) = makeAddrAndKey("newSigner");
        // --

        vm.expectEmit(address(claim));
        emit SignerUpdated(newSigner);

        vm.startPrank(owner);
        claim.setSigner(newSigner);
        vm.stopPrank();
    }

    function getSignature(
        address to,
        uint256 amount,
        uint256 maxAmount,
        uint256 expiredAt
    ) private returns (bytes memory signature) {
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            signerKey,
            keccak256(
                abi.encodePacked(
                    block.chainid,
                    to,
                    amount,
                    maxAmount,
                    expiredAt
                )
            )
        );
        signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
    }
}
