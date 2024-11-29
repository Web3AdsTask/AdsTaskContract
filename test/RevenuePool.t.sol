// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/RevenuePool.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {OAToken} from "../src/OAToken.sol";
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
    // 营销token
    OMToken public marketingToken;
    // 分红token
    OAXToken public dividendToken;
    OAToken public stakingToken;
    // 质押每日收益
    uint256 constant profitPerDay = 1 ether / 1_000;

    uint256 constant DEAL_USER_AMOUNT = 1000 * 1e18;

    function setUp() public {
        // 创建合约管理员
        owner = address(0xCAFE);
        // 创建测试用户
        alice = address(0xBEEF);
        bob = address(0xDEAD);
        // 部署合约
        vm.startPrank(owner);
        revenuePool = new RevenuePool();
        revenueToken = new MockERC20();
        dividendToken = new OAXToken();
        stakingToken = new OAToken();
        marketingToken = new OMToken();

        // 管理员给revenuePool授权revenueToken
        revenueToken.approve(address(revenuePool), DEAL_USER_AMOUNT);

        // 给测试用户发放代币
        dividendToken.mint(alice, DEAL_USER_AMOUNT);
        marketingToken.mint(bob, DEAL_USER_AMOUNT);
        vm.stopPrank();

        // 给管理员分发收益token
        deal(address(revenueToken), owner, DEAL_USER_AMOUNT);

        // 给测试用户分发代币
        // deal(address(dividendToken), alice, DEAL_USER_AMOUNT);
        // deal(address(marketingToken), bob, DEAL_USER_AMOUNT);
    }

    function testInit() public view {
        uint256 totalSupply = marketingToken.totalSupply();
        assertEq(totalSupply, DEAL_USER_AMOUNT, "wrong totalSupply");
    }

    // 测试注入收益token
    function testSetInjectRevenueTokenAddress() public {
        vm.prank(owner);
        revenuePool.setInjectRevenueToken(address(revenueToken));

        // 查询收益token地址
        address injectToken = revenuePool.injectToken();
        assertEq(injectToken, address(revenueToken), " wrong injectToken");
    }

    // 测试设置分红token
    function testSetDividendTokenAddress() public {
        vm.prank(owner);
        revenuePool.setDividendToken(address(dividendToken), address(stakingToken), profitPerDay);
        // 查询分红token地址
        address dividendTokenAddress = revenuePool.dividendToken();
        assertEq(dividendTokenAddress, address(dividendToken), " wrong dividendToken");
    }

    // 测试设置营销token
    function testSetMarketingTokenAddress() public {
        vm.prank(owner);
        revenuePool.setMarketingToken(address(marketingToken));
        // 查询营销token地址
        address marketingTokenAddress = revenuePool.marketingToken();
        assertEq(marketingTokenAddress, address(marketingToken), " wrong marketingToken");
    }

    // 测试设置分红池比例
    function testSetPoolRatio() public {
        vm.prank(owner);
        revenuePool.setPoolRatio(50, 50);
        // 查询分红池比例
        uint256 poolRatio = revenuePool.dividendPoolRatio();
        assertEq(poolRatio, 50, " wrong poolRatio");

        // 查询营销池比例
        uint256 marketingPoolRatio = revenuePool.marketingPoolRatio();
        assertEq(marketingPoolRatio, 50, " wrong marketingPoolRatio");
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
        assertEq(balance, 500e18, " wrong dividendPool balance");
    }

    // 测试注入营销池
    function testInjectMarketingPool() public {
        vm.startPrank(owner);
        revenuePool.injectMarketingPool(500e18);
        vm.stopPrank();

        // 查询营销池余额
        uint256 balance = revenuePool.marketingPoolAmount();
        assertEq(balance, 500e18, "wrong marketingPool balance");
    }

    // 测试 预估 OAXToken 兑换分红价值
    function testEstDividendTokenToValue() public {
        mockSetDividendAndMarketingToken();
        revenuePool.openDividendTokenExchange();
        mockSetPoolRatioAndInjectRevenue(30, 70, 100e18);

        vm.warp(block.timestamp + 1 days);
        uint256 oaxValue = 30e18 / (stakingToken.totalSupply() / 1 ether * profitPerDay / 1 ether * 2);
        uint256 estValue = revenuePool.estDividendTokenToValue();
        console.log("--- estValue ---");
        console.log(oaxValue);
        console.log(estValue);
        assertEq(estValue, oaxValue, "wrong dividendToken value");
    }

    // 测试 预估 OMToken 兑换营销价值
    function testEstMarketingTokenAmountToValue() public {
        mockSetDividendAndMarketingToken();
        mockSetPoolRatioAndInjectRevenue(30, 70, 100e18);
        uint256 marketingTokenAmount = 100e18 * 70 / 100;
        uint256 omtValue = marketingTokenAmount / (DEAL_USER_AMOUNT / 1 ether);
        uint256 estValue = revenuePool.estMarketingTokenToValue();
        assertEq(estValue, omtValue, "wrong marketingToken value");
    }

    // 测试 OAXToken 兑换分红
    function testExchangeDividendTokenToValue() public {
        mockSetDividendAndMarketingToken();
        revenuePool.openDividendTokenExchange();
        mockSetPoolRatioAndInjectRevenue(30, 70, 100e18);
        console.log("--- mockSetPoolRatioAndInjectRevenue ---");
        console.log(revenuePool.dividendPoolAmount());

        vm.warp(block.timestamp + 1 days);
        uint256 dividendPoolBalance = 100e18 * 30 / 100;
        uint256 oaxValue = dividendPoolBalance / (stakingToken.totalSupply() / 1 ether * profitPerDay / 1 ether * 2);
        console.log("--- oaxValue ---");
        console.log(oaxValue);

        uint256 exchangeOAXAmount = 300 ether;
        uint256 oaxToValueAmount = oaxValue * exchangeOAXAmount / 1 ether;
        console.log("--- oaxToValueAmount ---");
        console.log(oaxToValueAmount);

        vm.prank(alice);
        revenuePool.exchangeDividendTokenToValue(exchangeOAXAmount);

        // 查询分红token余额
        uint256 balance = revenueToken.balanceOf(alice);
        console.log("--- balance ---");
        console.log(balance);
        assertEq(balance, oaxToValueAmount, "wrong dividendToken balance");

        // 查询alice钱包oaxToken余额
        uint256 aliceOatBalance = dividendToken.balanceOf(alice);
        console.log("--- aliceOatBalance ---");
        console.log(aliceOatBalance);
        assertEq(aliceOatBalance, DEAL_USER_AMOUNT - exchangeOAXAmount, "wrong aliceOatBalance");

        // 查询分红池余额
        uint256 dividendPoolBalance2 = revenuePool.dividendPoolAmount();
        console.log("--- dividendPoolBalance ---");
        console.log(dividendPoolBalance2);
        assertEq(dividendPoolBalance2, dividendPoolBalance - oaxToValueAmount, "wrong dividendPoolBalance");
    }

    // 测试 OMToken 兑换营销
    function testExchangeMarketingTokenToValue() public {
        mockSetDividendAndMarketingToken();
        revenuePool.openDividendTokenExchange();
        mockSetPoolRatioAndInjectRevenue(30, 70, 100e18);
        console.log("--- mockSetPoolRatioAndInjectRevenue ---");
        console.log(revenuePool.marketingPoolAmount());

        uint256 exchangeOMTAmount = 50e18;
        uint256 marketingTokenAmount = 100e18 * 70 / 100;
        uint256 omtValue = marketingTokenAmount / (DEAL_USER_AMOUNT / 1 ether);
        uint256 omtToValueAmount = omtValue * exchangeOMTAmount / 1 ether;
        console.log("--- omtToValueAmount ---");
        console.log(omtToValueAmount);

        vm.prank(bob);
        revenuePool.exchangeMarketingTokenToValue(exchangeOMTAmount);

        // 查询bob营销token余额
        uint256 balance = revenueToken.balanceOf(bob);
        console.log("--- balance ---");
        console.log(balance);
        assertEq(balance, omtToValueAmount, "wrong marketingToken balance");

        // 查询营销池余额
        uint256 marketingPoolBalance = revenuePool.marketingPoolAmount();
        console.log("--- marketingPoolBalance ---");
        console.log(marketingPoolBalance);
        assertEq(marketingPoolBalance, marketingTokenAmount - omtToValueAmount, "wrong marketingPoolBalance");
    }

    // 模拟设置收益池比例
    function mockSetPoolRatio(uint8 dividenRatio, uint8 marketingRatio) public {
        vm.prank(owner);
        revenuePool.setPoolRatio(dividenRatio, marketingRatio);
    }

    function mockSetPoolRatioAndInjectRevenue(uint8 dividenRatio, uint8 marketingRatio, uint256 amount) public {
        vm.startPrank(owner);
        revenuePool.setPoolRatio(dividenRatio, marketingRatio);
        revenuePool.injectingRevenue(amount);
        vm.stopPrank();
    }

    function mockSetDividendAndMarketingToken() public {
        vm.startPrank(owner);
        revenuePool.setInjectRevenueToken(address(revenueToken));
        revenuePool.setDividendToken(address(dividendToken), address(stakingToken), profitPerDay);
        revenuePool.setMarketingToken(address(marketingToken));
        vm.stopPrank();
    }

    function testCountOAXBaseSupply() public {
        mockSetDividendAndMarketingToken();
        revenuePool.openDividendTokenExchange();
        vm.warp(block.timestamp + 1 days);

        uint256 totalSupply = revenuePool.countOAXBaseSupply();
        console.log("--- totalSupply ---");
        console.log(totalSupply);
    }

    function testGetWaitingRedemptionOAXTotalSupply() public {
        mockSetDividendAndMarketingToken();
        revenuePool.openDividendTokenExchange();

        vm.warp(block.timestamp + 1 days);
        uint256 timeTotalSupply = stakingToken.totalSupply() / 1 ether * profitPerDay / 1 ether * 2;
        console.log("--- timeTotalSupply ---");
        console.log(timeTotalSupply);
        uint256 totalSupply = revenuePool.getWaitingRedemptionOAXTotalSupply();
        console.log(totalSupply);
        assertEq(totalSupply, timeTotalSupply, "wrong totalSupply");
    }
}
