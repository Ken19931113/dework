import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import useWeb3 from '../hooks/useWeb3';
import { getNetworkName } from '../utils/contracts';

const Connect = () => {
  const navigate = useNavigate();
  const { 
    connectWallet, 
    isConnected, 
    isConnecting, 
    error,
    chain,
    supportedChains,
    switchNetwork
  } = useWeb3();
  
  const [connectError, setConnectError] = useState(null);
  
  // 支持的網絡
  const targetNetworks = [
    { id: 421614, name: 'Arbitrum Sepolia' },
    { id: 42161, name: 'Arbitrum One' },
    { id: 1506, name: 'HashKey Chain' },
    { id: 31337, name: 'Hardhat Local' } // 只在開發時顯示
  ];
  
  // 如果已連接錢包，跳轉到儀表板
  useEffect(() => {
    if (isConnected) {
      navigate('/dashboard');
    }
  }, [isConnected, navigate]);
  
  // 連接錢包
  const handleConnect = async () => {
    setConnectError(null);
    
    try {
      const success = await connectWallet();
      if (success) {
        navigate('/dashboard');
      }
    } catch (err) {
      console.error('連接錯誤:', err);
      setConnectError('連接錢包失敗，請重試。');
    }
  };
  
  // 切換網絡
  const handleSwitchNetwork = async (chainId) => {
    setConnectError(null);
    
    try {
      await switchNetwork(chainId);
    } catch (err) {
      console.error('切換網絡錯誤:', err);
      setConnectError(`切換到 ${getNetworkName(chainId)} 失敗，請在錢包中手動切換。`);
    }
  };

  return (
    <div className="container mx-auto px-4 py-12">
      <div className="max-w-md mx-auto bg-white rounded-xl shadow-md overflow-hidden">
        <div className="p-8">
          <div className="flex justify-center mb-6">
            <div className="bg-blue-100 p-4 rounded-full">
              <svg xmlns="http://www.w3.org/2000/svg" className="h-12 w-12 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2z" />
              </svg>
            </div>
          </div>
          
          <h2 className="text-2xl font-bold text-center mb-4">連接您的錢包</h2>
          
          <p className="text-gray-600 mb-6 text-center">
            連接您的錢包以使用DeWork押金代管平台。
          </p>
          
          {error || connectError ? (
            <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
              {error || connectError}
            </div>
          ) : null}
          
          <button
            onClick={handleConnect}
            disabled={isConnecting}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-3 px-4 rounded-lg mb-4 flex justify-center items-center"
          >
            {isConnecting ? (
              <>
                <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                連接中...
              </>
            ) : (
              '連接MetaMask'
            )}
          </button>
          
          {/* 支持的網絡 */}
          <div className="mt-8">
            <h3 className="text-lg font-medium mb-3">支持的網絡</h3>
            
            <div className="space-y-3">
              {targetNetworks.map((network) => (
                <button
                  key={network.id}
                  onClick={() => handleSwitchNetwork(network.id)}
                  className={`w-full px-4 py-3 border rounded-lg flex justify-between items-center hover:bg-gray-50 ${
                    chain?.id === network.id ? 'border-blue-500 bg-blue-50' : 'border-gray-300'
                  }`}
                >
                  <span>{network.name}</span>
                  {chain?.id === network.id && (
                    <span className="bg-blue-500 text-white text-xs px-2 py-1 rounded">已連接</span>
                  )}
                </button>
              ))}
            </div>
          </div>
          
          <div className="mt-8 text-center text-sm text-gray-500">
            <p>您的資金安全是我們的第一優先考量。</p>
            <p>DeWork平台不會存儲您的私鑰或請求不必要的權限。</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Connect;
