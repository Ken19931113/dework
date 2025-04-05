#!/bin/bash

# 為所有腳本添加執行權限
chmod +x fix-environment.sh
chmod +x startup.sh
chmod +x reinstall.sh
if [ -f install.sh ]; then
    chmod +x install.sh
fi

echo "已為所有腳本添加執行權限"
