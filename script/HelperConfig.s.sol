// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    // VRF Mock values
    uint96 public constant MOCK_BASE_FEE = 0.25 ether ;
    uint96 public constant MOCK_GAS_PRICE = 1e9; 
    // LINK / ETH price
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
}

contract HelperConfig is CodeConstants, Script {

    /* Errors */
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address vrfCoordinator;    
    }

    NetworkConfig public activeNetworkConfig;
    mapping (uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaNetworkConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns(NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaNetworkConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 sec
            keyHash: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9,
            subscriptionId: 0,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (networkConfigs[LOCAL_CHAIN_ID].vrfCoordinator != address(0)) {
            return networkConfigs[LOCAL_CHAIN_ID];
        }
        
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE, MOCK_WEI_PER_UNIT_LINK);
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 sec
            keyHash: 0x2d6c6e7c9e9b4b1b4b1b4b1b4b1b4b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b, // doesn't matter
            subscriptionId: 0, // doesn't matter
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinator: address(vrfCoordinatorMock)
        });
    }


}