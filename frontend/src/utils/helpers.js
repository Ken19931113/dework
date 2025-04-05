import { ethers } from 'ethers';

// 格式化錢包地址，顯示前幾位和後幾位
export const formatAddress = (address, start = 6, end = 4) => {
  if (!address || address.length < (start + end)) return address;
  return `${address.substring(0, start)}...${address.substring(address.length - end)}`;
};

// 格式化金額，轉換為更易讀的形式
export const formatAmount = (amount, decimals = 6, displayDecimals = 2) => {
  if (!amount) return '0';
  
  try {
    const formattedAmount = ethers.formatUnits(amount, decimals);
    const numericAmount = parseFloat(formattedAmount);
    return numericAmount.toLocaleString(undefined, {
      minimumFractionDigits: displayDecimals,
      maximumFractionDigits: displayDecimals
    });
  } catch (error) {
    console.error('格式化金額錯誤:', error);
    return '0';
  }
};

// 解析金額，轉換為區塊鏈上使用的格式
export const parseAmount = (amount, decimals = 6) => {
  if (!amount) return '0';
  
  try {
    // 移除所有非數字和小數點字符
    const cleanAmount = amount.toString().replace(/[^\d.]/g, '');
    return ethers.parseUnits(cleanAmount, decimals);
  } catch (error) {
    console.error('解析金額錯誤:', error);
    return '0';
  }
};

// 格式化日期
export const formatDate = (timestamp) => {
  if (!timestamp) return '';
  
  const date = new Date(Number(timestamp) * 1000);
  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
};

// 計算剩餘時間（天/小時/分鐘）
export const calculateTimeRemaining = (targetTimestamp) => {
  if (!targetTimestamp) return { days: 0, hours: 0, minutes: 0 };
  
  const now = Math.floor(Date.now() / 1000);
  const targetTime = Number(targetTimestamp);
  
  if (now >= targetTime) return { days: 0, hours: 0, minutes: 0 };
  
  const secondsRemaining = targetTime - now;
  const days = Math.floor(secondsRemaining / 86400);
  const hours = Math.floor((secondsRemaining % 86400) / 3600);
  const minutes = Math.floor((secondsRemaining % 3600) / 60);
  
  return { days, hours, minutes };
};

// 格式化剩餘時間為易讀字符串
export const formatTimeRemaining = (targetTimestamp) => {
  const { days, hours, minutes } = calculateTimeRemaining(targetTimestamp);
  
  if (days > 0) {
    return `${days}天 ${hours}小時`;
  } else if (hours > 0) {
    return `${hours}小時 ${minutes}分鐘`;
  } else if (minutes > 0) {
    return `${minutes}分鐘`;
  } else {
    return '時間已到';
  }
};

// 格式化年化收益率
export const formatAPY = (apy) => {
  if (!apy) return '0%';
  
  // APY通常以10000為基數，例如500表示5%
  const apyValue = (Number(apy) / 100).toFixed(2);
  return `${apyValue}%`;
};

// 狀態描述轉換
export const getRentalStatusText = (rental) => {
  if (!rental) return '未知狀態';
  
  const now = Math.floor(Date.now() / 1000);
  
  if (!rental.isActive) return '已完成';
  if (rental.inDispute) return '爭議中';
  if (now < rental.endTime) return '進行中';
  if (now < rental.releaseTime) return '等待押金釋放';
  return '可以結束';
};

// 獲取交易查看鏈接
export const getExplorerUrl = (txHash, networkId) => {
  const explorers = {
    1: 'https://etherscan.io',
    5: 'https://goerli.etherscan.io',
    42161: 'https://arbiscan.io',
    421614: 'https://sepolia.arbiscan.io',
    1506: 'https://explorer.hashkey.com'
  };
  
  const baseUrl = explorers[networkId] || 'https://etherscan.io';
  return `${baseUrl}/tx/${txHash}`;
};

// 睡眠函數
export const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// 等待交易確認
export const waitForTransaction = async (provider, txHash, confirmations = 1) => {
  try {
    return await provider.waitForTransaction(txHash, confirmations);
  } catch (error) {
    console.error('等待交易確認錯誤:', error);
    throw error;
  }
};
