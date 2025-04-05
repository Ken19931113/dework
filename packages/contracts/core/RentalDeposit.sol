// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IInterestManager.sol";
import "../interfaces/IRentalNFT.sol";
import "../interfaces/ICircleUSDC.sol";
import "../interfaces/ISelfProtocol.sol";
import "../utils/WorldIDVerifier.sol";

/**
 * @title RentalDeposit
 * @dev 管理租賃押金的智能合約，整合多種技術與功能
 */
contract RentalDeposit is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // 合約狀態變數
    IInterestManager public interestManager;
    IRentalNFT public rentalNFT;
    IERC20 public depositToken;  // 用於押金的穩定幣（如USDC）
    WorldIDVerifier public worldIDVerifier;
    ISelfProtocol public selfProtocol;
    
    uint256 public platformFeePercentage = 10; // 平台收取的利息百分比，初始為10%
    uint256 public constant PERCENTAGE_DENOMINATOR = 100;
    uint256 public disputePeriod = 7 days; // 爭議解決期限
    bool public worldIDRequired = true;  // 是否要求WorldID驗證
    
    // 租賃信息結構
    struct RentalInfo {
        address tenant;          // 租客地址
        address landlord;        // 房東地址
        uint256 depositAmount;   // 押金金額
        uint256 startTime;       // 開始時間
        uint256 endTime;         // 結束時間
        uint256 releaseTime;     // 押金釋放時間
        bool isActive;           // 租賃是否活躍
        bool inDispute;          // 是否處於爭議狀態
        uint256 interestSharingPercentage; // 租客分享利息的百分比 (0-100)
        bool isVerified;         // 租客是否通過WorldID驗證
        string metadataURI;      // 租賃元數據的IPFS URI
    }
    
    // 租賃ID到租賃信息的映射
    mapping(uint256 => RentalInfo) public rentals;
    // 用戶地址到其參與的租賃ID數組的映射
    mapping(address => uint256[]) public userRentals;
    // HashKey Chain身份驗證狀態
    mapping(address => bool) public hashKeyVerified;
    
    // 事件定義
    event RentalCreated(uint256 indexed rentalId, address indexed tenant, address indexed landlord, uint256 amount);
    event DepositPaid(uint256 indexed rentalId, uint256 amount);
    event DisputeRaised(uint256 indexed rentalId, address initiator);
    event DisputeResolved(uint256 indexed rentalId, bool favorTenant);
    event DepositReleased(uint256 indexed rentalId, address recipient, uint256 amount);
    event DepositRefunded(uint256 indexed rentalId, address tenant, uint256 amount);
    event InterestWithdrawn(uint256 indexed rentalId, address recipient, uint256 amount);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event HashKeyVerificationUpdated(address indexed user, bool status);
    event MetadataUpdated(uint256 indexed rentalId, string metadataURI);
    event InterestSharingUpdated(uint256 indexed rentalId, uint256 percentage);
    
    /**
     * @dev 構造函數
     * @param _depositToken 押金使用的ERC20代幣地址
     * @param _interestManager 利息管理器合約地址
     * @param _rentalNFT 租賃NFT合約地址
     * @param _worldIDVerifier WorldID驗證器合約地址
     * @param _selfProtocol Self Protocol合約地址 (如果沒有可傳入零地址)
     */
    constructor(
        address _depositToken,
        address _interestManager,
        address _rentalNFT,
        address _worldIDVerifier,
        address _selfProtocol
    ) Ownable() {
        depositToken = IERC20(_depositToken);
        interestManager = IInterestManager(_interestManager);
        rentalNFT = IRentalNFT(_rentalNFT);
        
        if (_worldIDVerifier != address(0)) {
            worldIDVerifier = WorldIDVerifier(_worldIDVerifier);
        }
        
        if (_selfProtocol != address(0)) {
            selfProtocol = ISelfProtocol(_selfProtocol);
        }
    }
    
    /**
     * @dev 檢查用戶是否通過必要的身份驗證
     * @param _user 要檢查的用戶地址
     * @return 是否通過驗證
     */
    function _checkVerification(address _user) internal view returns (bool) {
        if (!worldIDRequired) {
            return true;
        }
        
        // 如果WorldID驗證器合約存在，檢查驗證狀態
        if (address(worldIDVerifier) != address(0)) {
            return worldIDVerifier.isVerified(_user);
        }
        
        return true;
    }
    
    /**
     * @dev 創建新的租賃關係
     * @param _landlord 房東地址
     * @param _depositAmount 押金金額
     * @param _leaseDuration 租期（秒）
     * @param _metadataURI 租賃元數據的IPFS URI
     * @param _interestSharingPercentage 租客分享利息的百分比 (0-100)
     * @return rentalId 新創建的租賃ID
     */
    function createRental(
        address _landlord,
        uint256 _depositAmount,
        uint256 _leaseDuration,
        string calldata _metadataURI,
        uint256 _interestSharingPercentage
    ) external nonReentrant returns (uint256) {
        require(_landlord != address(0), "Invalid landlord address");
        require(_depositAmount > 0, "Deposit must be greater than 0");
        require(_leaseDuration > 0, "Lease duration must be greater than 0");
        require(_interestSharingPercentage <= 100, "Interest sharing percentage cannot exceed 100");
        
        // 檢查租客是否通過身份驗證
        bool isVerified = _checkVerification(msg.sender);
        if (worldIDRequired) {
            require(isVerified, "Tenant must be verified with WorldID");
        }
        
        // 從租客轉移押金到合約
        depositToken.safeTransferFrom(msg.sender, address(this), _depositAmount);
        
        // 將押金存入利息管理器
        depositToken.approve(address(interestManager), _depositAmount);
        interestManager.deposit(_depositAmount);
        
        // 計算結束時間和釋放時間
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _leaseDuration;
        uint256 releaseTime = endTime + disputePeriod;
        
        // 創建租賃NFT並獲取ID
        uint256 rentalId = rentalNFT.mint(msg.sender, _landlord);
        
        // 使用Self Protocol評估租客風險並獲取建議的利息分享百分比
        uint256 finalInterestSharing = _interestSharingPercentage;
        if (address(selfProtocol) != address(0)) {
            try selfProtocol.calculateInterestSharingPercentage(msg.sender) returns (uint256 recommendedPercentage) {
                if (recommendedPercentage < _interestSharingPercentage) {
                    finalInterestSharing = recommendedPercentage;
                }
            } catch {
                // 如果調用失敗，使用用戶提供的百分比
            }
        }
        
        // 儲存租賃信息
        rentals[rentalId] = RentalInfo({
            tenant: msg.sender,
            landlord: _landlord,
            depositAmount: _depositAmount,
            startTime: startTime,
            endTime: endTime,
            releaseTime: releaseTime,
            isActive: true,
            inDispute: false,
            interestSharingPercentage: finalInterestSharing,
            isVerified: isVerified,
            metadataURI: _metadataURI
        });
        
        // 更新用戶租賃記錄
        userRentals[msg.sender].push(rentalId);
        userRentals[_landlord].push(rentalId);
        
        // 設置NFT元數據URI
        rentalNFT.setTokenURI(rentalId, _metadataURI);
        
        emit RentalCreated(rentalId, msg.sender, _landlord, _depositAmount);
        
        return rentalId;
    }
    
    /**
     * @dev 結束租賃並釋放押金給房東
     * @param _rentalId 租賃ID
     */
    function endRental(uint256 _rentalId) external nonReentrant {
        RentalInfo storage rental = rentals[_rentalId];
        
        require(rental.isActive, "Rental is not active");
        require(msg.sender == rental.tenant || msg.sender == rental.landlord || msg.sender == owner(), "Not authorized");
        require(block.timestamp >= rental.endTime, "Lease period not ended");
        require(!rental.inDispute, "Rental is in dispute");
        
        if (msg.sender == rental.tenant) {
            // 如果是租客提前結束，需要等到釋放時間
            require(block.timestamp >= rental.releaseTime, "Cannot end before release time");
        }
        
        // 從利息管理器提取押金
        uint256 depositWithInterest = interestManager.getDepositWithInterest(rental.depositAmount);
        interestManager.withdraw(rental.depositAmount);
        
        // 計算利息
        uint256 interest = depositWithInterest > rental.depositAmount ? 
                          depositWithInterest - rental.depositAmount : 0;
        
        uint256 platformFee = (interest * platformFeePercentage) / PERCENTAGE_DENOMINATOR;
        uint256 tenantShare = (interest * rental.interestSharingPercentage) / PERCENTAGE_DENOMINATOR;
        uint256 landlordAmount = depositWithInterest - platformFee - tenantShare;
        
        // 轉移資金
        if (platformFee > 0) {
            depositToken.safeTransfer(owner(), platformFee);
        }
        
        if (tenantShare > 0) {
            depositToken.safeTransfer(rental.tenant, tenantShare);
            emit InterestWithdrawn(_rentalId, rental.tenant, tenantShare);
        }
        
        depositToken.safeTransfer(rental.landlord, landlordAmount);
        
        // 更新租賃狀態
        rental.isActive = false;
        
        // 燒掉租賃NFT
        rentalNFT.burn(_rentalId);
        
        emit DepositReleased(_rentalId, rental.landlord, landlordAmount);
    }
    
    /**
     * @dev 提出爭議
     * @param _rentalId 租賃ID
     */
    function raiseDispute(uint256 _rentalId) external nonReentrant {
        RentalInfo storage rental = rentals[_rentalId];
        
        require(rental.isActive, "Rental is not active");
        require(msg.sender == rental.tenant, "Only tenant can raise dispute");
        require(block.timestamp < rental.releaseTime, "Too late to raise dispute");
        require(!rental.inDispute, "Dispute already raised");
        
        rental.inDispute = true;
        
        emit DisputeRaised(_rentalId, msg.sender);
    }
    
    /**
     * @dev 平台解決爭議
     * @param _rentalId 租賃ID
     * @param _favorTenant 是否有利於租客
     */
    function resolveDispute(uint256 _rentalId, bool _favorTenant) external onlyOwner nonReentrant {
        RentalInfo storage rental = rentals[_rentalId];
        
        require(rental.isActive, "Rental is not active");
        require(rental.inDispute, "No active dispute");
        
        // 從利息管理器提取押金
        uint256 depositWithInterest = interestManager.getDepositWithInterest(rental.depositAmount);
        interestManager.withdraw(rental.depositAmount);
        
        // 計算利息和費用
        uint256 interest = depositWithInterest > rental.depositAmount ? 
                          depositWithInterest - rental.depositAmount : 0;
        uint256 platformFee = (interest * platformFeePercentage) / PERCENTAGE_DENOMINATOR;
        
        // 根據爭議結果分配押金與利息
        if (_favorTenant) {
            // 如果有利於租客，將押金返還給租客
            if (platformFee > 0) {
                depositToken.safeTransfer(owner(), platformFee);
            }
            uint256 refundAmount = depositWithInterest - platformFee;
            depositToken.safeTransfer(rental.tenant, refundAmount);
            emit DepositRefunded(_rentalId, rental.tenant, refundAmount);
        } else {
            // 如果有利於房東，將押金釋放給房東
            if (platformFee > 0) {
                depositToken.safeTransfer(owner(), platformFee);
            }
            uint256 landlordAmount = depositWithInterest - platformFee;
            depositToken.safeTransfer(rental.landlord, landlordAmount);
            emit DepositReleased(_rentalId, rental.landlord, landlordAmount);
        }
        
        // 更新租賃狀態
        rental.isActive = false;
        rental.inDispute = false;
        
        // 燒掉租賃NFT
        rentalNFT.burn(_rentalId);
        
        emit DisputeResolved(_rentalId, _favorTenant);
    }
    
    /**
     * @dev 提前終止租賃並退還押金給租客
     * @param _rentalId 租賃ID
     */
    function terminateEarly(uint256 _rentalId) external nonReentrant {
        RentalInfo storage rental = rentals[_rentalId];
        
        require(rental.isActive, "Rental is not active");
        require(msg.sender == rental.landlord, "Only landlord can terminate early");
        require(!rental.inDispute, "Rental is in dispute");
        
        // 從利息管理器提取押金
        uint256 depositWithInterest = interestManager.getDepositWithInterest(rental.depositAmount);
        interestManager.withdraw(rental.depositAmount);
        
        // 計算利息
        uint256 interest = depositWithInterest > rental.depositAmount ? 
                          depositWithInterest - rental.depositAmount : 0;
        
        uint256 platformFee = (interest * platformFeePercentage) / PERCENTAGE_DENOMINATOR;
        uint256 tenantShare = (interest * rental.interestSharingPercentage) / PERCENTAGE_DENOMINATOR;
        uint256 refundAmount = rental.depositAmount + tenantShare;
        
        // 轉移資金
        if (platformFee > 0) {
            depositToken.safeTransfer(owner(), platformFee);
        }
        
        uint256 landlordInterest = interest - platformFee - tenantShare;
        if (landlordInterest > 0) {
            depositToken.safeTransfer(rental.landlord, landlordInterest);
            emit InterestWithdrawn(_rentalId, rental.landlord, landlordInterest);
        }
        
        // 將押金和租客利息份額返還給租客
        depositToken.safeTransfer(rental.tenant, refundAmount);
        
        // 更新租賃狀態
        rental.isActive = false;
        
        // 燒掉租賃NFT
        rentalNFT.burn(_rentalId);
        
        emit DepositRefunded(_rentalId, rental.tenant, refundAmount);
    }
    
    /**
     * @dev 獲取用戶參與的所有租賃ID
     * @param _user 用戶地址
     * @return 租賃ID數組
     */
    function getUserRentals(address _user) external view returns (uint256[] memory) {
        return userRentals[_user];
    }
    
    /**
     * @dev 更新平台費用百分比
     * @param _newFeePercentage 新的費用百分比
     */
    function updatePlatformFee(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 30, "Fee too high");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }
    
    /**
     * @dev 更新爭議期限
     * @param _newDisputePeriod 新的爭議期限（秒）
     */
    function updateDisputePeriod(uint256 _newDisputePeriod) external onlyOwner {
        require(_newDisputePeriod >= 1 days && _newDisputePeriod <= 30 days, "Invalid period");
        disputePeriod = _newDisputePeriod;
    }
    
    /**
     * @dev 設置用戶的HashKey Chain身份驗證狀態
     * @param _user 用戶地址
     * @param _verified 驗證狀態
     */
    function setHashKeyVerification(address _user, bool _verified) external onlyOwner {
        hashKeyVerified[_user] = _verified;
        emit HashKeyVerificationUpdated(_user, _verified);
    }
    
    /**
     * @dev 更新是否需要WorldID驗證
     * @param _required 是否需要
     */
    function setWorldIDRequired(bool _required) external onlyOwner {
        worldIDRequired = _required;
    }
    
    /**
     * @dev 更新WorldID驗證器合約地址
     * @param _newVerifier 新的驗證器地址
     */
    function updateWorldIDVerifier(address _newVerifier) external onlyOwner {
        worldIDVerifier = WorldIDVerifier(_newVerifier);
    }
    
    /**
     * @dev 更新Self Protocol合約地址
     * @param _newSelfProtocol 新的Self Protocol地址
     */
    function updateSelfProtocol(address _newSelfProtocol) external onlyOwner {
        selfProtocol = ISelfProtocol(_newSelfProtocol);
    }
    
    /**
     * @dev 更新租賃元數據URI
     * @param _rentalId 租賃ID
     * @param _metadataURI 新的元數據URI
     */
    function updateMetadataURI(uint256 _rentalId, string calldata _metadataURI) external {
        RentalInfo storage rental = rentals[_rentalId];
        require(rental.isActive, "Rental is not active");
        require(msg.sender == rental.tenant || msg.sender == rental.landlord || msg.sender == owner(), "Not authorized");
        
        rental.metadataURI = _metadataURI;
        rentalNFT.setTokenURI(_rentalId, _metadataURI);
        
        emit MetadataUpdated(_rentalId, _metadataURI);
    }
    
    /**
     * @dev 更新利息分享百分比
     * @param _rentalId 租賃ID
     * @param _newPercentage 新的百分比
     */
    function updateInterestSharing(uint256 _rentalId, uint256 _newPercentage) external {
        RentalInfo storage rental = rentals[_rentalId];
        require(rental.isActive, "Rental is not active");
        require(msg.sender == rental.landlord || msg.sender == owner(), "Not authorized");
        require(_newPercentage <= 100, "Percentage cannot exceed 100");
        
        rental.interestSharingPercentage = _newPercentage;
        
        emit InterestSharingUpdated(_rentalId, _newPercentage);
    }
    
    /**
     * @dev 緊急提款功能，僅限所有者
     * @param _token 代幣地址
     * @param _amount 提款金額
     */
    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(owner(), _amount);
    }
    
    /**
     * @dev 獲取租賃詳細信息
     * @param _rentalId 租賃ID
     * @return 租賃信息
     */
    function getRentalDetails(uint256 _rentalId) external view returns (RentalInfo memory) {
        return rentals[_rentalId];
    }
    
    /**
     * @dev 獲取租賃目前的押金價值（包含利息）
     * @param _rentalId 租賃ID
     * @return 當前押金價值
     */
    function getCurrentDepositValue(uint256 _rentalId) external view returns (uint256) {
        RentalInfo storage rental = rentals[_rentalId];
        require(rental.isActive, "Rental is not active");
        
        return interestManager.getDepositWithInterest(rental.depositAmount);
    }
    
    /**
     * @dev 檢查租賃是否處於活躍狀態
     * @param _rentalId 租賃ID
     * @return 是否活躍
     */
    function isRentalActive(uint256 _rentalId) external view returns (bool) {
        return rentals[_rentalId].isActive;
    }
    
    /**
     * @dev 批量獲取租賃狀態
     * @param _rentalIds 租賃ID數組
     * @return 活躍狀態數組
     */
    function batchGetRentalStatus(uint256[] calldata _rentalIds) external view returns (bool[] memory) {
        bool[] memory statuses = new bool[](_rentalIds.length);
        
        for (uint256 i = 0; i < _rentalIds.length; i++) {
            statuses[i] = rentals[_rentalIds[i]].isActive;
        }
        
        return statuses;
    }
}
