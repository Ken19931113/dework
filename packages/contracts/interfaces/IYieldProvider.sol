// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IYieldProvider
 * @dev 收益提供者接口，用於與各種DeFi協議整合
 */
interface IYieldProvider {
    /**
     * @dev 將資金存入收益生成協議
     * @param _amount 存款金額
     */
    function deposit(uint256 _amount) external;
    
    /**
     * @dev 從收益生成協議提取資金
     * @param _amount 要提取的金額
     * @return 實際提取金額
     */
    function withdraw(uint256 _amount) external returns (uint256);
    
    /**
     * @dev 提取所有資金
     * @return 提取的總金額
     */
    function withdrawAll() external returns (uint256);
    
    /**
     * @dev 獲取當前存款的總價值（包含收益）
     * @return 總價值
     */
    function getTotalValue() external view returns (uint256);
    
    /**
     * @dev 獲取當前年化收益率
     * @return 年化收益率（以10000為基數，例如500表示5%）
     */
    function getCurrentAPY() external view returns (uint256);
    
    /**
     * @dev 獲取底層收益協議的名稱
     * @return 協議名稱
     */
    function getProtocolName() external view returns (string memory);
}
