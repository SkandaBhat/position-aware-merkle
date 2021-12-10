// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerklePosAwareShort {
    function verifyMultiple(
        bytes32[][] memory proofs,
        bytes32 root,
        bytes32[] memory leaves,
        uint32[] memory assetId,
        uint32 depth,
        uint32 maxAssets,
        mapping(bytes32 => bool) storage alreadyCovered
    ) internal returns (bool) {
        for (uint256 i = 0; i < proofs.length; i++) {
            if (!verify(proofs[i], root, leaves[i], assetId[i], depth, maxAssets, alreadyCovered)) return false;
        }
        return true;
    }

    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf,
        uint32 assetId,
        uint32 depth,
        uint32 maxAssets,
        mapping(bytes32 => bool) storage alreadyCovered
    ) internal returns (bool) {
        bytes32 computedHash = leaf;
        bytes memory seq = bytes(getSequence(assetId, depth));

        uint256 last_node = maxAssets;
        uint256 my_node = assetId;
        uint256 j = depth;
        uint256 i = 0;
        bytes memory covered;

        while (j > 0) {
            bytes32 proofElement = proof[i];
            j--;
            //skip proof check  if my node is  last node and number of nodes on level is odd
            if (last_node % 2 == 1 && last_node == my_node) {
                my_node = my_node / 2 + (my_node % 2);
                last_node = last_node / 2 + (last_node % 2);
                continue;
            }
            covered = slice(seq, 0, j + 1);
            if (seq[j] == 0x30) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
            i++;
            my_node = my_node / 2 + (my_node % 2);
            last_node = last_node / 2 + (last_node % 2);
            if (alreadyCovered[computedHash]) {
                return true;
            }
            alreadyCovered[computedHash] = true;
        }
        return computedHash == root;
    }

    function getSequence(uint256 assetId, uint256 depth) internal pure returns (bytes memory) {
        bytes memory output = new bytes(depth);
        uint256 n = assetId - 1;
        for (uint8 i = 0; i < depth; i++) {
            output[depth - 1 - i] = (n % 2 == 1) ? bytes1("1") : bytes1("0");
            n /= 2;
        }
        return output;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}
