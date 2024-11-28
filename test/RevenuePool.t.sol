// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/RevenuePool.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {OAXToken} from "../src/OAXToken.sol";
import {OMToken} from "../src/OMToken.sol";

contract RevenuePoolTest is Test {
    RevenuePool public revenuePool;

    // 合约管理员
    address public owner;
    // 测试用户
    address public alice;
    address public bob;

    // 注入的收益token
    MockERC20 public revenueToken;
    // 分红token
    OAXToken public dividendToken;
    // 营销token
    OMToken public marketingToken;

    function setUp() public {
        // 创建合约管理员
        owner = address(0xCAFE);
        // 部署合约
        vm.startPrank(owner);
        revenuePool = new RevenuePool();
        revenueToken = new MockERC20();
        dividendToken = new OAXToken();
        marketingToken = new OMToken();

        vm.stopPrank();
        // 给管理员分发收益token
        deal(address(revenueToken), owner, 1000e18);

        // 创建测试用户
        alice = address(0xBEEF);
        bob = address(0xDEAD);

        // 给测试用户分发代币
        deal(address(dividendToken), alice, 1000e18);
        deal(address(marketingToken), bob, 1000e18);
    }

    // 测试注入收益token
    function testSetInjectRevenueTokenAddress() public {
        vm.prank(owner);
        revenuePool.setInjectRevenueToken(address(revenueToken));

        // 查询收益token地址
        address injectToken = revenuePool.injectToken();
        assert(injectToken == address(revenueToken));
    }

    // 测试设置分红token
    function testSetDividendTokenAddress() public {
        vm.prank(owner);
        revenuePool.setDividendToken(address(dividendToken));
        // 查询分红token地址
        address dividendTokenAddress = revenuePool.dividendToken();
        assert(dividendTokenAddress == address(dividendToken));
    }

    // 测试设置营销token
    function testSetMarketingTokenAddress() public {
        vm.prank(owner);
        revenuePool.setMarketingToken(address(marketingToken));
        // 查询营销token地址
        address marketingTokenAddress = revenuePool.marketingToken();
        assert(marketingTokenAddress == address(marketingToken));
    }

    // 测试设置分红池比例
    function testSetPoolRatio() public {
        vm.prank(owner);
        revenuePool.setPoolRatio(50, 50);
        // 查询分红池比例
        uint poolRatio = revenuePool.dividendPoolRatio();
        assert(poolRatio == 50);

        // 查询营销池比例
        uint marketingPoolRatio = revenuePool.marketingPoolRatio();
        assert(marketingPoolRatio == 50);
    }

    // 测试注入收益
    function testInjectingRevenue() public {
        mockSetPoolRatio(50, 50);

        // 校验事件
        vm.expectEmit(true, false, false, false);
        emit RevenuePool.RevenueInjected(1000e18);
        vm.startPrank(owner);
        revenuePool.injectingRevenue(1000e18);
        vm.stopPrank();
    }

    // 测试注入分红池
    function testInjectDividendPool() public {
        vm.startPrank(owner);
        revenuePool.injectDividendPool(500e18);
        vm.stopPrank();

        // 查询分红池余额
        uint256 balance = revenuePool.dividendPoolAmount();
        assert(balance == 500e18);
    }

    // 测试注入营销池
    function testInjectMarketingPool() public {
        vm.startPrank(owner);
        revenuePool.injectMarketingPool(500e18);
        vm.stopPrank();

        // 查询营销池余额
        uint256 balance = revenuePool.marketingPoolAmount();
        assert(balance == 500e18);
    }

    // 测试 查询 OAXToken 兑换分红价值
    function testQueryDividendTokenAmountToValue() public {
        mockSetPoolRatioAndInjectRevenue(30, 70, 100e18);

        uint256 value = revenuePool.queryDividendTokenToValue();
        assert(value == 30e18);
    }

    // 测试 查询 OMToken 兑换营销价值
    function testQueryMarketingTokenAmountToValue() public {
        mockSetPoolRatioAndInjectRevenue(30, 70, 100e18);

        uint256 value = revenuePool.queryMarketingTokenToValue();
        assert(value == 70e18);
    }

    // 测试 OAXToken 兑换分红
    function testExechangeDividendTokenToValue() public {
        mockSetPoolRatioAndInjectRevenue(40, 60, 100e18);

        vm.prank(alice);
        revenuePool.exchangeDividendTokenToValue(500e18);
    }

    // 测试 OMToken 兑换营销
    function testExchangeMarketingTokenToValue() public {
        mockSetPoolRatioAndInjectRevenue(40, 60, 100e18);

        vm.prank(bob);
        revenuePool.exchangeMarketingTokenToValue(500e18);
    }

    // 模拟设置收益池比例
    function mockSetPoolRatio(uint8 dividenRatio, uint8 marketingRatio) public {
        vm.prank(owner);
        revenuePool.setPoolRatio(dividenRatio, marketingRatio);
    }

    function mockSetPoolRatioAndInjectRevenue(
        uint8 dividenRatio,
        uint8 marketingRatio,
        uint256 amount
    ) public {
        vm.startPrank(owner);
        revenuePool.setPoolRatio(dividenRatio, marketingRatio);
        revenuePool.injectingRevenue(amount);
        vm.stopPrank();
    }
}
