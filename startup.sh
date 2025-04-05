#!/bin/bash

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印標題
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}       DeWork 專案啟動腳本          ${NC}"
echo -e "${BLUE}=====================================${NC}"

# 檢查環境
echo -e "${YELLOW}檢查環境...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}錯誤: 找不到 Node.js，請先安裝 Node.js${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}錯誤: 找不到 npm，請先安裝 npm${NC}"
    exit 1
fi

# 檢查修復環境腳本權限
if [ ! -x "fix-environment.sh" ]; then
    echo -e "${YELLOW}添加修復環境腳本執行權限...${NC}"
    chmod +x fix-environment.sh
fi

# 詢問用戶是否要修復環境
read -p "是否需要修復環境？（已安裝過依賴可跳過）[y/N]: " fix_env
if [[ $fix_env =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}修復環境...${NC}"
    ./fix-environment.sh
fi

# 檢查是否有 .env 文件
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}找不到 .env 文件，從模板創建...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}已創建 .env 文件，請編輯填入正確的配置${NC}"
    else
        echo -e "${RED}錯誤: 找不到 .env.example 模板文件${NC}"
        exit 1
    fi
fi

# 編譯合約
echo -e "${YELLOW}編譯智能合約...${NC}"
npx hardhat compile

# 詢問用戶想執行哪個功能
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}請選擇要執行的功能:${NC}"
echo -e "${BLUE}=====================================${NC}"
echo "1) 運行本地開發節點"
echo "2) 部署合約到本地網絡"
echo "3) 部署合約到 Arbitrum Sepolia 測試網"
echo "4) 運行測試"
echo "5) 退出"

read -p "請輸入選項 [1-5]: " choice

case $choice in
    1)
        echo -e "${YELLOW}啟動本地開發節點...${NC}"
        npx hardhat node
        ;;
    2)
        echo -e "${YELLOW}部署合約到本地網絡...${NC}"
        # 檢查是否有本地節點在運行
        echo -e "${YELLOW}請確保本地節點已啟動 (使用選項1)${NC}"
        read -p "繼續部署？[y/N]: " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            npx hardhat run scripts/deploy-localhost.js --network localhost
        fi
        ;;
    3)
        echo -e "${YELLOW}部署合約到 Arbitrum Sepolia 測試網...${NC}"
        echo -e "${YELLOW}請確保 .env 文件中有正確的 Arbitrum Sepolia RPC URL 和私鑰${NC}"
        read -p "繼續部署？[y/N]: " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            npx hardhat run scripts/deploy.js --network arbitrumSepolia
        fi
        ;;
    4)
        echo -e "${YELLOW}運行測試...${NC}"
        npx hardhat test
        ;;
    5)
        echo -e "${GREEN}退出程序${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}無效選項${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}操作完成！${NC}"
