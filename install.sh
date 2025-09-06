#!/bin/bash
# VPS工具箱安装脚本
INSTALL_DIR="/opt/vps-tools"
MODULE_DIR="$INSTALL_DIR/modules"
BACKUP_DIR="$INSTALL_DIR/backup"
REPO="tyleroh/VPS-Tools"

echo "🧹 正在清理旧版本..."
rm -rf "$INSTALL_DIR"

echo "📦 正在安装 VPS 工具箱到 $INSTALL_DIR..."
mkdir -p "$MODULE_DIR" "$BACKUP_DIR"

# 下载主面板
curl -sSL "https://raw.githubusercontent.com/$REPO/main/vps_main.sh" -o "$INSTALL_DIR/vps_main.sh"

# 下载模块
for module in sysinfo.sh backup.sh update.sh; do
    echo "📄 下载模块: $module"
    curl -sSL "https://raw.githubusercontent.com/$REPO/main/modules/$module" -o "$MODULE_DIR/$module"
done

# 设置权限
chmod +x "$INSTALL_DIR/vps_main.sh"
chmod +x "$MODULE_DIR"/*.sh

# 创建全局快捷命令
ln -sf "$INSTALL_DIR/vps_main.sh" /usr/local/bin/vtool
chmod +x /usr/local/bin/vtool

echo "✅ 安装完成！使用 'vtool' 启动主面板。"
