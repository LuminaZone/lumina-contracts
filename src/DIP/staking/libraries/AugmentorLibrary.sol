// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {CloneFactory} from "./CloneFactory.sol";
import {Augment} from "../Augment.sol";
import {TransferHelper} from "../../libraries/TransferHelper.sol";
import {IWETH} from "../../../mock/interfaces/IWETH.sol";
import {IEngine} from "@standardweb3/src/exchange/interfaces/IEngine.sol";

interface IAugment {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function mint(address to, uint256 amount) external returns (bool);
}

library AugmentorLibrary {
    struct Origin {
        uint256 chainId;
        address source;
    }
    struct Relayer {
        /// relaying wallet
        address account;
        /// delegated amount of point
        uint256 delegated;
        /// is relayer online
        bool isOnline;
        /// commission rate percentage(%) with 3 decimals
        uint32 commission;
    }
    struct State {
        /// address of LUM
        address LUM;
        /// address of WETH
        address WETH;
        /// address of market engine
        address engine;
        /// address of augmented token impl
        address impl;
        /// balances of augmented token
        mapping(address => mapping(address => uint256)) balances;
        /// points balance of stakers after staking
        mapping(address => uint256) points;
        //// Relayer
        /// relayer ids
        mapping(address => uint32) rIds;
        /// relayers
        mapping(uint32 => Relayer) relayers;
        /// delegated total points
        uint256 total;
        /// relayer list in arbitrary order to shuffle for authorship
        mapping(uint32 => uint32) list;
        /// relayer is in list
        mapping(uint32 => bool) enlisted;
        /// minimum relayer delegation threshold to become a valid relayer
        uint256 minDelegated;
        /// list head
        uint32 lHead;
        /// list cout
        uint32 lCount;
        /// relayer count
        uint32 rCount;
        /// confisticated until
        mapping(uint32 => uint64) confiscated;
        /// originals
        mapping(address => Origin) origins;
    }

    // errors
    error PairDoesNotExist(address asset, address LUM);
    error InvalidAccess(address sender, address owner);
    error AugmentAlreadyExists(address original, address augment);
    error AmountExceedsBalance(uint256 amount, uint256 balance);
    error DoubleAugment(address augmented, uint256 chainId, address original);
    /// relayers
    error InvalidRelayer(address delegateTo);
    error AlreadyOccupied(address delegator, uint32 dId);
    error AmountExceedsPoint(uint256 amount, uint256 point);
    error NotRelayerAccount(address sender, address account);

    // functions

    function _augmentExists(
        State storage self,
        address original
    ) internal view returns (bool) {
        address augment = _predictAddress(self, block.chainid, original);

        // Check if the address has code
        uint32 size;
        assembly {
            size := extcodesize(augment)
        }

        // If the address has code and it's a clone of impl, revert.
        if (size > 0 || CloneFactory._isClone(self.impl, augment)) {
            return true;
        }
        return false;
    }

    function _createAugment(
        State storage self,
        address source
    ) internal returns (address augment) {
        if (_augmentExists(self, source)) {
            revert AugmentAlreadyExists(source, augment);
        }

        // Build constructor args
        string memory symbol = IAugment(source).symbol();
        string memory name = IAugment(source).name();
        symbol = string(abi.encodePacked("Lum", symbol));
        name = string(abi.encodePacked("Lumina ", name));

        bytes memory args = abi.encode(name, symbol, address(this));

        address proxy = CloneFactory._createCloneWithSaltOnConstructor(
            self.impl,
            _getSalt(block.chainid, source),
            args
        );

        self.origins[proxy] = Origin(block.chainid, source); 

        return (proxy);
    }

    // Set immutable, consistant, one rule for orderbook implementation
    function _createImpl(State storage self) internal {
        address addr;
        bytes memory bytecode = type(Augment).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("augment", "0"));
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        self.impl = addr;
    }

    function _predictAddress(
        State storage self,
        uint256 chainId,
        address source
    ) internal view returns (address) {
        bytes32 salt = _getSalt(chainId, source);
        return
            CloneFactory.predictAddressWithSalt(address(this), self.impl, salt);
    }

    function _getSalt(uint256 chainId, address source) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(chainId, source));
    }

    function stake(
        State storage self,
        address asset,
        uint256 amount,
        address recipient
    ) internal {
        // check if one is staking an augmented asset(double-augmenting)
        Origin memory orgn = self.origins[asset];
        if(orgn.source != address(0)) {
            revert DoubleAugment(asset, orgn.chainId, orgn.source);
        }
        // check if the asset pair between ETH exists in exchange
        uint256 price = asset == self.LUM
            ? 1
            : IEngine(self.engine).mktPrice(asset, self.LUM);

        // if not, revert with error
        if (price == 0) {
            revert PairDoesNotExist(asset, self.LUM);
        }

        // stake
        TransferHelper.safeTransferFrom(
            asset,
            msg.sender,
            address(this),
            amount
        );

        // if LUM is staked, do not return augmented token
        if (asset == self.LUM) {
            // set balance to return to user and add points
            self.balances[recipient][asset] += amount;
            self.points[recipient] += (price * amount) / 1e8;
            return;
        }

        // if augment asset does not exist, create one
        if (!_augmentExists(self, asset)) {
            address augment = _createAugment(self, asset);
            // mint asset to recipient
            self.balances[recipient][asset] += amount;
            self.points[recipient] += (price * amount) / 1e8;
            IAugment(augment).mint(recipient, amount);
        } else {
            address augment = _predictAddress(self, block.chainid, asset);
            // mint asset to recipient
            self.balances[recipient][asset] += amount;
            self.points[recipient] += (price * amount) / 1e8;
            IAugment(augment).mint(recipient, amount);
        }
    }

    function unstake(
        State storage self,
        address asset,
        uint256 amount
    ) internal {
        // check if the asset pair between ETH exists in exchange
        uint256 price = IEngine(self.engine).mktPrice(asset, self.LUM);

        // check if the amount exceeds balance
        if (amount > self.balances[msg.sender][asset]) {
            // if not, revert with error
            revert AmountExceedsBalance(
                amount,
                self.balances[msg.sender][asset]
            );
        }
        // unstake
        self.balances[msg.sender][asset] -= amount;
        if (self.points[msg.sender] < (price * amount) / 1e8) {
            self.points[msg.sender] = 0;
        } else {
            self.points[msg.sender] -= (price * amount) / 1e8;
        }
        if (asset == self.WETH) {
            IWETH(self.WETH).withdraw(amount);
            payable(msg.sender).transfer(amount);
        } else {
            TransferHelper.safeTransfer(asset, msg.sender, amount);
        }
    }

    // delegator functions
    function register(State storage self) internal {
        // check occupation
        if (self.rIds[msg.sender] != 0) {
            revert AlreadyOccupied(msg.sender, self.rIds[msg.sender]);
        }

        // Transfer required LUMs to register as validator
        // TODO: set point decimals
        TransferHelper.safeTransferFrom(
            self.LUM,
            msg.sender,
            address(this),
            32e18
        );

        // Add delegator in the list
        self.rCount += 1;
        self.rIds[msg.sender] = self.rCount;
        self.list[self.rCount] = self.lHead;
        self.relayers[self.rCount].delegated += 32e18;
        self.relayers[self.rCount].isOnline = true;
        self.lHead = self.rCount;
        _enlist(self, self.rCount);
    }

    function _enlist(State storage self, uint32 id) internal {
        if (self.lCount < 20) {
            self.minDelegated = self.relayers[id].delegated >= self.minDelegated
                ? self.minDelegated
                : self.relayers[id].delegated;
            self.list[id] = self.lHead;
            self.lHead = id;
            self.lCount += 1;
            self.enlisted[id] = true;
            return;
        } else {
            // TODO: 
            // if delegated amount is below minDelegated, stay out of the list
            if (self.relayers[id].delegated <= self.minDelegated) {
                // if the id is already included, take it out.
                if (self.enlisted[id]) {
                    uint32 head = self.lHead;
                    uint32 last = 0;
                    if (head == id) {
                        self.lHead = self.list[head];
                        self.list[head] = 0;
                        self.enlisted[head] = false;
                        return;
                    }
                    while (head != 0) {
                        if (head == id) {
                            self.list[last] = self.list[head];
                            self.list[head] = 0;
                            self.enlisted[head] = false;
                            return;
                        } else {
                            last = head;
                            head = self.list[head];
                        }
                    }
                } else {
                    // relayer delegated is smaller than minDelegated when not enlisted. do nothing.
                    return;
                }
            } else {
                // find mindelegated id and remove
                uint32 head = self.lHead;
                uint32 last = 0;
                if (self.relayers[head].delegated == self.minDelegated) {
                    self.lHead = self.list[head];
                    self.list[head] = 0;
                    self.enlisted[head] = false;
                    return;
                }
                while (head != 0) {
                    if (self.relayers[head].delegated == self.minDelegated) {
                        self.list[last] = self.list[head];
                        self.list[head] = 0;
                        self.enlisted[head] = false;
                        return;
                    } else {
                        last = head;
                        head = self.list[head];
                    }
                }
                if (self.enlisted[id] || self.relayers[id].isOnline == false) {
                    return;
                } else {
                    // add relayer id in head
                    self.list[id] = self.lHead;
                    self.lHead = id;
                    self.enlisted[id] = true;
                }
            }
        }
    }

    function delegate(
        State storage self,
        address delegateTo,
        uint256 amount
    ) internal returns (uint32 id) {
        // check if delegator exists
        id = self.rIds[delegateTo];
        if (id == 0) {
            revert InvalidRelayer(delegateTo);
        }
        // check if amount exceeds point balance
        if (amount > self.points[msg.sender]) {
            revert AmountExceedsPoint(amount, self.points[msg.sender]);
        }
        self.points[msg.sender] -= amount;
        self.relayers[id].delegated += amount;
        self.total += amount;
        _enlist(self, id);
        return id;
    }

    function undelegate(
        State storage self,
        address delegateTo,
        uint256 amount
    ) external returns (uint32 id) {
        // check if delegator exists
        id = self.rIds[delegateTo];
        if (id == 0) {
            revert InvalidRelayer(delegateTo);
        }
        self.points[msg.sender] += amount;
        self.relayers[id].delegated -= amount;
        self.total -= amount;
        _enlist(self, id);
        return id;
    }

    function authorize(
        State storage self
    ) internal returns (address author, address[] memory validators) {
        // Get the current block hash
        bytes32 hash = blockhash(block.number - 1);

        // Ensure that the block hash is not zero
        require(hash != 0, "Block hash is zero");

        // Extract 4-byte chunks from bytes32 and convert to uint32
        uint32[3] memory chunks;
        assembly {
            mstore(chunks, hash)
            mstore(add(chunks, 32), shr(32, hash))
            mstore(add(chunks, 64), shr(64, hash))
            //mstore(add(chunks, 96), shr(96, hash))
            //mstore(add(chunks, 128), shr(128, hash))
        }

        // get author
        author = self.relayers[chunks[0] % self.lCount].account;
        // initialize the validators array with a length of 2
        uint32[] memory dIdQ = new uint32[](2);
        validators = new address[](2);

        // push validators into the array
        for (uint32 i = 0; i < 2; i++) {
            uint32 id = self.lHead;
            uint32 last = 0;
            // reuse chunks[0] for storing index
            chunks[0] = chunks[i + 1] % self.lCount;

            // traverse to the given index then get delegator id
            for (uint32 j = 0; j < chunks[0] - 1; j++) {
                last = id;
                id = self.list[id];
            }
            // take out picked id from list
            self.list[last] = self.list[id];
            self.list[id] = 0;
            dIdQ[i] = id;
            validators[i] = self.relayers[id].account;
        }

        // shuffle picked indices by pushing front to the list
        for (uint32 i = 0; i < dIdQ.length; i++) {
            self.list[dIdQ[i]] = self.lHead;
            self.lHead = dIdQ[i];
        }

        return (author, validators);
    }

    function slash(State storage self, address delegator) internal {
        // slash points on delegator
        self.relayers[self.rIds[delegator]].delegated = 0;

        // distribute slashed LUM to reporter for 1/8

        // confiscate delegator for 3 months
    }

    function setOnline(State storage self, uint32 rId, bool online) internal {
        if (self.relayers[rId].account != msg.sender) {
            revert NotRelayerAccount(msg.sender, self.relayers[rId].account);
        }
        if (online) {
            // enlist relayer
            _enlist(self, rId);
        } else {
            // find rId and remove
            uint32 head = self.lHead;
            uint32 last = 0;
            if (self.relayers[head].account == msg.sender) {
                self.lHead = self.list[head];
                self.list[head] = 0;
                self.enlisted[head] = false;
                return;
            }
            while (head != 0) {
                if (self.relayers[head].account == msg.sender) {
                    self.list[last] = self.list[head];
                    self.list[head] = 0;
                    self.enlisted[head] = false;
                    return;
                } else {
                    last = head;
                    head = self.list[head];
                }
            }
        }
    }

    function augmentOf(
        State storage self,
        uint256 chainId,
        address original
    ) internal view returns (address augment) {
        return _predictAddress(self, chainId, original);
    }

    function originalOf(
        State storage self,
        address augmented
    ) internal view returns (Origin memory original) {
        return self.origins[augmented];
    }
}
