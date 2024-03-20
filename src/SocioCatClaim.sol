// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SocioCatClaim {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    address public signer;

    error InvalidSignature();
    error InvalidNonce();

    event Claimed(address indexed to, uint256 amount);

    constructor(IERC20 _token, address _signer) {
        signer = _signer;
        token = _token;
    }

    function claim(
        uint256 amount,
        uint256 nonce,
        bytes calldata signature,
        address receiver
    ) external {
        if (receiver == address(0)) {
            receiver = msg.sender;
        }

        token.safeTransfer(receiver, amount);
    }
}
