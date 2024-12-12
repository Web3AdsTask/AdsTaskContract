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

    uint256 public privateK = 0x86cbd6a5f655a0089ef9bf49c89298f351ed5054df5674509b73b2ccc9eda9c3;

    PlayerPlatform public playerPlatform;
    OMToken public omt;

    function setUp() public {
        // (owner, ownerPK) = makeAddrAndKey("1337");
        ownerPK = privateK;
        owner = vm.addr(ownerPK);

        vm.startPrank(owner);
        console.log("-- owner builder: ");
        console.log(owner);
        omt = new OMToken();
        playerPlatform = new PlayerPlatform();
        playerPlatform.setPlayToken(address(omt));

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

    function testViemMockSignature() public {
        console.log("testViemMockSignature");
        uint256 amount = 50000000000000000000;
        uint256 deadline = 1735627134000; // 毫秒：2024-12-31 14:38:54
        address addr = address(0x6A1D110668424E0315Fe207fD22dA5420a1238d1);
        uint256 privateKey = ownerPK; //0x86cbd6a5f655a0089ef9bf49c89298f351ed5054df5674509b73b2ccc9eda9c3;
        // 打包消息
        bytes32 msgHash = keccak256(abi.encodePacked("premitClaimOMT(address,uint256,uint256)", addr, amount, deadline));
        console.log("--- msgHash ---");
        console.logBytes32(msgHash);
        // 签名消息
        bytes32 ethSignHash = MessageHashUtils.toEthSignedMessageHash(msgHash);
        console.log("--- ethSignHash ---");
        console.logBytes32(ethSignHash);
        // 使用私钥签名，获取 v r s
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethSignHash);
        console.log("--- v r s ---");
        console.log(v);
        console.logBytes32(r);
        console.logBytes32(s);
        require(v == 27 || v == 28, "Invalid v value");
        bytes memory signature = abi.encodePacked(r, s, v);
        console.log("--- signature ---");
        console.logBytes(signature);

        address signer = ecrecover(ethSignHash, v, r, s);
        console.log("--- signer ---");
        console.log(signer);
        playerPlatform.premitClaimOMT(addr, amount, deadline, v, r, s);

        // 校验用户OMToken额度
        assertEq(omt.balanceOf(addr), amount, "invalid alice omt amount");
    }
}

/**
 * -->> walletAddress:  0x6a1d110668424e0315fe207fd22da5420a1238d1
 * tasks.js:50 claimAmount 50000000000000000000
 * SignatureContext.js:27 updateSignatureAmount: 50000000000000000000
 * SignatureContext.js:29 setSignatureAmount: 50000000000000000000
 * tasks.js:57 expirationTime 1733149739688
 * tasks.js:72 签名钱包地址: 0x455f84CF76ae596F29A8c5b2eE5A48D9E15C0A7C
 * 签名私钥：0x86cbd6a5f655a0089ef9bf49c89298f351ed5054df5674509b73b2ccc9eda9c3
 */
