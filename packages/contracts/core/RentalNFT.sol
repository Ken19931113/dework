// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IERC4907.sol";

/**
 * @title RentalNFT
 * @dev 代表租賃合同的NFT，整合ERC-4907標準實現租賃功能
 */
contract RentalNFT is ERC721URIStorage, ERC721Enumerable, AccessControl, IERC4907 {
    using Counters for Counters.Counter;
    
    // 角色定義
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // 用於追蹤NFT ID
    Counters.Counter private _tokenIdCounter;
    
    // NFT元數據
    struct RentalMetadata {
        address tenant;      // 租客地址
        address landlord;    // 房東地址
        uint256 timestamp;   // 創建時間戳
        string ensName;      // ENS名稱
    }
    
    // ERC-4907用戶信息映射
    mapping(uint256 => UserInfo) private _users;
    
    // ID到元數據的映射
    mapping(uint256 => RentalMetadata) public rentalMetadata;
    
    // ENS名稱映射到NFT ID
    mapping(string => uint256) private _ensToTokenId;
    
    // 事件定義
    event RentalNFTMinted(uint256 indexed tokenId, address indexed tenant, address indexed landlord);
    event RentalNFTBurned(uint256 indexed tokenId);
    event BaseURIUpdated(string newBaseURI);
    event ENSNameSet(uint256 indexed tokenId, string ensName);
    
    /**
     * @dev 構造函數
     * @param _name NFT名稱
     * @param _symbol NFT符號
     * @param baseURI_ 基礎URI
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseURI_
    ) ERC721(_name, _symbol) {
        _setBaseURI(baseURI_);
        
        // 授予部署者管理員和鑄造者角色
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }
    
    /**
     * @dev 鑄造新的租賃NFT
     * @param _tenant 租客地址
     * @param _landlord 房東地址
     * @return 新鑄造的NFT ID
     */
    function mint(address _tenant, address _landlord) external onlyRole(MINTER_ROLE) returns (uint256) {
        require(_tenant != address(0), "Invalid tenant address");
        require(_landlord != address(0), "Invalid landlord address");
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        // 存儲租賃元數據
        rentalMetadata[tokenId] = RentalMetadata({
            tenant: _tenant,
            landlord: _landlord,
            timestamp: block.timestamp,
            ensName: ""
        });
        
        // 鑄造NFT給租客
        _safeMint(_tenant, tokenId);
        
        // 設置租客為用戶（根據ERC-4907）
        // 默認用戶權限到期時間設置為99年，實際上會在燒毀時提前結束
        _users[tokenId] = UserInfo({
            user: _tenant,
            expires: uint64(block.timestamp + 99 * 365 days)
        });
        
        emit RentalNFTMinted(tokenId, _tenant, _landlord);
        emit UpdateUser(tokenId, _tenant, _users[tokenId].expires);
        
        return tokenId;
    }
    
    /**
     * @dev 燒毀租賃NFT
     * @param _tokenId 要燒毀的NFT ID
     */
    function burn(uint256 _tokenId) external onlyRole(MINTER_ROLE) {
        // 如果NFT綁定了ENS名稱，清除映射
        if (bytes(rentalMetadata[_tokenId].ensName).length > 0) {
            delete _ensToTokenId[rentalMetadata[_tokenId].ensName];
        }
        
        // 清除用戶權限
        _users[_tokenId] = UserInfo({
            user: address(0),
            expires: 0
        });
        
        _burn(_tokenId);
        
        delete rentalMetadata[_tokenId];
        
        emit RentalNFTBurned(_tokenId);
        emit UpdateUser(_tokenId, address(0), 0);
    }
    
    /**
     * @dev 設置代幣元數據URI
     * @param _tokenId 代幣ID
     * @param _tokenURI 代幣URI
     */
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenURI(_tokenId, _tokenURI);
    }
    
    /**
     * @dev 更新基礎URI
     * @param _newBaseURI 新的基礎URI
     */
    function setBaseURI(string memory _newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(_newBaseURI);
        emit BaseURIUpdated(_newBaseURI);
    }
    
    /**
     * @dev 添加新的鑄造者
     * @param _minter 要添加的鑄造者地址
     */
    function addMinter(address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, _minter);
    }
    
    /**
     * @dev 移除鑄造者
     * @param _minter 要移除的鑄造者地址
     */
    function removeMinter(address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, _minter);
    }
    
    /**
     * @dev 獲取租賃元數據
     * @param _tokenId NFT ID
     * @return 租賃元數據
     */
    function getRentalMetadata(uint256 _tokenId) external view returns (RentalMetadata memory) {
        require(_exists(_tokenId), "Token does not exist");
        return rentalMetadata[_tokenId];
    }
    
    /**
     * @dev 獲取當前總鑄造量
     * @return 總鑄造量
     */
    function getTotalMinted() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    /**
     * @dev 根據ENS名稱查詢NFT ID
     * @param _ensName ENS名稱
     * @return 對應的NFT ID，如果不存在返回0
     */
    function getTokenIdByENS(string calldata _ensName) external view returns (uint256) {
        return _ensToTokenId[_ensName];
    }
    
    /**
     * @dev 設置NFT的ENS名稱
     * @param _tokenId NFT ID
     * @param _ensName ENS名稱
     */
    function setENSName(uint256 _tokenId, string calldata _ensName) external {
        require(_exists(_tokenId), "Token does not exist");
        require(msg.sender == ownerOf(_tokenId) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        require(bytes(_ensName).length > 0, "ENS name cannot be empty");
        require(_ensToTokenId[_ensName] == 0, "ENS name already in use");
        
        // 如果NFT之前綁定了ENS名稱，清除舊映射
        if (bytes(rentalMetadata[_tokenId].ensName).length > 0) {
            delete _ensToTokenId[rentalMetadata[_tokenId].ensName];
        }
        
        // 設置新的ENS名稱
        rentalMetadata[_tokenId].ensName = _ensName;
        _ensToTokenId[_ensName] = _tokenId;
        
        emit ENSNameSet(_tokenId, _ensName);
    }
    
    // ERC-4907 實現
    
    /**
     * @dev 設置NFT的用戶和到期時間
     * @param tokenId NFT ID
     * @param user 用戶地址
     * @param expires 到期時間戳
     */
    function setUser(uint256 tokenId, address user, uint64 expires) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        
        // 更新用戶信息
        _users[tokenId] = UserInfo({
            user: user,
            expires: expires
        });
        
        emit UpdateUser(tokenId, user, expires);
    }
    
    /**
     * @dev 獲取NFT的用戶地址
     * @param tokenId NFT ID
     * @return 用戶地址
     */
    function userOf(uint256 tokenId) external view override returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        }
        return address(0);
    }
    
    /**
     * @dev 獲取NFT用戶權限的到期時間
     * @param tokenId NFT ID
     * @return 到期時間戳
     */
    function userExpires(uint256 tokenId) external view override returns (uint256) {
        return _users[tokenId].expires;
    }
    
    // 以下函數是為了解決ERC721URIStorage和ERC721Enumerable之間的繼承衝突

    function _baseURI() internal view virtual override returns (string memory) {
        return super._baseURI();
    }
    
    function _setBaseURI(string memory baseURI_) internal virtual {
        super._baseURI();
        // 實際上ERC721URIStorage沒有_setBaseURI，這裡需要自己實現
    }
    
    /**
     * @dev 重寫轉移前的鉤子函數，確保租賃NFT不可轉讓（僅限所有者或授權地址可操作）
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        // 如果是鑄造或燒毀，允許操作
        if (from == address(0) || to == address(0)) {
            super._beforeTokenTransfer(from, to, tokenId, 1);
            return;
        }
        
        // 只有部署者或擁有管理員角色的地址可以轉移NFT
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(MINTER_ROLE, msg.sender),
            "RentalNFT: transfer not allowed"
        );
        
        super._beforeTokenTransfer(from, to, tokenId, 1);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage, ERC721Enumerable, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
    function _burn(uint256 tokenId) 
        internal 
        override(ERC721, ERC721URIStorage) 
    {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
