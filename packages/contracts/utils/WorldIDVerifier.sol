// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IWorldID.sol";

/**
 * @title WorldIDVerifier
 * @dev 整合WorldID驗證用戶真實性
 */
contract WorldIDVerifier is Ownable {
    /// @notice WorldID合約接口實例
    IWorldID public immutable worldId;
    
    /// @notice 用於WorldID驗證的群組ID
    uint256 public immutable groupId;
    
    /// @notice 用於驗證的應用ID
    uint256 public immutable appId;
    
    /// @notice 用於跟踪已驗證的身份，防止重複註冊
    mapping(uint256 => bool) public nullifierHashes;
    
    /// @notice 跟踪已經通過WorldID驗證的地址
    mapping(address => bool) public verifiedAddresses;
    
    /// @notice 事件定義
    event IdentityVerified(address indexed user, uint256 nullifierHash);
    
    /**
     * @dev 構造函數
     * @param _worldId WorldID合約地址
     * @param _groupId WorldID驗證的群組ID
     * @param _appId 應用ID
     */
    constructor(
        IWorldID _worldId,
        uint256 _groupId,
        uint256 _appId
    ) Ownable() {
        worldId = _worldId;
        groupId = _groupId;
        appId = _appId;
    }
    
    /**
     * @dev 驗證WorldID證明
     * @param signal 用戶的地址（轉換為uint256）
     * @param root Merkle樹根
     * @param nullifierHash 空值哈希，用於防止重複驗證
     * @param proof 零知識證明
     */
    function verifyIdentity(
        uint256 signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external {
        // 檢查空值哈希是否已使用
        require(!nullifierHashes[nullifierHash], "WorldIDVerifier: nullifier hash has been used");
        
        // 計算用於驗證的外部空值
        uint256 externalNullifierHash = _calculateExternalNullifierHash();
        
        // 使用WorldID協議驗證證明
        worldId.verifyProof(
            root,
            groupId,
            signal,
            nullifierHash,
            externalNullifierHash,
            proof
        );
        
        // 將nullifierHash標記為已使用
        nullifierHashes[nullifierHash] = true;
        
        // 將用戶標記為已驗證
        address user = address(uint160(signal));
        verifiedAddresses[user] = true;
        
        emit IdentityVerified(user, nullifierHash);
    }
    
    /**
     * @dev 檢查地址是否通過了WorldID驗證
     * @param user 要檢查的用戶地址
     * @return 是否已驗證
     */
    function isVerified(address user) external view returns (bool) {
        return verifiedAddresses[user];
    }
    
    /**
     * @dev 手動設置地址的驗證狀態（僅限管理員，用於特殊情況）
     * @param user 用戶地址
     * @param status 驗證狀態
     */
    function setVerificationStatus(address user, bool status) external onlyOwner {
        verifiedAddresses[user] = status;
    }
    
    /**
     * @dev 計算外部空值哈希
     * @return 外部空值哈希
     */
    function _calculateExternalNullifierHash() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(appId, "dework-rental-verification")));
    }
}
