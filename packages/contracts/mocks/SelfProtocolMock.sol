// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ISelfProtocol.sol";

/**
 * @title SelfProtocolMock
 * @dev 模擬Self Protocol的實現，用於測試和演示
 * 此合約模擬租客信用憑證、風險評估以及利息分潤計算功能
 */
contract SelfProtocolMock is ISelfProtocol, Ownable {
    // 租客信用分數映射
    mapping(address => CreditScore) public tenantCreditScores;
    
    // 租客支付歷史記錄
    struct PaymentHistory {
        uint256 totalPayments;
        uint256 onTimePayments;
        uint256 latePayments;
        uint256 lastPaymentTime;
    }
    
    // 租客支付歷史映射
    mapping(address => PaymentHistory) public paymentHistories;
    
    // 事件定義
    event CreditScoreUpdated(address indexed tenant, uint256 score, uint8 riskCategory);
    event TenantVerified(address indexed tenant);
    event PaymentRecorded(address indexed tenant, uint256 amount, bool onTime);
    
    /**
     * @dev 構造函數
     */
    constructor() Ownable() {}
    
    /**
     * @dev 獲取租客信用分數
     * @param tenant 租客地址
     * @return 信用分數數據
     */
    function getTenantCreditScore(address tenant) external view override returns (CreditScore memory) {
        // 如果租客還沒有信用分數記錄，返回默認值
        if (tenantCreditScores[tenant].updatedAt == 0) {
            return CreditScore({
                score: 700,
                updatedAt: 0,
                isVerified: false,
                riskCategory: 3
            });
        }
        
        return tenantCreditScores[tenant];
    }
    
    /**
     * @dev 更新租客信用分數
     * @param tenant 租客地址
     * @param score 新的信用分數
     * @param riskCategory 新的風險類別
     */
    function updateTenantCreditScore(
        address tenant,
        uint256 score,
        uint8 riskCategory
    ) external override onlyOwner {
        require(score <= 1000, "Score cannot exceed 1000");
        require(riskCategory >= 1 && riskCategory <= 5, "Risk category must be between 1 and 5");
        
        tenantCreditScores[tenant] = CreditScore({
            score: score,
            updatedAt: block.timestamp,
            isVerified: tenantCreditScores[tenant].isVerified,
            riskCategory: riskCategory
        });
        
        emit CreditScoreUpdated(tenant, score, riskCategory);
    }
    
    /**
     * @dev 驗證租客身份
     * @param tenant 租客地址
     */
    function verifyTenant(address tenant) external override onlyOwner {
        // 如果租客還沒有信用分數記錄，創建一個默認的
        if (tenantCreditScores[tenant].updatedAt == 0) {
            tenantCreditScores[tenant] = CreditScore({
                score: 700,
                updatedAt: block.timestamp,
                isVerified: true,
                riskCategory: 3
            });
        } else {
            tenantCreditScores[tenant].isVerified = true;
            tenantCreditScores[tenant].updatedAt = block.timestamp;
        }
        
        emit TenantVerified(tenant);
    }
    
    /**
     * @dev 根據租客風險計算推薦的利息分享百分比
     * @param tenant 租客地址
     * @return 推薦的利息分享百分比（基點，例如5000 = 50%）
     */
    function calculateInterestSharingPercentage(address tenant) external view override returns (uint256) {
        CreditScore memory score = tenantCreditScores[tenant];
        
        // 如果租客還沒有信用記錄，返回默認值
        if (score.updatedAt == 0) {
            return 2000; // 20%
        }
        
        // 根據風險類別計算利息分享百分比
        if (score.riskCategory == 1) {
            return 5000; // 最低風險 - 50%
        } else if (score.riskCategory == 2) {
            return 4000; // 低風險 - 40%
        } else if (score.riskCategory == 3) {
            return 3000; // 中等風險 - 30%
        } else if (score.riskCategory == 4) {
            return 2000; // 高風險 - 20%
        } else {
            return 1000; // 最高風險 - 10%
        }
    }
    
    /**
     * @dev 記錄租賃支付歷史
     * @param tenant 租客地址
     * @param amount 支付金額
     * @param onTime 是否按時支付
     */
    function recordRentalPayment(
        address tenant,
        uint256 amount,
        bool onTime
    ) external override onlyOwner {
        PaymentHistory storage history = paymentHistories[tenant];
        
        history.totalPayments += 1;
        if (onTime) {
            history.onTimePayments += 1;
        } else {
            history.latePayments += 1;
        }
        history.lastPaymentTime = block.timestamp;
        
        // 更新信用分數
        _updateCreditScoreBasedOnPayment(tenant, onTime);
        
        emit PaymentRecorded(tenant, amount, onTime);
    }
    
    /**
     * @dev 根據支付歷史更新信用分數
     * @param tenant 租客地址
     * @param onTime 是否按時支付
     */
    function _updateCreditScoreBasedOnPayment(address tenant, bool onTime) internal {
        CreditScore storage score = tenantCreditScores[tenant];
        
        // 如果租客還沒有信用分數記錄，創建一個默認的
        if (score.updatedAt == 0) {
            score.score = 700;
            score.riskCategory = 3;
            score.isVerified = false;
        }
        
        // 按時支付增加分數，逾期支付減少分數
        if (onTime) {
            if (score.score <= 950) {
                score.score += 50;
            }
            // 連續五次按時付款後降低風險類別
            PaymentHistory memory history = paymentHistories[tenant];
            if (history.totalPayments >= 5 && history.onTimePayments >= 5 && score.riskCategory > 1) {
                score.riskCategory -= 1;
            }
        } else {
            if (score.score >= 100) {
                score.score -= 100;
            }
            // 逾期付款提高風險類別
            if (score.riskCategory < 5) {
                score.riskCategory += 1;
            }
        }
        
        score.updatedAt = block.timestamp;
        
        emit CreditScoreUpdated(tenant, score.score, score.riskCategory);
    }
    
    /**
     * @dev 獲取租客的支付歷史
     * @param tenant 租客地址
     * @return totalPayments 總付款次數
     * @return onTimePayments 按時付款次數
     * @return latePayments 逾期付款次數
     * @return lastPaymentTime 最後付款時間
     */
    function getPaymentHistory(address tenant) external view returns (
        uint256 totalPayments,
        uint256 onTimePayments,
        uint256 latePayments,
        uint256 lastPaymentTime
    ) {
        PaymentHistory memory history = paymentHistories[tenant];
        return (
            history.totalPayments,
            history.onTimePayments,
            history.latePayments,
            history.lastPaymentTime
        );
    }
    
    /**
     * @dev 批量更新租客信用分數
     * @param tenants 租客地址數組
     * @param scores 信用分數數組
     * @param riskCategories 風險類別數組
     */
    function batchUpdateCreditScores(
        address[] calldata tenants,
        uint256[] calldata scores,
        uint8[] calldata riskCategories
    ) external onlyOwner {
        require(
            tenants.length == scores.length && scores.length == riskCategories.length,
            "Array lengths mismatch"
        );
        
        for (uint256 i = 0; i < tenants.length; i++) {
            require(scores[i] <= 1000, "Score cannot exceed 1000");
            require(riskCategories[i] >= 1 && riskCategories[i] <= 5, "Risk category must be between 1 and 5");
            
            tenantCreditScores[tenants[i]] = CreditScore({
                score: scores[i],
                updatedAt: block.timestamp,
                isVerified: tenantCreditScores[tenants[i]].isVerified,
                riskCategory: riskCategories[i]
            });
            
            emit CreditScoreUpdated(tenants[i], scores[i], riskCategories[i]);
        }
    }
}
