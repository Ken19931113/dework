// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDC
 * @dev 模擬USDC代幣，用於測試目的
 */
contract MockUSDC is ERC20, Ownable {
    uint8 private _decimals;
    
    /**
     * @dev 構造函數
     * @param name 代幣名稱
     * @param symbol 代幣符號
     * @param decimals_ 小數位數
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;
    }
    
    /**
     * @dev 獲取代幣小數位數
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev 鑄造代幣
     * @param to 接收者地址
     * @param amount 鑄造金額
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /**
     * @dev 銷毀代幣
     * @param from 銷毀代幣的地址
     * @param amount 銷毀金額
     */
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
