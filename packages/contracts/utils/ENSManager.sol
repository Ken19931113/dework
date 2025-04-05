// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IENSResolver.sol";
import "../core/RentalNFT.sol";

/**
 * @title ENSManager
 * @dev 管理租賃NFT的ENS名稱解析與綁定
 */
contract ENSManager is Ownable {
    // ENS相關
    address public ensRegistry;
    address public ensResolver;
    
    // 租賃NFT合約
    RentalNFT public rentalNFT;
    
    // 指定專用於租賃的ENS域名
    bytes32 public rentalNamespace;
    
    // 事件定義
    event ENSNameRegistered(uint256 indexed tokenId, string ensName, address indexed owner);
    event ENSNameReleased(uint256 indexed tokenId, string ensName);
    event NamespaceUpdated(bytes32 newNamespace);
    
    /**
     * @dev 構造函數
     * @param _rentalNFT 租賃NFT合約地址
     * @param _ensRegistry ENS註冊表地址
     * @param _ensResolver ENS解析器地址
     * @param _namespace 租賃域名的命名空間 (e.g., hash of "dework.eth")
     */
    constructor(
        address _rentalNFT,
        address _ensRegistry,
        address _ensResolver,
        bytes32 _namespace
    ) Ownable() {
        rentalNFT = RentalNFT(_rentalNFT);
        ensRegistry = _ensRegistry;
        ensResolver = _ensResolver;
        rentalNamespace = _namespace;
    }
    
    /**
     * @dev 註冊ENS名稱給租賃NFT
     * @param _tokenId NFT ID
     * @param _ensName ENS名稱 (不含域名部分，只有子域名)
     */
    function registerENSName(uint256 _tokenId, string calldata _ensName) external {
        require(rentalNFT.ownerOf(_tokenId) == msg.sender || msg.sender == owner(), "ENSManager: not authorized");
        
        // 創建完整的ENS節點
        bytes32 nameNode = _createNameNode(_ensName);
        
        // 使用ENS解析器設置地址
        IENSResolver(ensResolver).setAddr(nameNode, rentalNFT.ownerOf(_tokenId));
        
        // 在NFT中保存ENS名稱
        rentalNFT.setENSName(_tokenId, _ensName);
        
        emit ENSNameRegistered(_tokenId, _ensName, rentalNFT.ownerOf(_tokenId));
    }
    
    /**
     * @dev 釋放ENS名稱
     * @param _tokenId NFT ID
     */
    function releaseENSName(uint256 _tokenId) external {
        // 確保是NFT擁有者或合約擁有者
        require(
            rentalNFT.ownerOf(_tokenId) == msg.sender || msg.sender == owner(),
            "ENSManager: not authorized"
        );
        
        // 獲取與NFT關聯的ENS名稱
        string memory ensName = rentalNFT.getRentalMetadata(_tokenId).ensName;
        require(bytes(ensName).length > 0, "ENSManager: no ENS name associated");
        
        // 創建ENS節點
        bytes32 nameNode = _createNameNode(ensName);
        
        // 重置ENS記錄
        IENSResolver(ensResolver).setAddr(nameNode, address(0));
        
        // 清除NFT中的ENS名稱
        rentalNFT.setENSName(_tokenId, "");
        
        emit ENSNameReleased(_tokenId, ensName);
    }
    
    /**
     * @dev 通過ENS名稱獲取租賃NFT ID
     * @param _ensName ENS名稱
     * @return 對應的NFT ID
     */
    function getTokenIdByENSName(string calldata _ensName) external view returns (uint256) {
        return rentalNFT.getTokenIdByENS(_ensName);
    }
    
    /**
     * @dev 更新租賃命名空間
     * @param _newNamespace 新的命名空間節點
     */
    function updateNamespace(bytes32 _newNamespace) external onlyOwner {
        rentalNamespace = _newNamespace;
        emit NamespaceUpdated(_newNamespace);
    }
    
    /**
     * @dev 更新ENS註冊表地址
     * @param _newRegistry 新的ENS註冊表地址
     */
    function updateENSRegistry(address _newRegistry) external onlyOwner {
        ensRegistry = _newRegistry;
    }
    
    /**
     * @dev 更新ENS解析器地址
     * @param _newResolver 新的ENS解析器地址
     */
    function updateENSResolver(address _newResolver) external onlyOwner {
        ensResolver = _newResolver;
    }
    
    /**
     * @dev 創建子域名的命名空間節點
     * @param _subName 子域名
     * @return 對應的ENS節點
     */
    function _createNameNode(string memory _subName) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(rentalNamespace, keccak256(abi.encodePacked(_subName))));
    }
    
    /**
     * @dev 批量檢查ENS名稱是否可用
     * @param _ensNames ENS名稱數組
     * @return 可用性布爾數組
     */
    function checkENSNamesAvailability(string[] calldata _ensNames) external view returns (bool[] memory) {
        bool[] memory results = new bool[](_ensNames.length);
        
        for (uint256 i = 0; i < _ensNames.length; i++) {
            bytes32 nameNode = _createNameNode(_ensNames[i]);
            address currentAddress = IENSResolver(ensResolver).addr(nameNode);
            results[i] = (currentAddress == address(0));
        }
        
        return results;
    }
}
