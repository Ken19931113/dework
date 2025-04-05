import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import useWeb3 from '../hooks/useWeb3';
import { formatAmount, parseAmount } from '../utils/helpers';

const CreateRental = () => {
  const navigate = useNavigate();
  const { isConnected, address, contracts, provider } = useWeb3();
  
  const [formValues, setFormValues] = useState({
    landlordAddress: '',
    depositAmount: '',
    leaseDuration: 365 // 默認365天
  });
  
  const [formErrors, setFormErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [approvalStatus, setApprovalStatus] = useState('notApproved');
  const [usdcBalance, setUsdcBalance] = useState(0);
  const [usdcAllowance, setUsdcAllowance] = useState(0);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  
  // 如果未連接錢包，跳轉到連接頁面
  useEffect(() => {
    if (!isConnected) {
      navigate('/connect');
    }
  }, [isConnected, navigate]);
  
  // 獲取USDC餘額和授權額度
  useEffect(() => {
    const getBalanceAndAllowance = async () => {
      try {
        if (contracts.usdc && address && contracts.rentalDeposit) {
          const balance = await contracts.usdc.balanceOf(address);
          setUsdcBalance(balance);
          
          const allowance = await contracts.usdc.allowance(
            address,
            await contracts.rentalDeposit.getAddress()
          );
          setUsdcAllowance(allowance);
          
          // 檢查授權狀態
          if (allowance > 0) {
            setApprovalStatus('approved');
          }
        }
      } catch (err) {
        console.error('獲取餘額和授權錯誤:', err);
      }
    };
    
    if (isConnected && contracts.usdc) {
      getBalanceAndAllowance();
    }
  }, [isConnected, address, contracts.usdc, contracts.rentalDeposit]);
  
  // 表單輸入變化處理
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormValues({
      ...formValues,
      [name]: value
    });
  };
  
  // 表單驗證
  const validateForm = () => {
    const errors = {};
    
    // 驗證房東地址
    if (!formValues.landlordAddress) {
      errors.landlordAddress = '房東地址不能為空';
    } else if (!/^(0x)?[0-9a-fA-F]{40}$/.test(formValues.landlordAddress)) {
      errors.landlordAddress = '無效的以太坊地址';
    } else if (formValues.landlordAddress.toLowerCase() === address.toLowerCase()) {
      errors.landlordAddress = '不能使用自己的地址作為房東地址';
    }
    
    // 驗證押金金額
    if (!formValues.depositAmount) {
      errors.depositAmount = '押金金額不能為空';
    } else if (isNaN(formValues.depositAmount) || parseFloat(formValues.depositAmount) <= 0) {
      errors.depositAmount = '押金必須大於0';
    } else {
      const depositAmountInWei = parseAmount(formValues.depositAmount);
      if (depositAmountInWei.gt(usdcBalance)) {
        errors.depositAmount = '餘額不足';
      }
    }
    
    // 驗證租期
    if (!formValues.leaseDuration) {
      errors.leaseDuration = '租期不能為空';
    } else if (isNaN(formValues.leaseDuration) || parseInt(formValues.leaseDuration) <= 0) {
      errors.leaseDuration = '租期必須大於0';
    }
    
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };
  
  // 批准代幣使用
  const handleApproveToken = async () => {
    try {
      setError(null);
      setIsSubmitting(true);
      setApprovalStatus('approving');
      
      const depositAmountInWei = parseAmount(formValues.depositAmount);
      const rentalDepositAddress = await contracts.rentalDeposit.getAddress();
      
      const tx = await contracts.usdc.approve(rentalDepositAddress, depositAmountInWei);
      await tx.wait();
      
      setUsdcAllowance(depositAmountInWei);
      setApprovalStatus('approved');
      setSuccess('USDC授權成功！');
    } catch (err) {
      console.error('代幣授權錯誤:', err);
      setError('代幣授權失敗，請重試。');
      setApprovalStatus('notApproved');
    } finally {
      setIsSubmitting(false);
    }
  };
  
  // 提交表單
  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // 驗證表單
    if (!validateForm()) {
      return;
    }
    
    try {
      setError(null);
      setSuccess(null);
      setIsSubmitting(true);
      
      const depositAmountInWei = parseAmount(formValues.depositAmount);
      const leaseDurationInSeconds = parseInt(formValues.leaseDuration) * 24 * 60 * 60; // 轉換為秒
      
      // 檢查授權
      if (depositAmountInWei.gt(usdcAllowance)) {
        setApprovalStatus('needApproval');
        setIsSubmitting(false);
        return;
      }
      
      // 創建租賃合約
      const tx = await contracts.rentalDeposit.createRental(
        formValues.landlordAddress,
        depositAmountInWei,
        leaseDurationInSeconds
      );
      
      await tx.wait();
      
      setSuccess('租賃合約創建成功！');
      
      // 延遲跳轉到儀表板
      setTimeout(() => {
        navigate('/dashboard');
      }, 2000);
    } catch (err) {
      console.error('創建租賃錯誤:', err);
      setError('創建租賃合約失敗，請重試。');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-2xl mx-auto bg-white rounded-xl shadow-md p-8">
        <div className="mb-6">
          <h1 className="text-2xl font-bold mb-2">創建新租賃合約</h1>
          <p className="text-gray-600">
            填寫以下信息創建新的租賃押金合約
          </p>
        </div>
        
        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            {error}
          </div>
        )}
        
        {success && (
          <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
            {success}
          </div>
        )}
        
        <form onSubmit={handleSubmit}>
          {/* 房東地址 */}
          <div className="mb-6">
            <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="landlordAddress">
              房東地址
            </label>
            <input
              id="landlordAddress"
              name="landlordAddress"
              type="text"
              placeholder="0x..."
              value={formValues.landlordAddress}
              onChange={handleInputChange}
              className={`shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline ${
                formErrors.landlordAddress ? 'border-red-500' : ''
              }`}
            />
            {formErrors.landlordAddress && (
              <p className="text-red-500 text-xs italic mt-1">{formErrors.landlordAddress}</p>
            )}
            <p className="text-gray-500 text-xs mt-1">
              輸入房東的以太坊錢包地址
            </p>
          </div>
          
          {/* 押金金額 */}
          <div className="mb-6">
            <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="depositAmount">
              押金金額 (USDC)
            </label>
            <div className="relative">
              <input
                id="depositAmount"
                name="depositAmount"
                type="text"
                placeholder="1000"
                value={formValues.depositAmount}
                onChange={handleInputChange}
                className={`shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline ${
                  formErrors.depositAmount ? 'border-red-500' : ''
                }`}
              />
              <div className="absolute inset-y-0 right-0 flex items-center px-3 pointer-events-none">
                <span className="text-gray-500">USDC</span>
              </div>
            </div>
            {formErrors.depositAmount && (
              <p className="text-red-500 text-xs italic mt-1">{formErrors.depositAmount}</p>
            )}
            <p className="text-gray-500 text-xs mt-1">
              您的USDC餘額: {formatAmount(usdcBalance)} USDC
            </p>
          </div>
          
          {/* 租期 */}
          <div className="mb-8">
            <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="leaseDuration">
              租期 (天數)
            </label>
            <input
              id="leaseDuration"
              name="leaseDuration"
              type="number"
              min="1"
              placeholder="365"
              value={formValues.leaseDuration}
              onChange={handleInputChange}
              className={`shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline ${
                formErrors.leaseDuration ? 'border-red-500' : ''
              }`}
            />
            {formErrors.leaseDuration && (
              <p className="text-red-500 text-xs italic mt-1">{formErrors.leaseDuration}</p>
            )}
          </div>
          
          {/* 按鈕區域 */}
          <div className="flex justify-between items-center">
            <button
              type="button"
              onClick={() => navigate('/dashboard')}
              className="bg-gray-300 hover:bg-gray-400 text-gray-800 font-medium py-2 px-4 rounded focus:outline-none focus:shadow-outline"
            >
              取消
            </button>
            
            {approvalStatus === 'needApproval' || (approvalStatus === 'notApproved' && formValues.depositAmount) ? (
              <button
                type="button"
                onClick={handleApproveToken}
                disabled={isSubmitting}
                className="bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded focus:outline-none focus:shadow-outline"
              >
                {isSubmitting && approvalStatus === 'approving' ? (
                  <>
                    <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white inline-block" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    授權中...
                  </>
                ) : (
                  '授權USDC'
                )}
              </button>
            ) : (
              <button
                type="submit"
                disabled={isSubmitting || Object.keys(formErrors).length > 0}
                className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded focus:outline-none focus:shadow-outline"
              >
                {isSubmitting ? (
                  <>
                    <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white inline-block" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    創建中...
                  </>
                ) : (
                  '創建租賃合約'
                )}
              </button>
            )}
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreateRental;
