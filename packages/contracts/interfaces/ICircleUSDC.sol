// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ICircleUSDC
 * @dev Interface for Circle USDC with additional Circle-specific functions
 */
interface ICircleUSDC is IERC20 {
    /**
     * @dev Returns the current version of USDC
     * @return string The version
     */
    function version() external view returns (string memory);
    
    /**
     * @dev Returns the name of the token
     * @return string The name
     */
    function name() external view returns (string memory);
    
    /**
     * @dev Returns the symbol of the token
     * @return string The symbol
     */
    function symbol() external view returns (string memory);
    
    /**
     * @dev Returns the number of decimals used for user representation
     * @return uint8 The number of decimals
     */
    function decimals() external view returns (uint8);
    
    /**
     * @dev Mint new tokens
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;
    
    /**
     * @dev Burn tokens
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) external;
    
    /**
     * @dev Blacklist an address
     * @param account Address to blacklist
     */
    function blacklist(address account) external;
    
    /**
     * @dev Check if an address is blacklisted
     * @param account Address to check
     * @return bool True if blacklisted
     */
    function isBlacklisted(address account) external view returns (bool);
    
    /**
     * @dev Pause all token transfers
     */
    function pause() external;
    
    /**
     * @dev Unpause all token transfers
     */
    function unpause() external;
    
    /**
     * @dev Check if the token is paused
     * @return bool True if paused
     */
    function paused() external view returns (bool);
}
