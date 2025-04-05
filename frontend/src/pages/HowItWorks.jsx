import React from 'react';
import { Link } from 'react-router-dom';

const HowItWorks = () => {
  const steps = [
    {
      title: '連接您的錢包',
      description: '使用MetaMask或其他Web3錢包連接到平台，確保您已經在支持的網絡上（Arbitrum或HashKey Chain）。',
      icon: '🔌'
    },
    {
      title: '創建租賃合約',
      description: '作為租客，您可以創建新的租賃合約，指定房東地址、押金金額和租期。',
      icon: '📝'
    },
    {
      title: '支付押金',
      description: '押金以USDC支付，並存入智能合約。您將收到一個NFT作為租賃憑證。',
      icon: '💸'
    },
    {
      title: '押金產生利息',
      description: '您的押金會自動投入DeFi協議產生利息，為房東和平台創造額外收益。',
      icon: '📈'
    },
    {
      title: '租期結束',
      description: '租期結束後，房東可以結束租賃，押金和利息將轉移給房東，平台收取一小部分利息作為服務費。',
      icon: '🔄'
    },
    {
      title: '爭議解決',
      description: '如有爭議，租客可以提出異議，凍結押金釋放，等待平台仲裁。',
      icon: '⚖️'
    }
  ];
  
  const faqs = [
    {
      question: '支持哪些代幣作為押金？',
      answer: '目前，我們支持USDC作為押金代幣。這是一種與美元掛鉤的穩定幣，可以最大限度地減少價格波動的風險。'
    },
    {
      question: '押金的利息如何分配？',
      answer: '押金產生的利息將在租期結束時分配，其中90%歸房東所有，10%歸平台所有作為服務費。'
    },
    {
      question: '如果我想提前終止租賃怎麼辦？',
      answer: '作為房東，您可以選擇提前終止租賃，這將把押金全額返還給租客。這通常用於雙方同意提前終止租約的情況。'
    },
    {
      question: '爭議如何解決？',
      answer: '租客可以在租期結束後的爭議期間內提出爭議。平台管理員將審查爭議並做出決定，將押金分配給適當的一方。'
    },
    {
      question: '我需要支付什麼費用？',
      answer: '平台只從押金產生的利息中收取10%的費用。沒有其他隱藏費用或月費。'
    },
    {
      question: '支持哪些區塊鏈網絡？',
      answer: '目前，我們支持Arbitrum和HashKey Chain網絡，這些網絡提供低費用和快速交易。'
    }
  ];

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-12">
          <h1 className="text-3xl font-bold mb-4">如何使用DeWork押金代管平台</h1>
          <p className="text-xl text-gray-600">
            了解我們的平台如何通過區塊鏈技術革新租賃押金管理
          </p>
        </div>
        
        {/* 主要流程 */}
        <div className="mb-16">
          <div className="space-y-12">
            {steps.map((step, index) => (
              <div key={index} className="flex items-start">
                <div className="flex-shrink-0 bg-blue-100 rounded-full p-4 mr-6">
                  <span className="text-3xl">{step.icon}</span>
                </div>
                <div>
                  <h2 className="text-xl font-bold mb-2">
                    {index + 1}. {step.title}
                  </h2>
                  <p className="text-gray-600">{step.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
        
        {/* 關鍵優勢 */}
        <div className="bg-blue-50 rounded-xl p-8 mb-16">
          <h2 className="text-2xl font-bold mb-6 text-center">為什麼選擇DeWork平台？</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white p-6 rounded-lg shadow-sm">
              <div className="text-blue-600 text-xl font-bold mb-2">安全透明</div>
              <p className="text-gray-600">
                所有交易都記錄在區塊鏈上，無法篡改，確保資金安全和流程透明。
              </p>
            </div>
            
            <div className="bg-white p-6 rounded-lg shadow-sm">
              <div className="text-blue-600 text-xl font-bold mb-2">利息收益</div>
              <p className="text-gray-600">
                通過DeFi協議生成收益，讓閒置的押金資金創造價值，提高資金效率。
              </p>
            </div>
            
            <div className="bg-white p-6 rounded-lg shadow-sm">
              <div className="text-blue-600 text-xl font-bold mb-2">公正仲裁</div>
              <p className="text-gray-600">
                爭議解決機制確保押金的公正處理，保護租客和房東的權益。
              </p>
            </div>
          </div>
        </div>
        
        {/* 常見問題 */}
        <div className="mb-16">
          <h2 className="text-2xl font-bold mb-8 text-center">常見問題</h2>
          
          <div className="space-y-6">
            {faqs.map((faq, index) => (
              <div key={index} className="border-b border-gray-200 pb-6">
                <h3 className="text-lg font-semibold mb-2">{faq.question}</h3>
                <p className="text-gray-600">{faq.answer}</p>
              </div>
            ))}
          </div>
        </div>
        
        {/* 呼籲行動 */}
        <div className="text-center">
          <h2 className="text-2xl font-bold mb-4">準備好開始使用了嗎？</h2>
          <p className="text-gray-600 mb-6">
            連接您的錢包，體驗更安全、更透明、更有收益的押金管理方式。
          </p>
          <div className="flex justify-center space-x-4">
            <Link
              to="/connect"
              className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-3 px-6 rounded-lg"
            >
              連接錢包
            </Link>
            <Link
              to="/dashboard"
              className="bg-gray-100 hover:bg-gray-200 text-gray-800 font-medium py-3 px-6 rounded-lg"
            >
              探索儀表板
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default HowItWorks;
