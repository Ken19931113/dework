// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IYieldProvider.sol";

// Aave協議接口（簡化版）
interface IAaveLendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
    
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

// Aave利率協議接口
interface IAaveDataProvider {
    function getReserveData(address asset) 
        external 
        view 
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );
}

/**
 * @title AaveYieldProvider
 * @dev 使用Aave協議生成收益的提供者
 */
contract AaveYieldProvider is IYieldProvider, Ownable {
    using SafeERC20 for IERC20;
    
    // 合約狀態變數
    IERC20 public depositToken;       // 存款代幣（如USDC）
    IERC20 public aToken;             // Aave的收益代幣
    IAaveLendingPool public lendingPool;
    IAaveDataProvider public dataProvider;
    
    /**
     * @dev 構造函數
     * @param _depositToken 存款代幣地址
     * @param _aToken Aave aToken地址
     * @param _lendingPool Aave借貸池地址
     * @param _dataProvider Aave數據提供者地址
     */
    constructor(
        address _depositToken,
        address _aToken,
        address _lendingPool,
        address _dataProvider
    ) {
        depositToken = IERC20(_depositToken);
        aToken = IERC20(_aToken);
        lendingPool = IAaveLendingPool(_lendingPool);
        dataProvider = IAaveDataProvider(_dataProvider);
    }
    
    /**
     * @dev 將資金存入Aave
     * @param _amount 存款金額
     */
    function deposit(uint256 _amount) external override {
        require(_amount > 0, "Amount must be greater than 0");
        
        // 從調用者轉移代幣到合約
        depositToken.safeTransferFrom(msg.sender, address(this), _amount);
        
        // 批准Aave借貸池使用代幣
        depositToken.approve(address(lendingPool), _amount);
        
        // 存入Aave
        lendingPool.deposit(
            address(depositToken),
            _amount,
            address(this),
            0  // 推薦碼
        );
    }
    
    /**
     * @dev 從Aave提取資金
     * @param _amount 要提取的金額
     * @return 實際提取金額
     */
    function withdraw(uint256 _amount) external override onlyOwner returns (uint256) {
        require(_amount > 0, "Amount must be greater than 0");
        
        // 從Aave提取
        uint256 amountWithdrawn = lendingPool.withdraw(
            address(depositToken),
            _amount,
            address(this)
        );
        
        // 將提取的代幣轉給調用者
        depositToken.safeTransfer(msg.sender, amountWithdrawn);
        
        return amountWithdrawn;
    }
    
    /**
     * @dev 提取所有資金
     * @return 提取的總金額
     */
    function withdrawAll() external override onlyOwner returns (uint256) {
        // 獲取aToken餘額
        uint256 aTokenBalance = aToken.balanceOf(address(this));
        
        if (aTokenBalance == 0) {
            return 0;
        }
        
        // 從Aave提取所有資金
        uint256 amountWithdrawn = lendingPool.withdraw(
            address(depositToken),
            type(uint256).max,  // 提取所有資金
            address(this)
        );
        
        // 將提取的代幣轉給調用者
        depositToken.safeTransfer(msg.sender, amountWithdrawn);
        
        return amountWithdrawn;
    }
    
    /**
     * @dev 獲取當前存款的總價值
     * @return 總價值
     */
    function getTotalValue() external view override returns (uint256) {
        // 在Aave中，aToken的餘額即為存款價值（包含收益）
        return aToken.balanceOf(address(this));
    }
    
    /**
     * @dev 獲取當前年化收益率
     * @return 年化收益率（以10000為基數）
     */
    function getCurrentAPY() external view override returns (uint256) {
        // 從Aave獲取當前利率數據
        (
            ,
            ,
            ,
            uint256 liquidityRate,
            ,
            ,
            ,
            ,
            ,
            
        ) = dataProvider.getReserveData(address(depositToken));
        
        // Aave的利率是以RAY單位計算的（10^27），轉換為百分比
        // 返回值以10000為基數，所以500表示5%
        return (liquidityRate / 10**23);
    }
    
    /**
     * @dev 獲取底層收益協議的名稱
     * @return 協議名稱
     */
    function getProtocolName() external pure override returns (string memory) {
        return "Aave";
    }
    
    /**
     * @dev 更新Aave合約地址
     * @param _lendingPool 新的借貸池地址
     * @param _dataProvider 新的數據提供者地址
     */
    function updateAaveContracts(address _lendingPool, address _dataProvider) external onlyOwner {
        lendingPool = IAaveLendingPool(_lendingPool);
        dataProvider = IAaveDataProvider(_dataProvider);
    }
    
    /**
     * @dev 獲取當前存款與借貸的利率差距
     * @return 存款利率和可變借貸利率（以10000為基數）
     */
    function getRateSpread() external view returns (uint256, uint256) {
        (
            ,
            ,
            ,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            ,
            ,
            ,
            ,
            
        ) = dataProvider.getReserveData(address(depositToken));
        
        return (liquidityRate / 10**23, variableBorrowRate / 10**23);
    }
}