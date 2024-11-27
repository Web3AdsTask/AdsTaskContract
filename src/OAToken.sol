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
