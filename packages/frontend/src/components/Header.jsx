import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { formatAddress, getNetworkName } from '../utils/helpers';
import useWeb3 from '../hooks/useWeb3';

const Header = () => {
  const location = useLocation();
  const { isConnected, address, connectWallet, disconnectWallet, chain } = useWeb3();
  const [menuOpen, setMenuOpen] = useState(false);
  
  // 導航鏈接
  const navLinks = [
    { name: '首頁', path: '/' },
    { name: '儀表板', path: '/dashboard' },
    { name: '創建租賃', path: '/create-rental' },
    { name: '如何使用', path: '/how-it-works' }
  ];
  
  // 檢查鏈接是否活躍
  const isActive = (path) => {
    if (path === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(path);
  };
  
  // 切換菜單
  const toggleMenu = () => {
    setMenuOpen(!menuOpen);
  };
  
  // 關閉菜單
  const closeMenu = () => {
    setMenuOpen(false);
  };

  return (
    <header className="bg-white shadow-md">
      <div className="container mx-auto px-4">
        <div className="flex justify-between items-center py-4">
          {/* Logo */}
          <Link to="/" className="flex items-center">
            <span className="text-2xl font-bold text-blue-600">DeWork</span>
          </Link>
          
          {/* 桌面導航 */}
          <nav className="hidden md:flex space-x-8">
            {navLinks.map((link) => (
              <Link
                key={link.path}
                to={link.path}
                className={`text-sm font-medium ${
                  isActive(link.path)
                    ? 'text-blue-600'
                    : 'text-gray-700 hover:text-blue-600'
                }`}
              >
                {link.name}
              </Link>
            ))}
          </nav>
          
          {/* 錢包連接/用戶信息 */}
          <div className="hidden md:flex items-center space-x-4">
            {isConnected ? (
              <div className="flex items-center">
                {chain && (
                  <span className="text-xs bg-gray-100 py-1 px-2 rounded mr-2">
                    {getNetworkName(chain.id)}
                  </span>
                )}
                <div className="relative group">
                  <button className="flex items-center space-x-2 bg-blue-50 hover:bg-blue-100 px-3 py-2 rounded-lg">
                    <span className="text-sm font-medium text-blue-700">
                      {formatAddress(address)}
                    </span>
                  </button>
                  
                  {/* 下拉菜單 */}
                  <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-20 hidden group-hover:block">
                    <Link
                      to="/dashboard"
                      className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                    >
                      儀表板
                    </Link>
                    <button
                      onClick={disconnectWallet}
                      className="block w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-gray-100"
                    >
                      斷開連接
                    </button>
                  </div>
                </div>
              </div>
            ) : (
              <button
                onClick={connectWallet}
                className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-lg text-sm"
              >
                連接錢包
              </button>
            )}
          </div>
          
          {/* 移動端菜單按鈕 */}
          <div className="md:hidden">
            <button
              onClick={toggleMenu}
              className="text-gray-500 hover:text-gray-700 focus:outline-none focus:text-gray-700"
            >
              <svg viewBox="0 0 24 24" className="h-6 w-6 fill-current">
                {menuOpen ? (
                  <path
                    fillRule="evenodd"
                    clipRule="evenodd"
                    d="M18.278 16.864a1 1 0 0 1-1.414 1.414l-4.829-4.828-4.828 4.828a1 1 0 0 1-1.414-1.414l4.828-4.829-4.828-4.828a1 1 0 0 1 1.414-1.414l4.829 4.828 4.828-4.828a1 1 0 1 1 1.414 1.414l-4.828 4.829 4.828 4.828z"
                  />
                ) : (
                  <path
                    fillRule="evenodd"
                    d="M4 5h16a1 1 0 0 1 0 2H4a1 1 0 1 1 0-2zm0 6h16a1 1 0 0 1 0 2H4a1 1 0 0 1 0-2zm0 6h16a1 1 0 0 1 0 2H4a1 1 0 0 1 0-2z"
                  />
                )}
              </svg>
            </button>
          </div>
        </div>
      </div>
      
      {/* 移動端導航 */}
      {menuOpen && (
        <div className="md:hidden bg-white border-t border-gray-200">
          <div className="container mx-auto px-4 py-3">
            <nav className="flex flex-col space-y-3">
              {navLinks.map((link) => (
                <Link
                  key={link.path}
                  to={link.path}
                  className={`py-2 px-3 rounded-md ${
                    isActive(link.path)
                      ? 'bg-blue-50 text-blue-600'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                  onClick={closeMenu}
                >
                  {link.name}
                </Link>
              ))}
              
              {/* 移動端錢包連接 */}
              {isConnected ? (
                <>
                  <div className="py-2 px-3">
                    <div className="flex items-center">
                      {chain && (
                        <span className="text-xs bg-gray-100 py-1 px-2 rounded mr-2">
                          {getNetworkName(chain.id)}
                        </span>
                      )}
                      <span className="text-sm font-medium">
                        {formatAddress(address)}
                      </span>
                    </div>
                  </div>
                  <button
                    onClick={disconnectWallet}
                    className="py-2 px-3 text-left text-red-600 hover:bg-gray-50 rounded-md"
                  >
                    斷開連接
                  </button>
                </>
              ) : (
                <button
                  onClick={connectWallet}
                  className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-3 rounded-md text-sm w-full"
                >
                  連接錢包
                </button>
              )}
            </nav>
          </div>
        </div>
      )}
    </header>
  );
};

export default Header;
