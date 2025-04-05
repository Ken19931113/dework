import React from 'react';
import { Link } from 'react-router-dom';

const NotFound = () => {
  return (
    <div className="container mx-auto px-4 py-16">
      <div className="max-w-lg mx-auto text-center">
        <div className="text-6xl font-bold text-blue-600 mb-6">404</div>
        <h1 className="text-3xl font-bold mb-4">頁面未找到</h1>
        <p className="text-gray-600 mb-8">
          很抱歉，您請求的頁面不存在或已被移動。
        </p>
        <Link
          to="/"
          className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-3 px-6 rounded-lg"
        >
          返回首頁
        </Link>
      </div>
    </div>
  );
};

export default NotFound;
