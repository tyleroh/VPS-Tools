#!/bin/bash
set -e

INSTALL_DIR="/opt/vps-tools"
REPO="tyleroh/VPS-Tools"

echo "📦 正在安装 VPS工具箱 到 $INSTALL_DIR"

# 1. 安装 git
if ! command -v git &>/dev/null; then
    echo "🔧 未检测到 git，正在安装..."
    if [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y git
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y git
    else
        echo "❌ 暂不支持的系统，请手动安装 git 后再试"
        exit 1
    fi
fi

# 2. 拉取/更新仓库
if [ ! -d "$INSTALL_DIR" ]; then
    sudo git clone https://github.com/$REPO.git "$INSTALL_DIR"
else
    cd "$INSTALL_DIR"
    sudo git pull
fi

# 3. 设置权限
sudo chmod +x "$INSTALL_DIR/vps_main.sh"
sudo chmod +x "$INSTALL_DIR/modules"/*.sh || true

# 4. 创建快捷命令
sudo ln -sf "$INSTALL_DIR/vps_main.sh" /usr/local/bin/vtool

echo "✅ 安装完成！"
echo "👉 输入 vtool 即可启动 VPS 工具箱面板"
