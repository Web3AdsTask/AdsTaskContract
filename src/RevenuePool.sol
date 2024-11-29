// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OAXToken} from "../src/OAXToken.sol";
import {OMToken} from "../src/OMToken.sol";

contract RevenuePool is Ownable {
    // custom errors
    error InvalidRatio();
    error InvalidAmount();
    error InvalidTokenValue();
    error InvalidAddress();

    // custom events
    event PoolRatioSet(uint8 indexed dividendRatio, uint8 indexed marketingRatio);

    event DividendPoolInjected(uint256 indexed amount);
    event MarketingPoolInjected(uint256 indexed amount);
    event RevenueInjected(uint256 indexed amount);

    event InjectTokenAddressSet(address indexed token);

    event MarketingTokenAddressSet(address indexed token);
    event DividendTokenAddressSet(address indexed token, address indexed stakeToken, uint256 indexed stakeRate);

    event DividendTokenAmountToValue(address indexed user, uint256 indexed amount, uint256 indexed value);
    event MarketingTokenAmountToValue(address indexed user, uint256 indexed amount, uint256 indexed value);

    // variables
    uint8 public dividendPoolRatio;
    uint8 public marketingPoolRatio;

    uint256 public dividendPoolAmount;
    uint256 public marketingPoolAmount;

    address public injectToken;
    address public marketingToken;

    address public dividendToken;
    address public stakingToken;
    uint256 public stakingRate;

    // 兑换参数
    uint256 public exchangeDividendOpenTime;
    uint256 public hadExchangeDividendTokenAmount;

    constructor() Ownable(msg.sender) {}

    // 设置收益池注入token
    function setInjectRevenueToken(address token) public onlyOwner {
        if (token == address(0)) revert InvalidAddress();
        injectToken = token;
        emit InjectTokenAddressSet(token);
    }

    // 设置分红兑换token
    function setDividendToken(address token, address stakeToken, uint256 stakeRate) public onlyOwner {
        if (token == address(0)) revert InvalidAddress();
        dividendToken = token;
        stakingToken = stakeToken;
        stakingRate = stakeRate;
        emit DividendTokenAddressSet(token, stakeToken, stakeRate);
    }

    // 设置营销兑换token
    function setMarketingToken(address token) public onlyOwner {
        if (token == address(0)) revert InvalidAddress();
        marketingToken = token;
        emit MarketingTokenAddressSet(token);
    }

    // 设置分红池、营销池比例
    function setPoolRatio(uint8 dividenRatio, uint8 marketingRatio) public onlyOwner {
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

    // 预估OAXToken兑换分红的价格
    function estDividendTokenToValue() public view returns (uint256) {
        if (dividendPoolAmount == 0) return 0;
        // 获取当前OAXToken的总量
        uint256 oaxTokenTotalSupply = getWaitingRedemptionOAXTotalSupply();
        if (oaxTokenTotalSupply == 0) return 0;
        // 计算每个OAXToken的价值
        uint256 oaxTokenValue = dividendPoolAmount / oaxTokenTotalSupply;
        return oaxTokenValue;
    }

    // 预估OMToken兑换营销的价格
    function estMarketingTokenToValue() public view returns (uint256) {
        if (marketingPoolAmount == 0) return 0;
        // 获取当前OMToken的总量
        uint256 omTokenTotalSupply = IERC20(marketingToken).totalSupply();
        if (omTokenTotalSupply == 0) return 0;

        // 计算每个OMToken的价值
        uint256 omTokenValue = marketingPoolAmount / (omTokenTotalSupply / 1 ether);
        return omTokenValue;
    }

    // 使用OAXToken兑换分红池
    function exchangeDividendTokenToValue(uint256 amount) public {
        if (dividendPoolAmount == 0) revert InvalidAmount();

        // 查询OAXToken兑换分红的价格
        uint256 oaxTokenValue = estDividendTokenToValue();
        if (oaxTokenValue == 0) revert InvalidTokenValue();

        // 计算可以兑换的分红额度
        uint256 dividendAmount = amount / 1 ether * oaxTokenValue;

        // 销毁OAXToken
        hadExchangeDividendTokenAmount += amount;
        OAXToken(dividendToken).burn(msg.sender, amount);

        // 转移分红额度
        dividendPoolAmount -= dividendAmount;
        IERC20(injectToken).transferFrom(owner(), msg.sender, dividendAmount);

        emit DividendTokenAmountToValue(msg.sender, amount, dividendAmount);
    }

    // 使用OMToken兑换营销池
    function exchangeMarketingTokenToValue(uint256 amount) public {
        if (marketingPoolAmount == 0) revert InvalidAmount();
        if (amount > IERC20(marketingToken).balanceOf(msg.sender)) revert InvalidAmount();

        // 查询OMToken兑换营销的价格
        uint256 omTokenValue = estMarketingTokenToValue();
        if (omTokenValue == 0) revert InvalidTokenValue();

        // 计算可以兑换的营销额度
        uint256 marketingAmount = amount / 1 ether * omTokenValue;

        // 销毁OMToken
        OMToken(marketingToken).burn(msg.sender, amount);
        // 转移营销额度
        marketingPoolAmount -= marketingAmount;
        IERC20(injectToken).transferFrom(owner(), msg.sender, marketingAmount);

        emit MarketingTokenAmountToValue(msg.sender, amount, marketingAmount);
    }

    // OAX开启以来的总量: 时间 * OAT总量 * 每日生成的OAX比率
    function openDividendTokenExchange() public {
        if (exchangeDividendOpenTime == 0) {
            exchangeDividendOpenTime = block.timestamp;
        }
    }

    function countOAXBaseSupply() public view returns (uint256) {
        if (stakingToken == address(0)) revert InvalidAddress();
        if (exchangeDividendOpenTime == 0) return 0;
        // 虚拟的OAXToken总量: t+1
        uint256 oatTokenTotalSupply = IERC20(stakingToken).totalSupply();
        uint256 oaxTokenCountTime = block.timestamp + 1 days - exchangeDividendOpenTime;
        uint256 countOAXBase = oaxTokenCountTime / 1 days * oatTokenTotalSupply / 1 ether * stakingRate / 1 ether;
        return countOAXBase;
    }

    function getWaitingRedemptionOAXTotalSupply() public view returns (uint256) {
        // 虚拟待兑换的OAXToken总量
        uint256 countOAXBase = countOAXBaseSupply();
        if (countOAXBase == 0) return 0;
        return countOAXBase - hadExchangeDividendTokenAmount;
    }

    function getRealOAXTotalSupply() private view returns (uint256) {
        return IERC20(dividendToken).totalSupply();
    }
}
