#!/bin/bash
# 更新模块，保留 backup 文件夹
INSTALL_DIR="/opt/vps-tools"
MODULE_DIR="$INSTALL_DIR/modules"
BACKUP_DIR="$INSTALL_DIR/backup"
REPO="tyleroh/VPS-Tools"

echo "🧹 正在更新 VPS 工具箱..."

# 备份当前模块
echo "📦 保留 backup 文件夹: $BACKUP_DIR"

# 更新主面板
curl -sSL "https://raw.githubusercontent.com/$REPO/main/vps_main.sh" -o "$INSTALL_DIR/vps_main.sh"

# 更新模块
for module in sysinfo.sh backup.sh update.sh; do
    echo "📄 更新模块: $module"
    curl -sSL "https://raw.githubusercontent.com/$REPO/main/modules/$module" -o "$MODULE_DIR/$module"
done

# 设置权限
chmod +x "$INSTALL_DIR/vps_main.sh"
chmod +x "$MODULE_DIR"/*.sh

# 全局命令 v
ln -sf "$INSTALL_DIR/vps_main.sh" /usr/local/bin/v
chmod +x /usr/local/bin/v

echo "✅ 更新完成！使用 'v' 启动主面板。"
