// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/RevenuePool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/OAXToken.sol";
import "../src/OMToken.sol";

contract RevenuePoolTest is Test {
    RevenuePool public revenuePool;

    // 合约管理员
    address public owner;
    // 测试用户
    address public user1;
    address public user2;

    // 注入的收益token
    address public revenueToken;
    // 分红token
    address public dividendToken;
    // 营销token
    address public marketingToken;

    function setUp() public {
        // 创建合约管理员
        owner = address(0xCAFE);
        // 部署合约
        vm.startPrank(owner);
        revenuePool = new RevenuePool();
        // dividendToken = new OAXToken();
        // marketingToken = new OMToken();
        vm.stopPrank();
        // 给管理员分发收益token
        // deal(ERC20(revenueToken), owner, 1000e18);

        // 创建测试用户
        user1 = address(0xBEEF);
        user2 = address(0xDEAD);

        // 给测试用户分发代币
        // deal(ERC20(revenueToken), users, 1000e18);
    }

    // 测试注入收益token
    // function testSetInjectRevenueTokenAddress() public {
    //     vm.prank(owner);
    //     revenuePool.setInjectRevenueTokenAddress(revenueToken);

    //     // 查询收益token地址
    //     address injectToken = revenuePool.injectToken();
    //     assert(injectToken == revenueToken);
    // }

    function testFailSetInjectRevenueTokenAddress() public {
        revenuePool.setInjectRevenueTokenAddress(revenueToken);
    }

    // 测试设置分红token
    function testSetDividendTokenAddress() public {
        vm.prank(owner);
        revenuePool.setDividendTokenAddress(dividendToken);
        // 查询分红token地址
        address dividendTokenAddress = revenuePool.dividendToken();
        assert(dividendTokenAddress == dividendToken);
    }

    // 测试设置营销token
    function testSetMarketingTokenAddress() public {
        vm.prank(owner);
        revenuePool.setMarketingTokenAddress(marketingToken);
        // 查询营销token地址
        address marketingTokenAddress = revenuePool.marketingToken();
        assert(marketingTokenAddress == marketingToken);
    }

    // 测试设置分红池比例
    function testSetDividenPoolRatio() public {
        vm.prank(owner);
        revenuePool.setDividendPoolRatio(50);
        // 查询分红池比例
        uint dividendPoolRatio = revenuePool.dividendPoolRatio();
        assert(dividendPoolRatio == 50);
    }

    // 测试设置营销池比例
    function testSetMarketingPoolRatio() public {
        vm.prank(owner);
        revenuePool.setMarketingPoolRatio(50);
        // 查询营销池比例
        uint marketingPoolRatio = revenuePool.marketingPoolRatio();
        assert(marketingPoolRatio == 50);
    }

    // 测试注入收益
    function testInjectingRevenue() public {}

    // 测试注入分红池
    function testInjectDividendPool() public {}

    // 测试注入营销池
    function testInjectMarketingPool() public {}

    // 测试 OAXToken 兑换分红价值
    function testDividendTokenAmountToValue() public {}

    // 测试 OMToken 兑换营销价值
    function testMarketingTokenAmountToValue() public {}

    // 测试 OAXToken 兑换分红
    function testUseDividendPool() public {}

    // 测试 OMToken 兑换营销
    function testUseMarketingPool() public {}
}
