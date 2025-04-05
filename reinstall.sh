#!/bin/bash

echo "刪除 node_modules 目錄和 package-lock.json..."
rm -rf node_modules
rm -f package-lock.json

echo "安裝依賴項..."
npm install --legacy-peer-deps

echo "編譯合約..."
npx hardhat compile

echo "安裝完成!"
