#!/bin/bash
# VPS工具箱 - 更新工具箱脚本
# By Bai

INSTALL_DIR="/opt/vps-tools"
REPO_URL="https://github.com/tyleroh/VPS-Tools.git"
LOG_FILE="$INSTALL_DIR/logs/update.log"

mkdir -p "$INSTALL_DIR/logs"

echo "🔄 开始更新工具箱..."
cd "$INSTALL_DIR" || { echo "❌ 找不到目录 $INSTALL_DIR"; exit 1; }

# 如果未初始化 git，则初始化
if [ ! -d ".git" ]; then
    git init
    git remote add origin "$REPO_URL"
    git branch -M main
fi

# 放弃本地修改
git reset --hard

# 拉取远程最新版本
git pull origin main

# 给主面板和模块赋可执行权限
chmod +x "$INSTALL_DIR/vps_main.sh"
chmod +x "$INSTALL_DIR/modules/"*.sh
chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null

echo "✅ 工具箱更新完成！详细日志：$LOG_FILE"