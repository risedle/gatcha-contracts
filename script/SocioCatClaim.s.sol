// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {SocioCatClaim} from "../src/SocioCatClaim.sol";

contract SocioCatClaimScript is Script {
    function run() public returns (SocioCatClaim claim) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        vm.startBroadcast(deployerPrivateKey);

        claim = new SocioCatClaim();
    }
}
