// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {SocioCatClaim} from "../src/SocioCatClaim.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SocioCatClaimScript is Script {
    function run() public returns (SocioCatClaim claim) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        IERC20 token = IERC20(vm.envAddress("TOKEN"));
        address signer = vm.envAddress("SIGNER");
        vm.startBroadcast(deployerPrivateKey);

        claim = new SocioCatClaim(token, signer);
    }
}
