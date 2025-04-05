#!/bin/bash

echo "清理環境..."
rm -rf node_modules
rm -f package-lock.json

echo "安裝所需的套件..."
npm install --save-exact @openzeppelin/contracts@4.9.3 dotenv@16.3.1
npm install --save-dev --save-exact @nomicfoundation/hardhat-toolbox@3.0.0 hardhat@2.17.0

echo "清理編譯緩存..."
rm -rf artifacts
rm -rf cache

echo "編譯合約..."
npx hardhat compile

echo "環境修復完成！"
