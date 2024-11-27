// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OAXToken} from "../src/OAXToken.sol";

contract StakingPool is Ownable {
    struct StakeInfoStruct {
        uint256 stakeNumber;
        uint256 stakeStartTime;
        uint256 unClaimNumber;
    }

    // custom errors
    error NotStake();
    error allowanceIsNotEnough();
    error balanceIsNotEnough();
    error stakeAmountIsNotEnough();
    error unClaimAmountIsNotEnough();

    // custom events
    event Stake(address indexed account, uint256 amount);
    event Unstake(address indexed account, uint256 amount);
    event ClaimTokens(address indexed account, uint256 amount);

    // variables
    IERC20 public stakeToken;
    OAXToken public profitToken;
    uint256 public profitRatePerday;
    mapping(address => StakeInfoStruct) public stakeInfos;

    constructor(
        address _stakeTokenAddress,
        address _profitTokenAddress,
        uint256 _profitRate
    ) Ownable(msg.sender) {
        stakeToken = IERC20(_stakeTokenAddress);
        profitToken = OAXToken(_profitTokenAddress);
        profitRatePerday = _profitRate;
    }

    modifier hadStaked() {
        StakeInfoStruct memory stakeInfo = stakeInfos[msg.sender];
        if (stakeInfo.stakeNumber == 0) revert NotStake();
        _;
    }

    // 质押
    function stake(uint256 amount) external {
        if (IERC20(stakeToken).allowance(msg.sender, address(this)) < amount)
            revert allowanceIsNotEnough();

        if (IERC20(stakeToken).balanceOf(msg.sender) < amount)
            revert balanceIsNotEnough();

        // user将质押的Token转入StakePool合约
        IERC20(stakeToken).transferFrom(msg.sender, address(this), amount);
        // 更新质押收益
        updatestakingIncome(msg.sender);

        stakeInfos[msg.sender].stakeNumber += amount;

        emit Stake(msg.sender, amount);
    }

    // 解除质押
    function unstake(uint256 amount) external hadStaked {
        if (stakeInfos[msg.sender].stakeNumber < amount)
            revert stakeAmountIsNotEnough();

        stakeInfos[msg.sender].stakeNumber -= amount;
        // 将StakePool的RNT转给user
        IERC20(stakeToken).transfer(msg.sender, amount);

        emit Unstake(msg.sender, amount);
    }

    // 领取质押收益
    function claimTokens() external {
        updatestakingIncome(msg.sender);
        uint256 unClaimNum = stakeInfos[msg.sender].unClaimNumber;
        if (unClaimNum == 0) revert unClaimAmountIsNotEnough();
        stakeInfos[msg.sender].unClaimNumber = 0;
        // 将收益代币profitToken分发给user
        profitToken.mint(msg.sender, unClaimNum);

        emit ClaimTokens(msg.sender, unClaimNum);
    }

    // 计算收益
    function updatestakingIncome(
        address account
    ) public returns (uint256 unClaimNum) {
        StakeInfoStruct memory stakeInfo = stakeInfos[account];
        if (stakeInfo.stakeStartTime > 0) {
            uint256 stakeTime = block.timestamp - stakeInfo.stakeStartTime;

            stakeInfo.unClaimNumber +=
                (stakeInfo.stakeNumber * stakeTime * profitRatePerday) /
                1 days;
            unClaimNum = stakeInfo.unClaimNumber;
        }
        stakeInfo.stakeStartTime = block.timestamp;

        stakeInfos[account] = stakeInfo;
    }

    // 查询质押信息
    function checkStakePools(
        address account
    ) external returns (StakeInfoStruct memory) {
        updatestakingIncome(account);
        StakeInfoStruct memory stakeInfo = stakeInfos[account];
        return stakeInfo;
    }
}
