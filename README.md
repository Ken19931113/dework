# Dework Monorepo

This project is set up as a monorepo using pnpm workspaces. The monorepo contains the following packages:

- `packages/frontend`: React-based frontend application
- `packages/backend`: FastAPI-based backend service
- `packages/contracts`: Smart contracts and Hardhat configuration

## Getting Started

### Prerequisites

- Node.js (v16 or later)
- pnpm (v7 or later)
- Python (v3.9 or later)
- Hardhat

### Installation

1. Install dependencies:

```bash
pnpm install
```

2. Set up environment variables:

```bash
# Copy and configure environment files
cp .env.example .env
```

### Development

You can use the following commands to work with the different packages:

#### Frontend

```bash
# Run dev server
pnpm frontend dev

# Build for production
pnpm frontend build
```

#### Backend

```bash
# Run dev server
pnpm backend dev

# Run tests
pnpm backend test
```

#### Contracts

```bash
# Compile contracts
pnpm contracts compile

# Run tests
pnpm contracts test

# Start local Hardhat node
pnpm contracts node

# Deploy contracts
pnpm contracts deploy
```

# DeWork - Web3押金代管平台

透過智能合約與DeFi利率市場管理商業空間租賃押金，提供租客保障、房東獲益和平台穩定收入。

## 專案概述

DeWork 是一個基於區塊鏈技術的押金代管平台，致力於解決商業空間租賃押金管理中的問題。透過智能合約與 DeFi 利率市場，DeWork 提供租客保障、房東獲益和平台穩定收入的整合解決方案。

## 功能亮點

- 租客押金安全透明，有爭議可退回
- 房東獲得利息分潤，無需直接持有押金
- 平台可從利息與手續費中取得收益

## 技術堆棧

- **前端**: React, ethers.js, TailwindCSS, Wagmi/ConnectKit
- **後端**: Python FastAPI
- **智能合約**: Solidity on Arbitrum Sepolia/Arbitrum/HashKey Chain
- **DeFi協議整合**: Aave, Compound

## 整合技術

| 技術               | 功能描述                                                |
|------------------|----------------------------------------------------|
| **ERC-4907**     | 租賃型 NFT，代表租賃憑證，並設計為不可轉讓 |
| **Nodit**        | 去中心化 webhook 平台，用於定時觸發如到期檢查、自動結算等動作 |
| **HashKey Chain**| 身份驗證與租賃記錄鏈，提供房東與租客的鏈上信任來源 |
| **World ID**     | 驗證用戶真實性、防止濫用帳號，配合租客註冊使用 |
| **ENS**          | 每筆租賃 NFT 可綁定 ENS 名稱作為租約識別標籤（企業命名） |
| **Circle (USDC)**| 押金透過 Circle USDC 支付與提款，保障穩定性與鏈下結算支援 |
| **Self Protocol**| 建立租客信用憑證、評估風險與可選擇性掛鉤分潤比例（未來擴展） |

## 區塊鏈與工具

- **主要區塊鏈**：Arbitrum Sepolia (測試網)，Chain ID: 421614
- **備用區塊鏈**：Arbitrum One (主網)，HashKey Chain
- **區塊鏈工具**：
  - Hardhat (智能合約開發框架)
  - Ethers.js (區塊鏈交互庫)
  - Wagmi/ConnectKit (前端區塊鏈連接)
- **穩定幣**：USDC (Arbitrum Sepolia 上的測試版本)

## 快速開始

### 環境修復

如果你在編譯合約時遇到問題，請使用以下指令修復環境：

```bash
chmod +x fix-environment.sh
./fix-environment.sh
```

這個腳本會安裝正確版本的 OpenZeppelin 合約和其他依賴項，並確保環境設置正確。

### 環境準備

1. 確保安裝了 Node.js, npm 和 Python
2. 準備好 MetaMask 錢包並連接到 Arbitrum Sepolia 測試網
3. 從 [Alchemy](https://www.alchemy.com/) 獲取 API 密鑰

### 安裝依賴

```bash
# 智能合約
# 使用修復腳本安裝所有依賴
./fix-environment.sh

# 或手動安裝
npm install

# 後端
cd backend
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# 或 .venv\Scripts\activate  # Windows
pip install -r requirements.txt

# 前端
cd frontend
npm install
```

### 環境配置

複製 `.env.example` 文件並命名為 `.env`，填入您的實際設置:

```bash
# 區塊鏈網絡配置
ARBITRUM_URL=https://arb-sepolia.g.alchemy.com/v2/YOUR_API_KEY
HASHKEY_URL=https://rpc-mainnet.hashkey.com

# 開發錢包私鑰(使用測試錢包!)
PRIVATE_KEY=your_wallet_private_key

# 第三方API配置
CIRCLE_API_KEY=your_circle_api_key
WORLDID_APP_ID=app_your_world_id_app

# 後端配置
BACKEND_PORT=8000
CORS_ORIGINS=http://localhost:3000
```

### 使用快速啟動腳本

我們提供了一個簡易的交互式啟動腳本，可以幫助您快速開始：

```bash
chmod +x startup.sh
./startup.sh
```

這個腳本將幫助您：
1. 檢查環境並根據需要執行修復
2. 確保 .env 文件存在
3. 編譯智能合約
4. 提供不同的部署選項：本地網絡、Arbitrum Sepolia 測試網等

### 手動編譯與部署合約

```bash
# 編譯合約
npx hardhat compile

# 部署到本地網絡進行測試
npx hardhat node
npx hardhat run scripts/deploy.js --network localhost

# 部署到 Arbitrum Sepolia 測試網
npx hardhat run scripts/deploy.js --network arbitrumSepolia
```

### 運行開發環境

```bash
# 運行後端
cd backend
source .venv/bin/activate  # 如果尚未激活
python -m uvicorn app.main:app --reload

# 運行前端
cd frontend
npm start
```

## 項目結構

```
/Users/ken/DeWork/
├── contracts/               # 智能合約目錄
│   ├── core/                  # 核心合約
│   ├── interfaces/            # 合約接口
│   ├── providers/             # 收益提供者實現
│   ├── mocks/                 # 測試用模擬合約
│   └── utils/                 # 工具合約（World ID、ENS等）
├── scripts/                 # 部署和測試腳本
├── test/                    # 測試檔案
├── deploy/                  # 部署信息存儲目錄
├── fix-environment.sh       # 環境修復腳本
├── backend/                 # 後端應用程式
│   ├── app/                   # 後端應用主目錄
│   └── requirements.txt       # 後端依賴
└── frontend/               # 前端應用程式
    └── src/                  # 源代碼
```

## 核心功能與整合技術實現

- **押金管理**：安全、透明地管理租賃押金
- **利息生成**：通過DeFi協議為閒置押金產生收益
- **租賃證明**：使用 ERC-4907 為每個租賃關係生成租賃型 NFT 證明
- **爭議解決**：內建的爭議解決機制保護各方權益
- **自動化流程**：使用 Nodit 觸發租期到期與押金結算
- **身份驗證**：整合 HashKey Chain 與 World ID 驗證用戶真實性
- **智能命名**：使用 ENS 為租賃 NFT 提供易記的識別名稱
- **租戶信用評估**：透過 Self Protocol 建立租戶信用應評估體系
- **Circle USDC 整合**：使用 USDC 作為押金流通幣種，確保並穩定性

## 整合技術具體實現

- **ERC-4907**：完整實現了支持租用機制的NFT標準合約租賃NFT.sol
- **Nodit**：完成NoditManager.sol合約，用於觸發任務與自動化結算
- **HashKey Chain**：實現了HashKeyIdentityVerifier.sol合約，能進行鏈上身份驗證
- **World ID**：實現了WorldIDVerifier.sol合約，並整合至租賃系統
- **ENS**：完成ENSManager.sol合約，處理租賃NFT的定制名稱
- **Self Protocol**：實作了SelfProtocolMock.sol合約，提供信用評分功能

## 如何獲取測試代幣

1. 獲取 Sepolia ETH:
   - 使用 [Sepolia Faucet](https://sepoliafaucet.com/)

2. 將 Sepolia ETH 橋接到 Arbitrum Sepolia:
   - 使用 [Arbitrum Bridge](https://bridge.arbitrum.io/) 並選擇 Sepolia 到 Arbitrum Sepolia

3. 獲取 Arbitrum Sepolia USDC:
   - 在 Arbitrum Sepolia 上使用 DEX 如 Uniswap 獲取 USDC

## 貢獻指南

1. Fork 並克隆儲存庫
2. 創建您的功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交您的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 開啟一個 Pull Request

## 協議

本專案採用 MIT 協議 - 詳見 LICENSE 文件
