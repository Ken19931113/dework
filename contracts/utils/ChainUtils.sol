// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChainUtils
 * @dev 提供跨鏈和區塊鏈實用功能的工具合約
 */
library ChainUtils {
    // 定義支持的區塊鏈網絡ID
    uint256 public constant ETHEREUM_MAINNET = 1;
    uint256 public constant ETHEREUM_SEPOLIA = 11155111;
    uint256 public constant POLYGON_MAINNET = 137;
    uint256 public constant POLYGON_MUMBAI = 80001;
    uint256 public constant ARBITRUM_ONE = 42161;
    uint256 public constant OPTIMISM = 10;
    uint256 public constant BASE = 8453;
    
    /**
     * @dev 獲取當前鏈的ID
     * @return 當前區塊鏈網絡ID
     */
    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
    
    /**
     * @dev 檢查當前是否在測試網
     * @return bool 是否為測試網
     */
    function isTestnet() internal view returns (bool) {
        uint256 chainId = getChainId();
        return chainId == ETHEREUM_SEPOLIA || 
               chainId == POLYGON_MUMBAI;
    }
    
    /**
     * @dev 獲取當前鏈的名稱
     * @return 當前區塊鏈網絡名稱
     */
    function getChainName() internal view returns (string memory) {
        uint256 chainId = getChainId();
        
        if (chainId == ETHEREUM_MAINNET) return "Ethereum Mainnet";
        if (chainId == ETHEREUM_SEPOLIA) return "Ethereum Sepolia";
        if (chainId == POLYGON_MAINNET) return "Polygon Mainnet";
        if (chainId == POLYGON_MUMBAI) return "Polygon Mumbai";
        if (chainId == ARBITRUM_ONE) return "Arbitrum One";
        if (chainId == OPTIMISM) return "Optimism";
        if (chainId == BASE) return "Base";
        
        return "Unknown Chain";
    }
    
    /**
     * @dev 獲取鏈的本地貨幣名稱
     * @return 當前區塊鏈的本地貨幣名稱
     */
    function getNativeCurrencyName() internal view returns (string memory) {
        uint256 chainId = getChainId();
        
        if (chainId == ETHEREUM_MAINNET || chainId == ETHEREUM_SEPOLIA) 
            return "ETH";
        if (chainId == POLYGON_MAINNET || chainId == POLYGON_MUMBAI) 
            return "MATIC";
        if (chainId == ARBITRUM_ONE || chainId == OPTIMISM || chainId == BASE) 
            return "ETH";
        
        return "Unknown";
    }
    
    /**
     * @dev 獲取區塊確認時間估計（以秒為單位）
     * @return 區塊確認的大致時間
     */
    function getBlockConfirmationTime() internal view returns (uint256) {
        uint256 chainId = getChainId();
        
        if (chainId == ETHEREUM_MAINNET) 
            return 12; // ~12秒
        if (chainId == ETHEREUM_SEPOLIA) 
            return 12; // ~12秒
        if (chainId == POLYGON_MAINNET || chainId == POLYGON_MUMBAI) 
            return 2; // ~2秒
        if (chainId == ARBITRUM_ONE) 
            return 1; // ~1秒
        if (chainId == OPTIMISM)
            return 2; // ~2秒
        if (chainId == BASE)
            return 2; // ~2秒
            
        return 12; // 默認值
    }
}
