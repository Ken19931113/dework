import React from 'react';
import { Link } from 'react-router-dom';
import { formatAPY, formatAmount } from '../utils/helpers';
import useWeb3 from '../hooks/useWeb3';

const Home = () => {
  const { isConnected } = useWeb3();
  
  const features = [
    {
      title: '押金安全透明',
      description: '押金存儲於智能合約中，保證租客資金安全',
      icon: '🔒'
    },
    {
      title: '利息持續生成',
      description: '押金自動投入DeFi協議，為房東和平台創造額外收益',
      icon: '💰'
    },
    {
      title: '爭議保障',
      description: '租客可提出爭議，確保押金公正處理',
      icon: '⚖️'
    },
    {
      title: '無需信任第三方',
      description: '基於區塊鏈技術，去除中間人風險',
      icon: '🔗'
    }
  ];
  
  const stats = [
    { label: '已存押金總額', value: '$2,500,000' },
    { label: '已生成利息', value: '$125,000' },
    { label: '當前平均年化收益率', value: '5.2%' },
    { label: '用戶數量', value: '850+' }
  ];

  return (
    <div className="container mx-auto px-4 py-8">
      {/* 主要橫幅 */}
      <div className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-xl shadow-lg p-8 mb-12 text-white">
        <div className="max-w-3xl mx-auto text-center">
          <h1 className="text-4xl font-bold mb-4">Web3 押金代管平台</h1>
          <p className="text-xl mb-8">
            通過智能合約與DeFi利率市場管理商業空間租賃押金，
            提供租客保障、房東獲益和平台穩定收入。
          </p>
          <div className="flex justify-center space-x-4">
            {isConnected ? (
              <Link 
                to="/dashboard" 
                className="bg-white text-purple-600 hover:bg-gray-100 px-6 py-3 rounded-lg font-medium shadow-md"
              >
                進入儀表板
              </Link>
            ) : (
              <Link 
                to="/connect" 
                className="bg-white text-purple-600 hover:bg-gray-100 px-6 py-3 rounded-lg font-medium shadow-md"
              >
                連接錢包
              </Link>
            )}
            <Link 
              to="/how-it-works" 
              className="bg-transparent border-2 border-white hover:bg-white hover:text-purple-600 px-6 py-3 rounded-lg font-medium"
            >
              了解更多
            </Link>
          </div>
        </div>
      </div>
      
      {/* 主要特點 */}
      <div className="mb-16">
        <h2 className="text-3xl font-bold text-center mb-12">平台特點</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {features.map((feature, index) => (
            <div 
              key={index} 
              className="bg-white p-6 rounded-xl shadow-md hover:shadow-lg transition-shadow"
            >
              <div className="text-4xl mb-4">{feature.icon}</div>
              <h3 className="text-xl font-semibold mb-2">{feature.title}</h3>
              <p className="text-gray-600">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
      
      {/* 平台統計 */}
      <div className="bg-gray-50 rounded-xl p-8 mb-16">
        <h2 className="text-3xl font-bold text-center mb-8">平台數據</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {stats.map((stat, index) => (
            <div key={index} className="text-center">
              <p className="text-3xl font-bold text-blue-600">{stat.value}</p>
              <p className="text-gray-600">{stat.label}</p>
            </div>
          ))}
        </div>
      </div>
      
      {/* 使用流程 */}
      <div className="mb-16">
        <h2 className="text-3xl font-bold text-center mb-8">如何使用</h2>
        <div className="max-w-4xl mx-auto">
          <div className="flex flex-col md:flex-row items-center mb-12">
            <div className="md:w-1/2 p-4">
              <h3 className="text-2xl font-semibold mb-2">1. 房東創建租賃合約</h3>
              <p className="text-gray-600">
                房東在平台上創建租賃合約，設定押金金額、租期等條件。
              </p>
            </div>
            <div className="md:w-1/2 p-4 flex justify-center">
              <div className="bg-blue-100 rounded-full p-6">
                <span className="text-4xl">📝</span>
              </div>
            </div>
          </div>
          
          <div className="flex flex-col md:flex-row-reverse items-center mb-12">
            <div className="md:w-1/2 p-4">
              <h3 className="text-2xl font-semibold mb-2">2. 租客支付押金</h3>
              <p className="text-gray-600">
                租客將押金支付到智能合約中，獲得NFT租賃憑證。
              </p>
            </div>
            <div className="md:w-1/2 p-4 flex justify-center">
              <div className="bg-green-100 rounded-full p-6">
                <span className="text-4xl">💸</span>
              </div>
            </div>
          </div>
          
          <div className="flex flex-col md:flex-row items-center mb-12">
            <div className="md:w-1/2 p-4">
              <h3 className="text-2xl font-semibold mb-2">3. 押金產生利息</h3>
              <p className="text-gray-600">
                押金資金自動投入DeFi協議，持續產生利息收益。
              </p>
            </div>
            <div className="md:w-1/2 p-4 flex justify-center">
              <div className="bg-yellow-100 rounded-full p-6">
                <span className="text-4xl">📈</span>
              </div>
            </div>
          </div>
          
          <div className="flex flex-col md:flex-row-reverse items-center">
            <div className="md:w-1/2 p-4">
              <h3 className="text-2xl font-semibold mb-2">4. 租期結束，押金釋放</h3>
              <p className="text-gray-600">
                租期結束後，押金及利息按比例分配給房東和平台。
              </p>
            </div>
            <div className="md:w-1/2 p-4 flex justify-center">
              <div className="bg-purple-100 rounded-full p-6">
                <span className="text-4xl">🔄</span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      {/* 呼籲行動 */}
      <div className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-xl shadow-lg p-8 text-white text-center">
        <h2 className="text-3xl font-bold mb-4">立即體驗Web3押金管理</h2>
        <p className="text-xl mb-8 max-w-2xl mx-auto">
          告別傳統押金模式，享受更安全、更透明、更有收益的押金管理方式。
        </p>
        <div className="flex justify-center">
          {isConnected ? (
            <Link 
              to="/dashboard" 
              className="bg-white text-purple-600 hover:bg-gray-100 px-8 py-4 rounded-lg font-medium shadow-md text-lg"
            >
              進入儀表板
            </Link>
          ) : (
            <Link 
              to="/connect" 
              className="bg-white text-purple-600 hover:bg-gray-100 px-8 py-4 rounded-lg font-medium shadow-md text-lg"
            >
              開始使用
            </Link>
          )}
        </div>
      </div>
    </div>
  );
};

export default Home;
