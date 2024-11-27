// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OMToken} from "../src/OMToken.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract PlayerPlatform is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // custom errors
    error invalidAmount();
    error invalidAddress();
    error invalidSignData();

    // custom events
    event RecordOMT(address indexed player, uint256 amount);
    event ClaimOMT(address indexed player, uint256 amount);

    // variables
    OMToken public tokenAddress;

    mapping(address => uint256) public playerOMT;

    constructor(address _tokenAddress) Ownable(msg.sender) {
        tokenAddress = OMToken(_tokenAddress);
    }

    // 领取OMT：传入服务器返回的签名数据
    function claimOMT(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // TODO:校验签名，并给用户发币

        // 直接铸币到用户帐户
        tokenAddress.mint(msg.sender, amount);

        emit ClaimOMT(msg.sender, amount);
    }
}
