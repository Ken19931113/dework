// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IYieldProvider.sol";

// Compound cToken接口
interface ICToken {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
}

/**
 * @title CompoundYieldProvider
 * @dev 使用Compound協議生成收益的提供者
 */
contract CompoundYieldProvider is IYieldProvider, Ownable {
    using SafeERC20 for IERC20;
    
    // 合約狀態變數
    IERC20 public depositToken;   // 存款代幣（如USDC）
    ICToken public cToken;        // Compound的cToken
    
    // 每年的區塊數（以太坊大約每15秒一個區塊）
    uint256 public constant BLOCKS_PER_YEAR = 2102400;  // 60 * 60 * 24 * 365 / 15
    
    /**
     * @dev 構造函數
     * @param _depositToken 存款代幣地址
     * @param _cToken Compound cToken地址
     */
    constructor(
        address _depositToken,
        address _cToken
    ) {
        depositToken = IERC20(_depositToken);
        cToken = ICToken(_cToken);
    }
    
    /**
     * @dev 將資金存入Compound
     * @param _amount 存款金額
     */
    function deposit(uint256 _amount) external override {
        require(_amount > 0, "Amount must be greater than 0");
        
        // 從調用者轉移代幣到合約
        depositToken.safeTransferFrom(msg.sender, address(this), _amount);
        
        // 批准cToken合約使用代幣
        depositToken.approve(address(cToken), _amount);
        
        // 存入Compound
        uint256 mintResult = cToken.mint(_amount);
        require(mintResult == 0, "Compound mint failed");
    }
    
    /**
     * @dev 從Compound提取資金
     * @param _amount 要提取的金額
     * @return 實際提取金額
     */
    function withdraw(uint256 _amount) external override onlyOwner returns (uint256) {
        require(_amount > 0, "Amount must be greater than 0");
        
        // 從Compound提取
        uint256 redeemResult = cToken.redeemUnderlying(_amount);
        require(redeemResult == 0, "Compound redeem failed");
        
        // 獲取當前餘額
        uint256 balance = depositToken.balanceOf(address(this));
        uint256 amountToSend = _amount > balance ? balance : _amount;
        
        // 將提取的代幣轉給調用者
        depositToken.safeTransfer(msg.sender, amountToSend);
        
        return amountToSend;
    }
    
    /**
     * @dev 提取所有資金
     * @return 提取的總金額
     */
    function withdrawAll() external override onlyOwner returns (uint256) {
        // 獲取cToken餘額
        uint256 cTokenBalance = cToken.balanceOf(address(this));
        
        if (cTokenBalance == 0) {
            return 0;
        }
        
        // 從Compound提取所有資金
        uint256 redeemResult = cToken.redeem(cTokenBalance);
        require(redeemResult == 0, "Compound redeem failed");
        
        // 獲取當前餘額
        uint256 balance = depositToken.balanceOf(address(this));
        
        // 將提取的代幣轉給調用者
        depositToken.safeTransfer(msg.sender, balance);
        
        return balance;
    }
    
    /**
     * @dev 獲取當前存款的總價值
     * @return 總價值
     */
    function getTotalValue() external view override returns (uint256) {
        // 獲取cToken餘額
        uint256 cTokenBalance = cToken.balanceOf(address(this));
        
        // 獲取當前匯率
        uint256 exchangeRate = cToken.exchangeRateStored();
        
        // 計算總價值
        // Compound匯率是以1e18為基數的，需要除以1e18
        return (cTokenBalance * exchangeRate) / 1e18;
    }
    
    /**
     * @dev 獲取當前年化收益率
     * @return 年化收益率（以10000為基數）
     */
    function getCurrentAPY() external view override returns (uint256) {
        // 獲取每區塊利率
        uint256 supplyRatePerBlock = cToken.supplyRatePerBlock();
        
        // 計算年化收益率
        // 公式：((1 + 每區塊利率) ^ 區塊數) - 1
        // 為了簡化計算，使用線性近似：利率 * 區塊數
        uint256 apy = supplyRatePerBlock * BLOCKS_PER_YEAR;
        
        // 轉換為以10000為基數的百分比
        return (apy * 10000) / 1e18;
    }
    
    /**
     * @dev 獲取底層收益協議的名稱
     * @return 協議名稱
     */
    function getProtocolName() external pure override returns (string memory) {
        return "Compound";
    }
    
    /**
     * @dev 更新Compound合約地址
     * @param _cToken 新的cToken地址
     */
    function updateCompoundContract(address _cToken) external onlyOwner {
        cToken = ICToken(_cToken);
    }
    
    /**
     * @dev 獲取當前cToken餘額
     * @return cToken餘額
     */
    function getCTokenBalance() external view returns (uint256) {
        return cToken.balanceOf(address(this));
    }
    
    /**
     * @dev 獲取當前匯率
     * @return cToken與底層資產的匯率
     */
    function getExchangeRate() external view returns (uint256) {
        return cToken.exchangeRateStored();
    }
}