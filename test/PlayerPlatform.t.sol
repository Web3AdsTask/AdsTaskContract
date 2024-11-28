// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {PlayerPlatform} from "../src/PlayerPlatform.sol";
import {OMToken} from "../src/OMToken.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract PlayerPlatformTest is Test {
    uint256 public ownerPK;
    address public owner;
    address public alice;

    PlayerPlatform public playerPlatform;
    OMToken public omt;

    function setUp() public {
        (owner, ownerPK) = makeAddrAndKey("1337");

        vm.startPrank(owner);
        omt = new OMToken();
        playerPlatform = new PlayerPlatform(address(omt));

        omt.setAdmin(address(playerPlatform), true);
        vm.stopPrank();

        alice = address(0xBEEF);
    }

    function testClaimOMT() public {
        console.log("testClaimOMT");
    }

    // 构造签名信息
    function makeSignData(uint256 amount) public returns (bytes memory) {
        // 打包消息
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "claimOMT(address,uint256,uint256)",
                alice,
                amount,
                block.timestamp + 5 minutes
            )
        );

        // 签名消息
        bytes32 ethSignHash = MessageHashUtils.toEthSignedMessageHash(msgHash);
        bytes memory signData = ECDSA.sign(ownerPK, ethSignHash);

        return signData;
    }
}
