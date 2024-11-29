// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OAToken is ERC20, Ownable {
    constructor() ERC20("OAToken", "OAT") Ownable(msg.sender) {
        // 设置代币总量为1亿，18位小数
        _mint(msg.sender, 100_000_000 * 10 ** 18);
    }
}

/**
 * 经济模型：
 *
 * OAX 分红：----------------------------
 * OAX虚拟额度：在项目方注入USD额度到收益池时，按【OAT总量】的 1/1000/1days 产生OAX计数
 * （可以转为记录用户兑换真实OAX的数量，当前虚拟总份额 = 当前时间的OAX总量 - 用户兑换的OAX数量）
 * OAX真实额度：用户质押OAT后产生OAX，按【OAT质押】的 1/1000/1days 产生OAX领取
 *
 * OAX每份收益(t+1days预估)：分红池USD总额度 / (t+1days)OAX虚拟总额度
 * OAX兑换销毁：用户兑换真实数量的OAX销毁，同时减去等额虚拟数量的OAX计数；
 * 分红池转出（授权帐户）对应价值USD给用户，同时减去等额USD计数
 *
 * OAX 分红池：----------------------------
 * 用户质押OAT后产生真实的OAX，可用于兑换收益（OAX数量 * 每份收益）。
 * 用户未兑换的收益归平台所有(平台也持有OAT)，平台提取多少份额的收益，销毁对应份额的OAX计数。
 *
 * 对于用户持有OAT但未质押的部份收益，暂时归平台所有，也可以做后续其他计划。
 * 如：OAT总量1亿，IDO发放2千万，平台手中8千万；
 * 用户质押1千万OAT产生的OAX用于兑换收益，用户未质押的1千万OAT这部份收益暂时归平台所有，或者作为DAO治理...
 *
 * OAX 收益波动：----------------------------
 * 假定平台注入USD收益周期为1days。用户少于<1days领取对收益的影响？用户长期(>1days)不领取OAX对收益的影响？
 *    示例：项目方10月1号注入USD，给出当天每份OAX可兑换的预估价格（USD总量/t+1days的OAX总量）
 *    项目方按<=1days注入收益：预估价格 = USD总量/t+1days 的OAX总量
 *    项目方超出周期注入收益：预估价格 = USD总量/t+1days+实际时间 的OAX总量
 *   （USD总量固定时间越长每份收益越低，用户倾向保留token等项目方下次注入收益再兑换）
 *
 *
 * OMT 兑换：----------------------------
 * OMT每份收益(t+1days预估)：营销池USD总额度 / (t+1days)OMT虚拟总额度
 *
 *
 * 项目阶段：----------------------------
 * 阶段一：项目方 注入资金到收益池
 * 产生的分红收益，都归项目方所有
 *
 * 阶段二：产生正向收益后，IDO募资
 * IDO募集价格根据正向收益估算
 * 募集资金是否投放部份到收益池？后续规划
 */
