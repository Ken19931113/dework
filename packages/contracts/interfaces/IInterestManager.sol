// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IInterestManager
 * @dev 利息管理器接口
 */
interface IInterestManager {
    /**
     * @dev 存入資金並投入收益協議
     * @param _amount 存款金額
     */
    function deposit(uint256 _amount) external;
    
    /**
     * @dev 從收益協議提取資金
     * @param _amount 提取金額
     * @return 實際提取金額（包含利息）
     */
    function withdraw(uint256 _amount) external returns (uint256);
    
    /**
     * @dev 計算存款金額對應的當前價值（包含利息）
     * @param _depositAmount 原始存款金額
     * @return 當前價值
     */
    function getDepositWithInterest(uint256 _depositAmount) external view returns (uint256);
    
    /**
     * @dev 獲取當前總價值
     * @return 總價值
     */
    function getTotalValue() external view returns (uint256);
    
    /**
     * @dev 獲取當前APY
     * @return 年化收益率（以10000為基數，例如500表示5%）
     */
    function getCurrentAPY() external view returns (uint256);
}
