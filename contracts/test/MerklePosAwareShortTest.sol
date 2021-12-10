// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../MerklePosAwareShort.sol";

contract MerklePosAwareShortTest {
    mapping(bytes32 => bool) alreadyCovered;

    function verifyMultiple(
        bytes32[][] memory proofs,
        bytes32 root,
        bytes32[] memory leaves,
        uint32[] memory assetId,
        uint32 depth,
        uint32 maxAssets
    ) external returns (bool) {
        return MerklePosAwareShort.verifyMultiple(proofs, root, leaves, assetId, depth, maxAssets, alreadyCovered);
    }

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf,
        uint32 assetId,
        uint32 depth,
        uint32 maxAssets
    ) external returns (bool) {
        return MerklePosAwareShort.verify(proof, root, leaf, assetId, depth, maxAssets, alreadyCovered);
    }

    function getSequence(uint256 assetId, uint256 depth) external view returns (string memory) {
        return string(MerklePosAwareShort.getSequence(assetId, depth));
    }
}
