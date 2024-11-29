// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OMToken} from "../src/OMToken.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract PlayerPlatform is Ownable {
    using MessageHashUtils for bytes32;

    // custom errors
    error invalidAmount();
    error invalidAddress();
    error invalidSignData();
    error invalidDeadline();

    // custom events
    event RecordOMT(address indexed player, uint256 amount);
    event ClaimOMT(address indexed player, uint256 amount);

    // variables
    OMToken public omt;

    mapping(address => uint256) public playerOMT;

    constructor(address _tokenAddress) Ownable(msg.sender) {
        omt = OMToken(_tokenAddress);
    }

    // 领取OMT：传入服务器返回的签名数据
    function premitClaimOMT(address player, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        if (amount == 0) revert invalidAmount();
        if (block.timestamp > deadline) revert invalidDeadline();
        // 打包消息
        bytes32 msgHash =
            keccak256(abi.encodePacked("premitClaimOMT(address,uint256,uint256)", player, amount, deadline));
        // 签名消息
        bytes32 ethSignHash = MessageHashUtils.toEthSignedMessageHash(msgHash);
        // 校验签名
        address signer = ecrecover(ethSignHash, v, r, s);
        if (signer != owner()) {
            revert invalidSignData();
        }

        // 直接铸币到用户帐户
        omt.mint(player, amount);

        emit ClaimOMT(msg.sender, amount);
    }
}
