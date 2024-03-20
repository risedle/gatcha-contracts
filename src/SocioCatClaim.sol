// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract SocioCatClaim is Ownable2Step {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    address public signer;
    mapping(address => uint256) public claimedAmounts;

    error InvalidSignature();
    error ExceedingMaxAmount();
    error ZeroAddress();

    event Claimed(address indexed to, uint256 amount);
    event SignerSet(address indexed signer);

    constructor(
        IERC20 _token,
        address _signer,
        address _owner
    ) Ownable(_owner) {
        _setSigner(_signer);
        token = _token;
    }

    function claim(
        uint256 amount,
        uint256 maxAmount,
        bytes calldata signature,
        address receiver
    ) external {
        if (
            !SignatureChecker.isValidSignatureNow(
                signer,
                keccak256(abi.encodePacked(msg.sender, amount, maxAmount)),
                signature
            )
        ) {
            revert InvalidSignature();
        }

        if (receiver == address(0)) {
            receiver = msg.sender;
        }

        uint256 claimed = claimedAmounts[msg.sender];
        uint256 resultant = claimed + amount;
        if (resultant > maxAmount) {
            revert ExceedingMaxAmount();
        }

        claimedAmounts[msg.sender] = resultant;
        token.safeTransfer(receiver, amount);

        emit Claimed(msg.sender, amount);
    }

    function setSigner(address _signer) external onlyOwner {
        _setSigner(_signer);
    }

    function _setSigner(address _signer) private {
        if (_signer == address(0)) {
            revert ZeroAddress();
        }
        signer = _signer;
        emit SignerSet(_signer);
    }
}
