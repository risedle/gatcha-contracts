// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SocioCatClaim {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;

    constructor(IERC20 _token) {
        token = _token;
    }

    function claim(address to, uint256 amount) external {
        token.safeTransfer(to, amount);
    }
}
