// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ISelfProtocol
 * @dev Interface for the Self Protocol credit assessment
 */
interface ISelfProtocol {
    /**
     * @dev Tenant credit score data structure
     */
    struct CreditScore {
        uint256 score;            // 0-1000 score
        uint256 updatedAt;        // Last update timestamp
        bool isVerified;          // Whether the score is verified
        uint8 riskCategory;       // Risk category: 1 (lowest) to 5 (highest)
    }
    
    /**
     * @dev Get tenant credit score
     * @param tenant Address of the tenant
     * @return CreditScore The tenant's credit score
     */
    function getTenantCreditScore(address tenant) external view returns (CreditScore memory);
    
    /**
     * @dev Update tenant credit score
     * @param tenant Address of the tenant
     * @param score New credit score
     * @param riskCategory New risk category
     */
    function updateTenantCreditScore(
        address tenant,
        uint256 score,
        uint8 riskCategory
    ) external;
    
    /**
     * @dev Verify tenant identity
     * @param tenant Address of the tenant
     */
    function verifyTenant(address tenant) external;
    
    /**
     * @dev Calculate recommended interest sharing percentage based on tenant risk
     * @param tenant Address of the tenant
     * @return uint256 Recommended percentage of interest to share with tenant (in basis points, e.g. 5000 = 50%)
     */
    function calculateInterestSharingPercentage(address tenant) external view returns (uint256);
    
    /**
     * @dev Record rental payment history
     * @param tenant Address of the tenant
     * @param amount Amount paid
     * @param onTime Whether the payment was on time
     */
    function recordRentalPayment(
        address tenant,
        uint256 amount,
        bool onTime
    ) external;
}
