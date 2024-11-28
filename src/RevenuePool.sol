// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RevenuePool is Ownable {
    // custom errors
    error InvalidRatio();
    error InvalidAmount();
    error InvalidAddress();

    // custom events
    event PoolRatioSet(
        uint8 indexed dividendRatio,
        uint8 indexed marketingRatio
    );

    event DividendPoolInjected(uint256 indexed amount);
    event MarketingPoolInjected(uint256 indexed amount);
    event RevenueInjected(uint256 indexed amount);

    event InjectTokenAddressSet(address indexed token);
    event DividendTokenAddressSet(address indexed token);
    event MarketingTokenAddressSet(address indexed token);

    event DividendTokenAmountToValue(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed value
    );
    event MarketingTokenAmountToValue(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed value
    );

    // variables
    uint8 public dividendPoolRatio;
    uint8 public marketingPoolRatio;

    uint256 public dividendPoolAmount;
    uint256 public marketingPoolAmount;

    address public injectToken;
    address public dividendToken;
    address public marketingToken;

    constructor() Ownable(msg.sender) {}

    // 设置收益池注入token
    function setInjectRevenueToken(address token) public onlyOwner {
        if (token == address(0)) revert InvalidAddress();
        injectToken = token;
        emit InjectTokenAddressSet(token);
    }

    // 设置分红兑换token
    function setDividendToken(address token) public onlyOwner {
        if (token == address(0)) revert InvalidAddress();
        dividendToken = token;
        emit DividendTokenAddressSet(token);
    }

    // 设置营销兑换token
    function setMarketingToken(address token) public onlyOwner {
        if (token == address(0)) revert InvalidAddress();
        marketingToken = token;
        emit MarketingTokenAddressSet(token);
    }

    // 设置分红池、营销池比例
    function setPoolRatio(
        uint8 dividenRatio,
        uint8 marketingRatio
    ) public onlyOwner {
        if (dividenRatio > 100 || marketingRatio > 100) revert InvalidRatio();
        if (dividenRatio + marketingRatio != 100) revert InvalidRatio();
        dividendPoolRatio = dividenRatio;
        marketingPoolRatio = marketingRatio;
        emit PoolRatioSet(dividenRatio, marketingRatio);
    }

    // 查询分红池、营销池比例之和 == 100
    modifier onlyRatio() {
        require(dividendPoolRatio + marketingPoolRatio == 100, InvalidRatio());
        _;
    }

    // 注入收益
    function injectingRevenue(uint256 amount) public onlyOwner onlyRatio {
        injectDividendPool((amount * dividendPoolRatio) / 100);
        injectMarketingPool((amount * marketingPoolRatio) / 100);
        emit RevenueInjected(amount);
    }

    // 注入收益池
    function injectDividendPool(uint256 amount) public onlyOwner {
        if (amount == 0) revert InvalidAmount();
        dividendPoolAmount += amount;
        emit DividendPoolInjected(amount);
    }

    // 注入营销池
    function injectMarketingPool(uint256 amount) public onlyOwner {
        if (amount == 0) revert InvalidAmount();
        marketingPoolAmount += amount;
        emit MarketingPoolInjected(amount);
    }

    // 查询OAXToken兑换分红的价格
    function queryDividendTokenToValue() public view returns (uint256) {
        // 获取当前OAXToken的总量
        uint256 oaxTokenTotalSupply = IERC20(dividendToken).totalSupply();
        if (oaxTokenTotalSupply == 0) return 0;

        // 计算每个OAXToken的价值
        uint256 oaxTokenValue = dividendPoolAmount / oaxTokenTotalSupply;
        return oaxTokenValue;
    }

    // 查询OMToken兑换营销的价格
    function queryMarketingTokenToValue() public view returns (uint256) {
        // 获取当前OMToken的总量
        uint256 omTokenTotalSupply = IERC20(marketingToken).totalSupply();
        if (omTokenTotalSupply == 0) return 0;

        // 计算每个OMToken的价值
        uint256 omTokenValue = marketingPoolAmount / omTokenTotalSupply;
        return omTokenValue;
    }

    // 使用OAXToken兑换分红池
    function exchangeDividendTokenToValue(uint256 amount) public {
        if (dividendPoolAmount > 0) revert InvalidAmount();

        // 查询OAXToken兑换分红的价格
        uint256 oaxTokenValue = queryDividendTokenToValue();
        if (oaxTokenValue == 0) revert InvalidAmount();

        // 计算可以兑换的分红额度
        uint256 dividendAmount = amount * oaxTokenValue;
        dividendPoolAmount -= dividendAmount;

        // 销毁OAXToken
        IERC20(dividendToken).transfer(address(0), amount);
        // 转移分红额度
        IERC20(injectToken).transfer(msg.sender, dividendAmount);

        emit DividendTokenAmountToValue(msg.sender, amount, dividendAmount);
    }

    // 使用OMToken兑换营销池
    function exchangeMarketingTokenToValue(uint256 amount) public {
        if (amount > marketingPoolAmount) revert InvalidAmount();

        // 查询OMToken兑换营销的价格
        uint256 omTokenValue = queryMarketingTokenToValue();
        if (omTokenValue == 0) revert InvalidAmount();

        // 计算可以兑换的营销额度
        uint256 marketingAmount = amount * omTokenValue;
        marketingPoolAmount -= marketingAmount;

        // 销毁OMToken
        IERC20(marketingToken).transfer(address(0), amount);
        // 转移营销额度
        IERC20(injectToken).transfer(msg.sender, marketingAmount);

        emit MarketingTokenAmountToValue(msg.sender, amount, marketingAmount);
    }
}
