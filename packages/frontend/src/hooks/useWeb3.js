import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useConnect, useAccount, useDisconnect, useNetwork, useSwitchNetwork } from 'wagmi';
import { getContract } from '../utils/contracts';

const useWeb3 = () => {
  const [provider, setProvider] = useState(null);
  const [contracts, setContracts] = useState({});
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState(null);

  const { connectAsync, connectors } = useConnect();
  const { address, isConnected } = useAccount();
  const { disconnect } = useDisconnect();
  const { chain } = useNetwork();
  const { switchNetworkAsync, chains } = useSwitchNetwork();

  // 初始化provider和合約
  useEffect(() => {
    const initializeProvider = async () => {
      try {
        if (window.ethereum) {
          const newProvider = new ethers.BrowserProvider(window.ethereum);
          setProvider(newProvider);
        } else {
          setError('請安裝MetaMask或其他支持以太坊的瀏覽器插件');
        }
      } catch (err) {
        console.error('初始化provider失敗:', err);
        setError('連接錢包失敗，請檢查您的瀏覽器插件。');
      }
    };

    initializeProvider();
  }, []);

  // 連接錢包
  const connectWallet = async (connector = connectors[0]) => {
    try {
      setIsConnecting(true);
      setError(null);
      
      await connectAsync({ connector });
      
      return true;
    } catch (err) {
      console.error('連接錢包錯誤:', err);
      setError('連接錢包失敗，請重試。');
      return false;
    } finally {
      setIsConnecting(false);
    }
  };

  // 斷開錢包連接
  const disconnectWallet = () => {
    disconnect();
  };

  // 切換網絡
  const switchNetwork = async (chainId) => {
    try {
      await switchNetworkAsync(chainId);
      return true;
    } catch (err) {
      console.error('切換網絡錯誤:', err);
      setError('切換網絡失敗，請重試。');
      return false;
    }
  };

  // 初始化合約
  const initializeContracts = async (networkId) => {
    try {
      if (!provider) return false;
      
      const signer = await provider.getSigner();
      
      const rentalDepositContract = await getContract('RentalDeposit', provider, signer, networkId);
      const interestManagerContract = await getContract('InterestManager', provider, signer, networkId);
      const rentalNFTContract = await getContract('RentalNFT', provider, signer, networkId);
      const usdcContract = await getContract('USDC', provider, signer, networkId);
      
      setContracts({
        rentalDeposit: rentalDepositContract,
        interestManager: interestManagerContract,
        rentalNFT: rentalNFTContract,
        usdc: usdcContract
      });
      
      return true;
    } catch (err) {
      console.error('初始化合約錯誤:', err);
      setError('初始化合約失敗，請確保您連接到正確的網絡。');
      return false;
    }
  };

  return {
    provider,
    contracts,
    address,
    isConnected,
    isConnecting,
    error,
    connectWallet,
    disconnectWallet,
    switchNetwork,
    initializeContracts,
    chain,
    supportedChains: chains
  };
};

export default useWeb3;
