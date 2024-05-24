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
    error ExpiredSignature();
    error ExceedingMaxAmount();
    error ZeroAddress();

    event Claimed(
        bytes32 indexed signatureHash,
        address indexed to,
        uint256 amount
    );
    event SignerUpdated(address indexed signer);

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
        uint256 expiredAt,
        bytes calldata signature,
        address receiver
    ) external {
        if (
            !SignatureChecker.isValidSignatureNow(
                signer,
                keccak256(
                    abi.encodePacked(
                        block.chainid,
                        msg.sender,
                        amount,
                        maxAmount,
                        expiredAt
                    )
                ),
                signature
            )
        ) {
            revert InvalidSignature();
        }

        if (block.timestamp >= expiredAt) {
            revert ExpiredSignature();
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

        emit Claimed(keccak256(signature), msg.sender, amount);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) {
            revert ZeroAddress();
        }
        token.safeTransfer(to, amount);
    }

    function setSigner(address _signer) external onlyOwner {
        _setSigner(_signer);
    }

    function _setSigner(address _signer) private {
        if (_signer == address(0)) {
            revert ZeroAddress();
        }
        signer = _signer;
        emit SignerUpdated(_signer);
    }
}
