// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {console} from "forge-std/console.sol";

contract PartnerIDO is Ownable {
    // custom errors
    error invalidAmount();
    error invalidLimtAmount();
    error moreThanSingleMaxAmount();
    error presaleActiveOrInvalidAmount();
    error presaleEndOrInvalidAmount();
    error moreThanMaxETHTargetAmount();

    // custom events
    event PresaleSuccess(address indexed account, uint256 indexed amount);
    event PresaleTriggerEnd();
    event ClaimSuccess(address indexed account, uint256 indexed amount);
    event RefundSuccess(address indexed account, uint256 indexed amount);
    event WithdrawSuccess(address indexed account, uint256 indexed amount);

    // variables
    IERC20 public idoToken;

    // 募集进度
    bool public isEnd = false;
    uint256 public totalETH;
    mapping(address => uint256) public balances;

    // 预售配置
    uint256 public endTime;

    uint256 public preTokenAmount = 1_000_000 * 1e18; // 预售Token数量
    uint256 public minETHTarget = 100 ether; // 最低募集目标
    uint256 public maxETHTarge = 200 ether; // 最高募集目标
    uint256 public preTokenMinPrice = minETHTarget / preTokenAmount; // 预售价格

    uint256 public minETHAmount = 0.01 ether; // 最低买入
    uint256 public maxETHAmount = 0.1 ether; // 最高买入[单个用户最高买入]

    constructor() Ownable(msg.sender) {}

    receive() external payable {
        presale();
    }

    function presale() public payable singleAmountLimit(msg.value) {
        balances[msg.sender] += msg.value; // 有用户多次申购

        totalETH += msg.value;
        // 筹集到最高额度，募集结束
        if (totalETH >= 200 ether) {
            isEnd = true;

            emit PresaleSuccess(msg.sender, totalETH);
        }
    }

    function setPresaleToken(
        address _tokenAddress,
        uint256 _amount,
        uint256 _endTime,
        uint256 _minETHAmount,
        uint256 _maxETHAmount,
        uint256 _minETHTarget,
        uint256 _maxETHTarge
    ) external onlyOwner {
        idoToken = IERC20(_tokenAddress);
        preTokenAmount = _amount;
        endTime = _endTime;
        minETHAmount = _minETHAmount;
        maxETHAmount = _maxETHAmount;
        minETHTarget = _minETHTarget;
        maxETHTarge = _maxETHTarge;

        // 更新预售价格，处理精度
        preTokenMinPrice = minETHTarget / (preTokenAmount / 1 ether);

        console.log("--- setPresaleToken ---");
        console.log(preTokenMinPrice);
    }

    // 主动触发结束（项目方手动结束）
    function triggerEnd() external onlyOwner {
        isEnd = true;

        emit PresaleTriggerEnd();
    }

    // 预售成功情况下，给用户发币（用户主动来领币）
    function claim() external onlySuccess {
        uint256 ethAmount = balances[msg.sender];
        if (ethAmount == 0) revert invalidAmount();
        uint256 realPrice = realTokenPrice();
        console.log("--- claimTokenPrice ---");
        console.log(realPrice);
        console.log(ethAmount);
        uint256 idoTokenAmount = realClaimAmount(ethAmount);
        console.log(idoTokenAmount);
        balances[msg.sender] = 0;
        idoToken.transferFrom(owner(), msg.sender, idoTokenAmount);

        emit ClaimSuccess(msg.sender, idoTokenAmount);
    }

    // 预售失败情况下，给用户退款（用户自己来领取退款）
    function refund() external onlyFail {
        uint256 eths = balances[msg.sender];
        if (eths > 0) {
            balances[msg.sender] = 0;

            // 退款 成功
            (bool succ, ) = payable(msg.sender).call{value: eths}("");
            if (succ) {
                emit RefundSuccess(msg.sender, eths);
            }
        }
    }

    // 项目方提取eth
    function withdraw() external onlySuccess onlyOwner {
        // 此时totalETH 和 address(this).banlance 的值应该相等
        uint256 eths = address(this).balance;
        // 提取
        (bool succ, ) = payable(msg.sender).call{value: eths}("");
        if (succ) {
            emit WithdrawSuccess(msg.sender, eths);
        }
    }

    // 预售成功，token实际价格
    function realTokenPrice() public view returns (uint256) {
        if (totalETH == 0) revert invalidAmount();
        if (totalETH < minETHTarget) return preTokenMinPrice;
        // 实际单价 = 预售总eth / 预售总token，处理精度
        return totalETH / (preTokenAmount / 1 ether);
    }

    // 预售成功，计算认购eth数量，实际领token数量
    function realClaimAmount(uint256 eths) public view returns (uint256) {
        return eths / realTokenPrice();
    }

    modifier singleAmountLimit(uint256 amount) {
        if (amount < minETHAmount || amount > maxETHAmount)
            revert invalidLimtAmount();
        if (balances[msg.sender] + amount > maxETHTarge)
            revert moreThanSingleMaxAmount();
        _;
    }

    modifier onlySuccess() {
        // 结束 && 募集成功
        require(
            checkIsEnd() && totalETH >= 100 ether,
            presaleActiveOrInvalidAmount()
        );
        _;
    }

    modifier onlyFail() {
        // 结束 && 募集失败
        require(
            checkIsEnd() && totalETH < 100 ether,
            presaleActiveOrInvalidAmount()
        );
        _;
    }

    modifier onlyActive() {
        // 募集进行中
        require(
            !checkIsEnd() && totalETH < 200 ether,
            presaleEndOrInvalidAmount()
        );
        _;
    }

    function checkIsEnd() public returns (bool) {
        if (isEnd || block.timestamp > endTime) {
            isEnd = true;
            return true;
        }
        return false;
    }
}
