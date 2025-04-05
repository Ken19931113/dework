// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title HashKeyIdentityVerifier
 * @dev 整合HashKey Chain身份驗證，作為房東與租客的鏈上信任來源
 */
contract HashKeyIdentityVerifier is Ownable {
    using ECDSA for bytes32;

    // 存儲已驗證的身份
    mapping(address => bool) public verifiedIdentities;
    
    // 驗證者地址，有權限驗證身份
    mapping(address => bool) public verifiers;
    
    // 身份類型
    enum IdentityType { TENANT, LANDLORD, BOTH }
    
    // 用戶身份信息
    struct UserIdentity {
        bool isVerified;
        IdentityType identityType;
        uint256 verifiedAt;
        uint256 reputation; // 0-100分
    }
    
    // 地址到身份信息的映射
    mapping(address => UserIdentity) public userIdentities;
    
    // 事件定義
    event IdentityVerified(address indexed user, IdentityType identityType);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event ReputationUpdated(address indexed user, uint256 oldScore, uint256 newScore);
    
    /**
     * @dev 構造函數
     */
    constructor() Ownable() {
        // 將部署者添加為初始驗證者
        verifiers[msg.sender] = true;
    }
    
    /**
     * @dev 添加驗證者
     * @param _verifier 驗證者地址
     */
    function addVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid verifier address");
        verifiers[_verifier] = true;
        emit VerifierAdded(_verifier);
    }
    
    /**
     * @dev 移除驗證者
     * @param _verifier 驗證者地址
     */
    function removeVerifier(address _verifier) external onlyOwner {
        require(verifiers[_verifier], "Address is not a verifier");
        verifiers[_verifier] = false;
        emit VerifierRemoved(_verifier);
    }
    
    /**
     * @dev 限制只有驗證者可以調用
     */
    modifier onlyVerifier() {
        require(verifiers[msg.sender], "Caller is not a verifier");
        _;
    }
    
    /**
     * @dev 驗證用戶身份
     * @param _user 用戶地址
     * @param _identityType 身份類型
     * @param _initialReputation 初始信譽分數
     */
    function verifyIdentity(
        address _user,
        IdentityType _identityType,
        uint256 _initialReputation
    ) external onlyVerifier {
        require(_user != address(0), "Invalid user address");
        require(_initialReputation <= 100, "Reputation score must be between 0 and 100");
        
        userIdentities[_user] = UserIdentity({
            isVerified: true,
            identityType: _identityType,
            verifiedAt: block.timestamp,
            reputation: _initialReputation
        });
        
        verifiedIdentities[_user] = true;
        emit IdentityVerified(_user, _identityType);
    }
    
    /**
     * @dev 使用簽名驗證身份（來自HashKey Chain）
     * @param _user 用戶地址
     * @param _identityType 身份類型
     * @param _signature 簽名
     */
    function verifyWithSignature(
        address _user,
        IdentityType _identityType,
        uint256 _timestamp,
        bytes calldata _signature
    ) external {
        // 防止重放攻擊
        require(block.timestamp - _timestamp < 1 hours, "Signature expired");
        
        // 創建消息哈希
        bytes32 messageHash = keccak256(abi.encodePacked(_user, uint8(_identityType), _timestamp));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        
        // 恢復簽名者地址
        address signer = ethSignedMessageHash.recover(_signature);
        
        // 驗證簽名者是否是合法驗證者
        require(verifiers[signer], "Invalid signature");
        
        // 驗證身份
        userIdentities[_user] = UserIdentity({
            isVerified: true,
            identityType: _identityType,
            verifiedAt: block.timestamp,
            reputation: 70  // 默認為70分
        });
        
        verifiedIdentities[_user] = true;
        emit IdentityVerified(_user, _identityType);
    }
    
    /**
     * @dev 更新用戶信譽分數
     * @param _user 用戶地址
     * @param _newReputation 新的信譽分數
     */
    function updateReputation(address _user, uint256 _newReputation) external onlyVerifier {
        require(userIdentities[_user].isVerified, "User not verified");
        require(_newReputation <= 100, "Reputation score must be between 0 and 100");
        
        uint256 oldScore = userIdentities[_user].reputation;
        userIdentities[_user].reputation = _newReputation;
        
        emit ReputationUpdated(_user, oldScore, _newReputation);
    }
    
    /**
     * @dev 檢查用戶是否已經驗證
     * @param _user 用戶地址
     * @return 是否已驗證
     */
    function isIdentityVerified(address _user) external view returns (bool) {
        return userIdentities[_user].isVerified;
    }
    
    /**
     * @dev 檢查用戶是否可以作為租客
     * @param _user 用戶地址
     * @return 是否可以作為租客
     */
    function canActAsTenant(address _user) external view returns (bool) {
        UserIdentity memory identity = userIdentities[_user];
        return identity.isVerified && (
            identity.identityType == IdentityType.TENANT || 
            identity.identityType == IdentityType.BOTH
        );
    }
    
    /**
     * @dev 檢查用戶是否可以作為房東
     * @param _user 用戶地址
     * @return 是否可以作為房東
     */
    function canActAsLandlord(address _user) external view returns (bool) {
        UserIdentity memory identity = userIdentities[_user];
        return identity.isVerified && (
            identity.identityType == IdentityType.LANDLORD || 
            identity.identityType == IdentityType.BOTH
        );
    }
    
    /**
     * @dev 獲取用戶身份信息
     * @param _user 用戶地址
     * @return 用戶身份信息
     */
    function getUserIdentity(address _user) external view returns (UserIdentity memory) {
        return userIdentities[_user];
    }
    
    /**
     * @dev 批量獲取用戶驗證狀態
     * @param _users 用戶地址數組
     * @return 驗證狀態數組
     */
    function batchGetVerificationStatus(address[] calldata _users) external view returns (bool[] memory) {
        bool[] memory results = new bool[](_users.length);
        
        for (uint256 i = 0; i < _users.length; i++) {
            results[i] = userIdentities[_users[i]].isVerified;
        }
        
        return results;
    }
    
    /**
     * @dev 批量獲取用戶信譽分數
     * @param _users 用戶地址數組
     * @return 信譽分數數組
     */
    function batchGetReputationScores(address[] calldata _users) external view returns (uint256[] memory) {
        uint256[] memory scores = new uint256[](_users.length);
        
        for (uint256 i = 0; i < _users.length; i++) {
            scores[i] = userIdentities[_users[i]].reputation;
        }
        
        return scores;
    }
    
    /**
     * @dev 批量驗證身份
     * @param _users 用戶地址數組
     * @param _identityTypes 身份類型數組
     * @param _initialReputations 初始信譽分數數組
     */
    function batchVerifyIdentities(
        address[] calldata _users,
        IdentityType[] calldata _identityTypes,
        uint256[] calldata _initialReputations
    ) external onlyVerifier {
        require(
            _users.length == _identityTypes.length && 
            _identityTypes.length == _initialReputations.length, 
            "Array lengths mismatch"
        );
        
        for (uint256 i = 0; i < _users.length; i++) {
            require(_users[i] != address(0), "Invalid user address");
            require(_initialReputations[i] <= 100, "Reputation score must be between 0 and 100");
            
            userIdentities[_users[i]] = UserIdentity({
                isVerified: true,
                identityType: _identityTypes[i],
                verifiedAt: block.timestamp,
                reputation: _initialReputations[i]
            });
            
            verifiedIdentities[_users[i]] = true;
            emit IdentityVerified(_users[i], _identityTypes[i]);
        }
    }
    
    /**
     * @dev 吊銷用戶身份驗證
     * @param _user 用戶地址
     */
    function revokeVerification(address _user) external onlyVerifier {
        require(userIdentities[_user].isVerified, "User not verified");
        
        userIdentities[_user].isVerified = false;
        verifiedIdentities[_user] = false;
    }
}
