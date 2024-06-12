// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

library PacketLibrary {
    struct DIPStacket {
        uint32 chainId;
        uint8 confirmations;
        address author;
        address[2] validators;
        bytes transport;
        uint64 storedAt;
        ATTPStacket[] payload;
    }

    struct ATTPStacket {
        bytes inputs;
        address to;
    }

    error ATTPError(uint32 processId, address to, bytes input);
    error NotRelayerWhitelist(uint32 processId, address to, bytes input);


    // Sending packet function
    function isReadyToRelay(DIPStacket memory stacket) internal view returns (bool) {
        // check if the stacket is ready to be executed
        return block.number >= stacket.storedAt + stacket.confirmations;
    }


    // Receiving packet function
    function execute(DIPStacket memory stacket) internal returns (bool) {
        // execute call to the smart contract
        for (uint32 i = 0; i < stacket.payload.length; i++) {
            // TODO: add whitelist
            if(false) {
                revert NotRelayerWhitelist(i, stacket.payload[i].to, stacket.payload[i].inputs);
            }
            (bool success, ) = stacket.payload[i].to.call(
                stacket.payload[i].inputs
            );
            if (!success) {
                revert ATTPError(
                    i,
                    stacket.payload[i].to,
                    stacket.payload[i].inputs
                );
            }
        }
        return true;
    }
}
