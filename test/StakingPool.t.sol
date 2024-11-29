// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {StakingPool} from "../src/StakingPool.sol";
import {OAToken} from "../src/OAToken.sol";
import {OAXToken} from "../src/OAXToken.sol";

contract StakingPoolTest is Test {
    StakingPool public stakingPool;
    OAToken public oatToken;
    OAXToken public oaxToken;

    address public alice;
    // 质押每日收益
    uint256 constant profitPerDay = 1 ether / 1_000;

    uint256 constant stakeAmount1 = 100 * 1e18;
    uint256 constant stakeAmount2 = 200 * 1e18;
    uint256 constant mockWarpTime = 10 days;

    function setUp() public {
        oatToken = new OAToken();
        oaxToken = new OAXToken();

        stakingPool = new StakingPool(address(oatToken), address(oaxToken), profitPerDay);

        alice = address(0xBEEF);

        // 给alice发oatToken
        deal(address(oatToken), alice, 100_000 ether);
        // 授权token给stakingPool
        vm.prank(alice);
        oatToken.approve(address(stakingPool), 100_000 ether);

        // 设置stakingPool为oaxToken管理员，可以铸币
        oaxToken.setAdmin(address(stakingPool), true);
    }

    function testStake() public {
        mockUserStake();

        // 验证质押额度
        (uint256 stakeNumber,,) = stakingPool.stakeInfos(alice);
        assertEq(stakeNumber, stakeAmount1 + stakeAmount2, "stake failed");
    }

    function testUnstake() public {
        mockUserStake();

        // 取出部份质押额度
        vm.prank(alice);
        stakingPool.unstake(stakeAmount2);

        // 验证质押额度
        (uint256 stakeNumber,,) = stakingPool.stakeInfos(alice);
        assertEq(stakeNumber, stakeAmount1, "unstake failed");
    }

    function testClaimTokens() public {
        mockUserStake();

        vm.prank(alice);
        stakingPool.claimTokens();

        // 验证质押额度
        (uint256 stakeNumber,,) = stakingPool.stakeInfos(alice);
        assertEq(stakeNumber, stakeAmount1 + stakeAmount2, "stake failed");

        // 验证alice钱包oaxToken余额
        uint256 aliceBalance = oaxToken.balanceOf(alice);
        console.log("--- aliceBalance ---");
        console.log(aliceBalance);
    }

    // TODO：验证质押收益
    function testCheckStakePools() public {
        mockUserStake();

        // 模拟时间
        vm.warp(block.timestamp + mockWarpTime);
        // 验证质押额度
        uint256 stakeAmount = stakingPool.checkStakePools(alice).stakeNumber;
        assertEq(stakeAmount, stakeAmount1 + stakeAmount2, "checkStakePools failed");
        // 验证收益
        console.log("--- checkStakePools ---");
        uint256 unClaimNumber = stakingPool.checkStakePools(alice).unClaimNumber;
        uint256 calculatedUnClaimNum = stakeAmount1 * mockWarpTime * profitPerDay / 1 days / 1 ether
            + (stakeAmount1 + stakeAmount2) * mockWarpTime * profitPerDay / 1 days / 1 ether;
        console.log("--- calculatedUnClaimNum ---");
        console.log(calculatedUnClaimNum);
        // 100 * 10 + 300 * 10
        assertEq(unClaimNumber, calculatedUnClaimNum, "checkStakePools failed");
    }

    function mockUserStake() public {
        vm.startPrank(alice);
        // 第一笔质押
        console.log("--- mockUserStake1 ---");
        stakingPool.stake(stakeAmount1);
        console.log("~~~~~ mockUserStake1 finish ~~~~~");
        // 模拟时间
        vm.warp(block.timestamp + mockWarpTime);
        // 第二笔质押
        console.log("--- mockUserStake2 ---");
        stakingPool.stake(stakeAmount2);
        console.log("~~~~~ mockUserStake2 finish ~~~~~");
        vm.stopPrank();
    }
}
