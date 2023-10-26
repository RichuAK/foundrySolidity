// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {BoxV2} from "../src/BoxV2.sol";
import {BoxV1} from "../src/BoxV1.sol";

contract UpgradeBox is Script {
    function run() external returns (address) {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);

        vm.startBroadcast();
        BoxV2 newBox = new BoxV2();
        address proxy = upgradeBox(mostRecentlyDeployed, address(newBox));
        vm.stopBroadcast();
        return proxy;
    }

    function upgradeBox(address proxyAddress, address newBox) public returns (address) {
        BoxV1 proxy = BoxV1(proxyAddress);
        vm.broadcast();
        proxy.upgradeToAndCall(newBox, "");
        return proxyAddress;
        // you're kinda returning the same address that you recieved as an argument.
        //TODO: See if you can refactor and simplify this
    }
}
