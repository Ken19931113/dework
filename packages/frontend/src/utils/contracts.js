import { ethers } from 'ethers';
import RentalDepositABI from '../abi/RentalDeposit.json';
import InterestManagerABI from '../abi/InterestManager.json';
import RentalNFTABI from '../abi/RentalNFT.json';
import USDCABI from '../abi/USDC.json';

// 合約地址（按網絡ID）
const CONTRACT_ADDRESSES = {
  // Hardhat本地開發
  31337: {
    RentalDeposit: '',  // 部署後填寫
    InterestManager: '',
    RentalNFT: '',
    USDC: ''
  },
  // Arbitrum Sepolia 測試網
  421614: {
    RentalDeposit: '',  // 部署後填寫
    InterestManager: '',
    RentalNFT: '',
    USDC: '0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d'  // Arbitrum Sepolia上的USDC
  },
  // Arbitrum
  42161: {
    RentalDeposit: '',  // 部署後填寫
    InterestManager: '',
    RentalNFT: '',
    USDC: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831'  // Arbitrum上的USDC
  },
  // HashKey Chain
  1506: {
    RentalDeposit: '',  // 部署後填寫
    InterestManager: '',
    RentalNFT: '',
    USDC: '0x4C84560A1081774103edBffc2DeA1B643839eA66'  // HashKey上的USDT（作為示例）
  }
};

// 合約ABI
const CONTRACT_ABIS = {
  RentalDeposit: RentalDepositABI,
  InterestManager: InterestManagerABI,
  RentalNFT: RentalNFTABI,
  USDC: USDCABI
};

// 獲取合約實例
export const getContract = async (contractName, provider, signer, networkId = 31337) => {
  try {
    // 獲取合約地址
    const address = CONTRACT_ADDRESSES[networkId]?.[contractName];
    if (!address) {
      console.error(`合約 ${contractName} 在網絡 ${networkId} 上不存在`);
      return null;
    }
    
    // 獲取合約ABI
    const abi = CONTRACT_ABIS[contractName];
    if (!abi) {
      console.error(`找不到合約 ${contractName} 的ABI`);
      return null;
    }
    
    // 創建合約實例
    const contract = new ethers.Contract(
      address,
      abi,
      signer || provider
    );
    
    return contract;
  } catch (error) {
    console.error(`獲取合約 ${contractName} 實例失敗:`, error);
    return null;
  }
};

// 更新合約地址
export const updateContractAddress = (networkId, contractName, address) => {
  if (!CONTRACT_ADDRESSES[networkId]) {
    CONTRACT_ADDRESSES[networkId] = {};
  }
  
  CONTRACT_ADDRESSES[networkId][contractName] = address;
};

// 獲取網絡名稱
export const getNetworkName = (networkId) => {
  const networks = {
    1: 'Ethereum Mainnet',
    5: 'Goerli Testnet',
    31337: 'Hardhat Local',
    42161: 'Arbitrum One',
    421614: 'Arbitrum Sepolia',
    1506: 'HashKey Chain'
  };
  
  return networks[networkId] || `未知網絡 (${networkId})`;
};

// 從部署文件中加載合約地址
export const loadContractAddresses = async (networkId) => {
  try {
    const response = await fetch(`/deployments/${networkId}_deployment.json`);
    if (!response.ok) {
      throw new Error(`無法載入網絡 ${networkId} 的部署信息`);
    }
    
    const deploymentInfo = await response.json();
    
    updateContractAddress(networkId, 'RentalDeposit', deploymentInfo.rentalDeposit);
    updateContractAddress(networkId, 'InterestManager', deploymentInfo.interestManager);
    updateContractAddress(networkId, 'RentalNFT', deploymentInfo.rentalNFT);
    
    if (deploymentInfo.stablecoin) {
      updateContractAddress(networkId, 'USDC', deploymentInfo.stablecoin);
    }
    
    return true;
  } catch (error) {
    console.error('載入合約地址失敗:', error);
    return false;
  }
};
