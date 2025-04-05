// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IYieldProvider.sol";

/**
 * @title MockYieldProvider
 * @dev 模擬收益提供者，用於測試目的
 */
contract MockYieldProvider is IYieldProvider, Ownable {
    using SafeERC20 for IERC20;

    // 合約狀態變數
    IERC20 public depositToken;
    uint256 public totalDeposits;
    uint256 public interestRate = 500; // 年化5%，以10000為基數
    uint256 public lastUpdateTime;
    
    // 事件定義
    event DepositMade(uint256 amount);
    event WithdrawalMade(uint256 amount);
    event InterestRateUpdated(uint256 newRate);
    
    /**
     * @dev 構造函數
     * @param _depositToken 存款代幣地址
     */
    constructor(address _depositToken) {
        depositToken = IERC20(_depositToken);
        lastUpdateTime = block.timestamp;
    }
    
    /**
     * @dev 存入資金
     * @param _amount 存款金額
     */
    function deposit(uint256 _amount) external override {
        require(_amount > 0, "Amount must be greater than 0");
        
        // 更新累積利息
        _updateInterest();
        
        // 從調用者轉移代幣到合約
        depositToken.safeTransferFrom(msg.sender, address(this), _amount);
        
        // 更新總存款金額
        totalDeposits += _amount;
        
        emit DepositMade(_amount);
    }
    
    /**
     * @dev 提取資金
     * @param _amount 提取金額
     * @return 實際提取金額
     */
    function withdraw(uint256 _amount) external override onlyOwner returns (uint256) {
        require(_amount > 0, "Amount must be greater than 0");
        
        // 更新累積利息
        _updateInterest();
        
        // 計算可提取金額
        uint256 balance = depositToken.balanceOf(address(this));
        uint256 amountToWithdraw = _amount > balance ? balance : _amount;
        
        // 更新總存款金額
        if (amountToWithdraw > totalDeposits) {
            totalDeposits = 0;
        } else {
            totalDeposits -= amountToWithdraw;
        }
        
        // 轉移代幣給調用者
        depositToken.safeTransfer(msg.sender, amountToWithdraw);
        
        emit WithdrawalMade(amountToWithdraw);
        
        return amountToWithdraw;
    }
    
    /**
     * @dev 提取所有資金
     * @return 提取的總金額
     */
    function withdrawAll() external override onlyOwner returns (uint256) {
        // 更新累積利息
        _updateInterest();
        
        // 獲取當前餘額
        uint256 balance = depositToken.balanceOf(address(this));
        
        if (balance == 0) {
            return 0;
        }
        
        // 重置總存款金額
        totalDeposits = 0;
        
        // 轉移所有代幣給調用者
        depositToken.safeTransfer(msg.sender, balance);
        
        emit WithdrawalMade(balance);
        
        return balance;
    }
    
    /**
     * @dev 獲取當前總價值
     * @return 總價值
     */
    function getTotalValue() external view override returns (uint256) {
        if (totalDeposits == 0) {
            return 0;
        }
        
        // 計算累積的利息
        uint256 timeElapsed = block.timestamp - lastUpdateTime;
        uint256 interest = (totalDeposits * interestRate * timeElapsed) / (365 days * 10000);
        
        return totalDeposits + interest;
    }
    
    /**
     * @dev 獲取當前APY
     * @return 年化收益率（以10000為基數）
     */
    function getCurrentAPY() external view override returns (uint256) {
        return interestRate;
    }
    
    /**
     * @dev 獲取底層收益協議的名稱
     * @return 協議名稱
     */
    function getProtocolName() external pure override returns (string memory) {
        return "MockYield";
    }
    
    /**
     * @dev 設置年化利率
     * @param _newRate 新的年化利率（以10000為基數）
     */
    function setInterestRate(uint256 _newRate) external onlyOwner {
        require(_newRate <= 3000, "Rate too high"); // 最高30%
        
        // 更新累積利息
        _updateInterest();
        
        // 更新利率
        interestRate = _newRate;
        
        emit InterestRateUpdated(_newRate);
    }
    
    /**
     * @dev 更新累積利息
     */
    function _updateInterest() internal {
        if (totalDeposits > 0) {
            uint256 timeElapsed = block.timestamp - lastUpdateTime;
            if (timeElapsed > 0) {
                uint256 interest = (totalDeposits * interestRate * timeElapsed) / (365 days * 10000);
                
                // 模擬產生利息（實際上只是增加總存款金額）
                totalDeposits += interest;
            }
        }
        
        // 更新時間戳
        lastUpdateTime = block.timestamp;
    }
    
    /**
     * @dev 模擬利息支付（僅用於測試）
     */
    function simulateInterestPayment() external onlyOwner {
        _updateInterest();
    }
}
