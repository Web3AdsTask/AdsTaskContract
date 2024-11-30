// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";

import {OAToken} from "../src/OAToken.sol";
import {OAXToken} from "../src/OAXToken.sol";
import {OMToken} from "../src/OMToken.sol";
import {StakingPool} from "../src/StakingPool.sol";
import {RevenuePool} from "../src/RevenuePool.sol";
import {PartnerIDO} from "../src/PartnerIDO.sol";
import {PlayerPlatform} from "../src/PlayerPlatform.sol";

contract DeployScript is Script {
    OAXToken public oax;
    OMToken public omt;
    OAToken public oat;
    StakingPool public stakingPool;
    RevenuePool public revenuePool;
    PartnerIDO public partnerIDO;
    PlayerPlatform public playerPlatform;

    function setUp() public {
        // console.log("Deploying... setUp");
    }

    function run() public {
        console.log("Deploying... run");

        vm.startBroadcast();

        oax = new OAXToken(); // 0xdc34ee57bd998A0Dca60937d109742e154F61C1D
        omt = new OMToken(); // 0x1F8eeC0b47cb25D6232133f8c88C971cCC70Cae7
        oat = new OAToken(); // 0x9c0cbF48DED26A7fDB5C1Bc67D160CA385aa2FB7
        stakingPool = new StakingPool(); // 0x8E2D3b13e01E149ae66BEcb40EDee3bd1D1Dad83
        revenuePool = new RevenuePool(); // 0x36Ff7c2F977a1C69Fc323dFDABf532C4725B8Ecd
        partnerIDO = new PartnerIDO(); // 0x6b1D32E399f1c014c20612E8c194bAacbfFe3f37
        playerPlatform = new PlayerPlatform(); // 0xf3eC7cd8243ed704A3f70195F2C39Ba5c9aedcF0

        vm.stopBroadcast();
    }
}
