// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IWorldID
 * @dev Interface for WorldID verification
 */
interface IWorldID {
    /**
     * @notice Verifies a WorldID zero-knowledge proof
     * @param root The root of the Merkle tree
     * @param groupId The group identifier for this proof
     * @param signal An arbitrary input from the user, usually the user's wallet address
     * @param nullifierHash The nullifier hash for this proof, preventing double signaling
     * @param externalNullifierHash A hash to identify the external nullifier used
     * @param proof The zero-knowledge proof
     */
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signal,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external view;
}
