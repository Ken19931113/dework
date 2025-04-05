// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IENSResolver
 * @dev Interface for ENS name resolution
 */
interface IENSResolver {
    /**
     * @dev Returns the address associated with an ENS name
     * @param node The ENS node to query
     * @return address The associated address
     */
    function addr(bytes32 node) external view returns (address);
    
    /**
     * @dev Sets the address associated with an ENS name
     * @param node The ENS node to update
     * @param addr The address to set
     */
    function setAddr(bytes32 node, address addr) external;
    
    /**
     * @dev Returns the content hash associated with an ENS name
     * @param node The ENS node to query
     * @return bytes The associated content hash
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
    
    /**
     * @dev Sets the content hash associated with an ENS name
     * @param node The ENS node to update
     * @param hash The content hash to set
     */
    function setContenthash(bytes32 node, bytes calldata hash) external;
    
    /**
     * @dev Returns the text data associated with an ENS name and key
     * @param node The ENS node to query
     * @param key The text data key
     * @return string The associated text data
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
    
    /**
     * @dev Sets the text data associated with an ENS name
     * @param node The ENS node to update
     * @param key The text data key
     * @param value The text data value
     */
    function setText(bytes32 node, string calldata key, string calldata value) external;
}
