// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IWETH} from "../../mock/interfaces/IWETH.sol";
import {AugmentorLibrary} from "./libraries/AugmentorLibrary.sol";

interface IAugment {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function mint(address to, uint256 amount) external returns (bool);
}

contract Augmentor is ReentrancyGuard {
    using AugmentorLibrary for AugmentorLibrary.State;

    AugmentorLibrary.State private _augmentor;

    // events
    event StakeCrypto(
        address indexed asset,
        address indexed account,
        uint256 amount,
        address sendTo
    );
    event UnstakeCrypto(
        address indexed asset,
        address indexed account,
        uint256 amount
    );

    // delegator events
    event DelegatePoint(uint32 did, address delegator, uint256 amount);
    event UnDelegatePoint(uint32 did, address delegator, uint256 amount);
    
    // errors
    error NotStakedToken(address lst, address source);

    // Augmentor functions
    function stake(
        address asset,
        uint256 amount,
        address recipient
    ) external nonReentrant returns (bool) {
        // stake asset
        _augmentor.stake(asset, amount, recipient);
        emit StakeCrypto(asset, msg.sender, amount, recipient);
        return true;
    }

    function stakeETH(
        address recipient
    ) external payable nonReentrant returns (bool) {
        // wrap ETH
        IWETH(_augmentor.WETH).deposit{value: msg.value}();
        // stake asset
        _augmentor.stake(_augmentor.WETH, msg.value, recipient);
        emit StakeCrypto(_augmentor.WETH, msg.sender, msg.value, recipient);
        return true;
    }

    function unstake(
        address asset,
        uint256 amount
    ) external nonReentrant returns (bool) {
        _augmentor.unstake(asset, amount);
        emit UnstakeCrypto(asset, msg.sender, amount);
        return true;
    }

    function stakedOf(
        address asset,
        address account
    ) external view returns (uint256 point) {
        return _augmentor.balances[account][asset];
    }

    function transfer(
        address asset,
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        // check msg.sender is staked tokens
        address source = _augmentor.origins[asset].source;
        if(source == address(0)) {
            revert NotStakedToken(asset, source);
        }
        _augmentor.balances[from][asset] -= amount;
        _augmentor.balances[to][asset] += amount;
    }

    /// Delegator functions
    function register() external returns (bool) {
        _augmentor.register();
        return true;
    }

    function delegate(
        address delegateTo,
        uint256 amount
    ) external returns (bool) {
        uint32 id = _augmentor.delegate(delegateTo, amount);
        emit DelegatePoint(id, delegateTo, amount);
        return true;
    }

    function undelegate(
        address delegateTo,
        uint256 amount
    ) external returns (bool) {
        uint32 id = _augmentor.undelegate(delegateTo, amount);
        emit UnDelegatePoint(id, delegateTo, amount);
        return true;
    }

    // Stacket Author functions
    function authorize() external {
        _augmentor.authorize();
    }

    // Online functions
    function setOnline(uint32 rId, bool online) external {
        _augmentor.setOnline(rId, online);
    }

    // Penalty functions



    // view functions
    function augmentOf(uint256 chainId, address original) external view returns (address augment) {
        return _augmentor.augmentOf(chainId, original);
    }

    function rIdOf(address account) external view returns (uint32 rId) {
        
    }
}
