// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IERC4907
 * @dev Interface for the ERC4907 standard - NFT Rental Standard
 * See: https://eips.ethereum.org/EIPS/eip-4907
 */
interface IERC4907 is IERC721 {
    /**
     * @dev The user info struct containing user data
     * @param user The address of the user
     * @param expires The unix timestamp when the user's rights expire
     */
    struct UserInfo {
        address user;
        uint64 expires;
    }

    /**
     * @dev Event emitted when a user is set for an NFT
     * @param tokenId The NFT token ID
     * @param user The address of the user
     * @param expires The unix timestamp when the user's rights expire
     */
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /**
     * @dev Sets the user and expires for an NFT
     * @param tokenId The NFT token ID
     * @param user The address of the user
     * @param expires The unix timestamp when the user's rights expire
     */
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    /**
     * @dev Gets the user address for an NFT
     * @param tokenId The NFT token ID
     * @return The user address
     */
    function userOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Gets the user expires for an NFT
     * @param tokenId The NFT token ID
     * @return The user expires timestamp
     */
    function userExpires(uint256 tokenId) external view returns (uint256);
}
