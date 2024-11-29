// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {PlayerPlatform} from "../src/PlayerPlatform.sol";
import {OMToken} from "../src/OMToken.sol";

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
        console.log("-- owner builder: ");
        console.log(owner);
        omt = new OMToken();
        playerPlatform = new PlayerPlatform(address(omt));

        omt.setAdmin(address(playerPlatform), true);
        vm.stopPrank();

        alice = address(0xBEEF);
    }

    function testPermitClaimOMT() public {
        console.log("testClaimOMT");
        uint256 amount = 0.5 ether;
        uint256 deadline = block.timestamp + 5 hours;
        // 打包消息
        bytes32 msgHash =
            keccak256(abi.encodePacked("premitClaimOMT(address,uint256,uint256)", alice, amount, deadline));
        // 签名消息
        bytes32 ethSignHash = MessageHashUtils.toEthSignedMessageHash(msgHash);
        // 使用私钥签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPK, ethSignHash);

        playerPlatform.premitClaimOMT(alice, amount, deadline, v, r, s);

        // 校验用户OMToken额度
        assertEq(omt.balanceOf(alice), amount, "invalid alice omt amount");
    }
}
