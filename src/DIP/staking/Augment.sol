// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ERC20MintablePausableBurnable} from "../../mock/ERC20MintablePausableBurnable.sol";

interface IAugment {
    function symbol() external view returns (string memory);
}

contract Augment is ERC20MintablePausableBurnable {
    constructor(string memory name, string memory symbol, address augmentor) ERC20MintablePausableBurnable(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, augmentor);
        _grantRole(MINTER_ROLE, augmentor);
        _grantRole(PAUSER_ROLE, augmentor);
    }
}