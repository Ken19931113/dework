// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IYieldProvider.sol";

/**
 * @title InterestManager
 * @dev 管理租賃押金的利息生成和分配
 */
contract InterestManager is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // 合約狀態變數
    IERC20 public depositToken;
    IYieldProvider public yieldProvider;
    
    // 紀錄總存款金額
    uint256 public totalDeposits;
    
    // 事件定義
    event DepositMade(address indexed from, uint256 amount);
    event WithdrawalMade(address indexed to, uint256 amount);
    event YieldProviderUpdated(address indexed newProvider);
    
    /**
     * @dev 構造函數
     * @param _depositToken 押金使用的ERC20代幣地址
     * @param _yieldProvider 收益提供者合約地址
     */
    constructor(address _depositToken, address _yieldProvider) Ownable() {
        depositToken = IERC20(_depositToken);
        yieldProvider = IYieldProvider(_yieldProvider);
    }
    
    /**
     * @dev 存入資金並投入收益協議
     * @param _amount 存款金額
     */
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        
        // 從調用者轉移代幣到合約
        depositToken.safeTransferFrom(msg.sender, address(this), _amount);
        
        // 批准收益提供者使用代幣
        depositToken.approve(address(yieldProvider), _amount);
        
        // 將資金存入收益提供者
        yieldProvider.deposit(_amount);
        
        // 更新總存款金額
        totalDeposits += _amount;
        
        emit DepositMade(msg.sender, _amount);
    }
    
    /**
     * @dev 從收益協議提取資金
     * @param _amount 提取金額
     * @return 實際提取金額（包含利息）
     */
    function withdraw(uint256 _amount) external nonReentrant returns (uint256) {
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= totalDeposits, "Insufficient funds");
        
        // 計算應該提取的金額（考慮累積的利息）
        uint256 sharePercentage = (_amount * 1e18) / totalDeposits;
        uint256 totalValue = yieldProvider.getTotalValue();
        uint256 withdrawAmount = (totalValue * sharePercentage) / 1e18;
        
        // 從收益提供者提取資金
        uint256 actualWithdrawn = yieldProvider.withdraw(withdrawAmount);
        
        // 更新總存款金額
        totalDeposits -= _amount;
        
        // 向調用者轉移代幣
        depositToken.safeTransfer(msg.sender, actualWithdrawn);
        
        emit WithdrawalMade(msg.sender, actualWithdrawn);
        
        return actualWithdrawn;
    }
    
    /**
     * @dev 計算存款金額對應的當前價值（包含利息）
     * @param _depositAmount 原始存款金額
     * @return 當前價值
     */
    function getDepositWithInterest(uint256 _depositAmount) external view returns (uint256) {
        if (totalDeposits == 0) return _depositAmount;
        
        uint256 sharePercentage = (_depositAmount * 1e18) / totalDeposits;
        uint256 totalValue = yieldProvider.getTotalValue();
        return (totalValue * sharePercentage) / 1e18;
    }
    
    /**
     * @dev 獲取當前總價值
     * @return 總價值
     */
    function getTotalValue() external view returns (uint256) {
        return yieldProvider.getTotalValue();
    }
    
    /**
     * @dev 獲取當前APY
     * @return 年化收益率（以10000為基數，例如500表示5%）
     */
    function getCurrentAPY() external view returns (uint256) {
        return yieldProvider.getCurrentAPY();
    }
    
    /**
     * @dev 更新收益提供者
     * @param _newYieldProvider 新的收益提供者地址
     */
    function updateYieldProvider(address _newYieldProvider) external onlyOwner {
        require(_newYieldProvider != address(0), "Invalid provider address");
        
        // 從舊提供者提取全部資金
        uint256 totalValue = yieldProvider.getTotalValue();
        yieldProvider.withdrawAll();
        
        // 更新提供者地址
        yieldProvider = IYieldProvider(_newYieldProvider);
        
        // 批准新提供者使用代幣
        uint256 balance = depositToken.balanceOf(address(this));
        depositToken.approve(address(yieldProvider), balance);
        
        // 將資金存入新提供者
        yieldProvider.deposit(balance);
        
        emit YieldProviderUpdated(_newYieldProvider);
    }
    
    /**
     * @dev 緊急提款功能，允許所有者在緊急情況下提取所有資金
     */
    function emergencyWithdraw() external onlyOwner {
        // 從收益提供者提取全部資金
        yieldProvider.withdrawAll();
        
        // 獲取合約餘額
        uint256 balance = depositToken.balanceOf(address(this));
        
        // 將全部餘額轉給所有者
        depositToken.safeTransfer(owner(), balance);
        
        // 重置總存款金額
        totalDeposits = 0;
    }
}
