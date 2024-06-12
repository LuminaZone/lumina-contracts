pragma solidity >=0.8;

import {console} from "forge-std/console.sol";
import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";
import {MockToken} from "../../src/mock/MockToken.sol";
import {MockBase} from "../../src/mock/MockBase.sol";
import {MockQuote} from "../../src/mock/MockQuote.sol";
import {MockBTC} from "../../src/mock/MockBTC.sol";
import {ErrToken} from "../../src/mock/MockTokenOver18Decimals.sol";
import {Utils} from "../utils/Utils.sol";
import {WETH9} from "../../src/mock/WETH9.sol";
import {BaseSetup} from "./AugmentorBaseSetup.sol";

contract StakeTest is BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function testRevertWhenStakePairDoNotExist() public {
    }

    function testCheckAccountBeforeStaking() public {}
    
    function testStakeAndAugmentAssetAppear() public {

    }

    function testStakeAndAugmentAssetNotAppearOnOversupply() public {

    }

    function testStake() public {
        // stake 1000 token1
        // check point balance
        // check token1 balance
        // check total supply
        // check total staked
        // check total point supply
        // check total point staked
        // check total point burned
        // check total point minted
        // check total point claimed
        // check total point unclaimed
        // check total point locked
    }

    function testBlockHashChunksAndNumber() public {
         // Get the current block hash
        
        bytes32 hash = 0x7a4a6fc947f7707899f4e4f562819807f725af34261f272e85165c7859647fe6;


        // Ensure that the block hash is not zero
        require(hash != 0, "Block hash is zero");

        // Extract 4-byte chunks from bytes32 and convert to uint32
        uint32[5] memory chunks;
        assembly {
            mstore(chunks,         hash)
            mstore(add(chunks, 32), shr(32, hash))
            mstore(add(chunks, 64), shr(64, hash))
            mstore(add(chunks, 96), shr(96, hash))
            mstore(add(chunks, 128), shr(128, hash))
        }

        for(uint256 i=0; i<chunks.length; i++) {
            console.log("chunk", i, chunks[i] % 20);
        }

    }
}

contract DelegateTest is BaseSetup {

}

contract AuthorshipTest is BaseSetup {

}

contract PenaltyTest is BaseSetup {

}