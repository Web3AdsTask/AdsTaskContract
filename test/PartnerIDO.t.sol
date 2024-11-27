// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {PartnerIDO} from "../src/PartnerIDO.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";

contract PartnerIDOTest is Test {
    PartnerIDO public partnerIDO;
    MockERC20 public idoToken = new MockERC20();

    address public owner;
    address public alice;
    address public bob;

    uint256 public constant PRESALE_AMOUNT = 2_000 ether;

    function setUp() public {
        owner = address(0xCAFE);
        alice = address(0xBEEF);
        bob = address(0xDEAD);

        vm.prank(owner);
        partnerIDO = new PartnerIDO();

        // 给owner发token
        deal(address(idoToken), owner, 100_000_000 ether);
        // 授权合约
        vm.prank(owner);
        idoToken.approve(address(partnerIDO), PRESALE_AMOUNT);

        // 给用户发eth
        vm.deal(alice, 1.5 ether);
        vm.deal(bob, 0.1 ether);
    }

    function testPresale() public {
        // 直接往合约转账
        vm.prank(alice);
        (bool succ, ) = address(partnerIDO).call{value: 0.1 ether}("");
        assertTrue(succ);
        // 使用presale转账
        vm.prank(bob);
        partnerIDO.presale{value: 0.05 ether}();

        // 检查用户的余额
        uint256 aliceBalance = address(alice).balance;
        uint256 bobBalance = address(bob).balance;
        assertEq(aliceBalance, 0.9 ether, "invalid alice balance");
        assertEq(bobBalance, 0 ether, "invalid bob balance");

        // 检查合约的余额
        uint256 contractBalance = address(partnerIDO).balance;
        assertEq(contractBalance, 0.15 ether, "invalid contract balance");

        // 检查合约中用户的余额
        uint256 aliceContractBalance = partnerIDO.balances(alice);
        uint256 bobContractBalance = partnerIDO.balances(bob);
        assertEq(
            aliceContractBalance,
            0.1 ether,
            "invalid alice contract balance"
        );
        assertEq(
            bobContractBalance,
            0.05 ether,
            "invalid bob contract balance"
        );
    }

    function testSetPresaleToken() public {
        mockSetPresaleToken();

        assertEq(partnerIDO.preTokenAmount(), 20_000_000 ether);
        assertEq(partnerIDO.endTime(), block.timestamp + 10 days);
        assertEq(partnerIDO.minETHAmount(), 0.01 ether);
        assertEq(partnerIDO.maxETHAmount(), 0.1 ether);
        assertEq(partnerIDO.minETHTarget(), 100 ether);
        assertEq(partnerIDO.maxETHTarge(), 200 ether);
    }

    function testTriggerEnd() public {
        vm.prank(owner);
        partnerIDO.triggerEnd();

        assertTrue(partnerIDO.isEnd(), "isEnd");
    }

    function testClaim() public {
        mockSetPresaleToken();
        mockUserPreOrder(120);
        vm.prank(alice);
        partnerIDO.presale{value: 1 ether}();

        // 模拟时间到期
        vm.warp(block.timestamp + 11 days);

        vm.prank(alice);
        partnerIDO.claim();

        // 查询alice钱包ido代币的数量
        uint256 aliceBalance = idoToken.balanceOf(alice);
        console.log("--- claim ---");
        console.log(aliceBalance);
    }

    function testRefund() public {
        mockSetPresaleToken();
        mockUserPreOrder(20);

        vm.prank(alice);
        partnerIDO.presale{value: 0.8 ether}();

        // alice提现前的eth余额
        uint256 aliceBalanceBefore = address(alice).balance;
        console.log(aliceBalanceBefore);

        // 模拟时间到期
        vm.warp(block.timestamp + 11 days);

        // 用户退款
        vm.prank(alice);
        partnerIDO.refund();

        // 查询alice钱包eth余额
        uint256 aliceBalance = address(alice).balance;
        console.log("--- refund ---");
        console.log(aliceBalance);
        assertEq(aliceBalance, aliceBalanceBefore + 0.8 ether, "refund failed");

        // 查询合约eth余额
        uint256 contractBalance = address(partnerIDO).balance;
        console.log(contractBalance);
        assertEq(contractBalance, 20 ether, "refund failed");
    }

    function testWithdraw() public {
        mockSetPresaleToken();
        mockUserPreOrder(120);

        vm.prank(alice);
        partnerIDO.presale{value: 1 ether}();

        // owner提现前的eth余额
        uint256 ownerBalanceBefore = address(owner).balance;

        // 模拟时间到期
        vm.warp(block.timestamp + 11 days);

        vm.prank(owner);
        partnerIDO.withdraw();

        // 查询owner钱包eth代币的数量
        uint256 ownerBalance = address(owner).balance;
        console.log("--- withdraw ---");
        console.log(ownerBalance);
        assertEq(
            ownerBalance,
            ownerBalanceBefore + 121 ether,
            "withdraw failed"
        );

        // 查询合约eth代币的数量
        uint256 contractBalance = address(partnerIDO).balance;
        console.log(contractBalance);
        assertEq(contractBalance, 0, "withdraw failed");
    }

    function testRealTokenPrice() public {
        mockSetPresaleToken();
        uint256 orderValue = 30;
        mockUserPreOrder(orderValue);
        uint256 price = partnerIDO.realTokenPrice();
        console.log("--- realTokenPrice1 ---");
        console.log(price);

        uint256 orderValue2 = 80;
        mockUserPreOrder(orderValue2);
        uint256 price2 = partnerIDO.realTokenPrice();
        console.log("--- realTokenPrice2 ---");
        console.log(price2);

        uint256 orderValue3 = 80;
        mockUserPreOrder(orderValue3);
        uint256 price3 = partnerIDO.realTokenPrice();
        console.log("--- realTokenPrice3 ---");
        console.log(price3);
    }

    function mockSetPresaleToken() public {
        vm.prank(owner);
        partnerIDO.setPresaleToken(
            address(partnerIDO),
            PRESALE_AMOUNT,
            block.timestamp + 10 days,
            0.1 ether,
            2 ether,
            100 ether, // 最低单价=100/2000 = 0.05
            150 ether // 最高单价=150/2000 = 0.075
        );
    }

    function mockUserPreOrder(uint256 userNum) public {
        for (uint160 i = 0; i < userNum; i++) {
            address user = address(i + 1);
            vm.deal(user, 1 ether);
            vm.prank(user);
            partnerIDO.presale{value: 1 ether}();
        }

        // 查询募资余额
        uint256 contractBalance = address(partnerIDO).balance;
        console.log("--- contractBalance ---");
        console.log(contractBalance);
    }
}
