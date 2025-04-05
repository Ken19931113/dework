// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IRentalNFT
 * @dev 租賃NFT接口
 */
interface IRentalNFT {
    /**
     * @dev 租賃元數據結構
     */
    struct RentalMetadata {
        address tenant;      // 租客地址
        address landlord;    // 房東地址
        uint256 timestamp;   // 創建時間戳
    }
    
    /**
     * @dev 鑄造新的租賃NFT
     * @param _tenant 租客地址
     * @param _landlord 房東地址
     * @return 新鑄造的NFT ID
     */
    function mint(address _tenant, address _landlord) external returns (uint256);
    
    /**
     * @dev 燒毀租賃NFT
     * @param _tokenId 要燒毀的NFT ID
     */
    function burn(uint256 _tokenId) external;
    
    /**
     * @dev 獲取租賃元數據
     * @param _tokenId NFT ID
     * @return 租賃元數據
     */
    function getRentalMetadata(uint256 _tokenId) external view returns (RentalMetadata memory);
    
    /**
     * @dev 設置代幣元數據URI
     * @param _tokenId 代幣ID
     * @param _tokenURI 代幣URI
     */
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external;
    
    /**
     * @dev 添加新的鑄造者
     * @param _minter 要添加的鑄造者地址
     */
    function addMinter(address _minter) external;
    
    /**
     * @dev 獲取當前總鑄造量
     * @return 總鑄造量
     */
    function getTotalMinted() external view returns (uint256);
}
