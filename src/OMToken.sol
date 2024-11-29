// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OMToken is ERC20, Ownable {
    // custom errors
    error invalidAdmin();

    // custom events
    event AdminSet(address indexed admin, bool indexed isAdd);

    // 添加mint管理员
    mapping(address => bool) public admins;

    constructor() ERC20("OMToken", "OMT") Ownable(msg.sender) {}

    function setAdmin(address admin, bool isAdd) public onlyOwner {
        admins[admin] = isAdd;
        emit AdminSet(admin, isAdd);
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner(), invalidAdmin());
        _;
    }

    function mint(address to, uint256 amount) public onlyAdmin {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}
