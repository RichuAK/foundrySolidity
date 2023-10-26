// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {DeployBox} from "../script/DeployBox.s.sol";
import {UpgradeBox} from "../script/UpgradeBox.s.sol";
import {BoxV2} from "../src/BoxV2.sol";
import {BoxV1} from "../src/BoxV1.sol";

contract DeployAndUpgradeTest is Test {
    DeployBox public deployer;
    UpgradeBox public upgrader;
    address public OWNER = makeAddr("owner");
    address public proxy;

    function setUp() public {
        deployer = new DeployBox();
        upgrader = new UpgradeBox();
        proxy = deployer.run();
    }

    function testUpgrades() public {
        BoxV2 box2 = new BoxV2();

        // work around because only owners can upgrage, but prank and broadcast can't work together
        // upgradeBox() has a broadcast() inside it, so can't call it directly under owner's prank
        vm.prank(BoxV1(proxy).owner());
        BoxV1(proxy).transferOwnership(msg.sender);

        upgrader.upgradeBox(proxy, address(box2));

        uint256 expectedValue = 2;
        assertEq(expectedValue, BoxV2(proxy).version());

        BoxV2(proxy).setValue(7);
        assertEq(7, BoxV2(proxy).getValue());
    }
}
