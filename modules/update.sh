#!/bin/bash
# 更新工具箱模块 - 保留 backup 文件夹
INSTALL_DIR="/opt/vps-tools"
MODULE_DIR="$INSTALL_DIR/modules"
REPO="tyleroh/VPS-Tools"

echo "=============================="
echo "🔄 正在更新 VPS 工具箱..."
echo "=============================="

cd "$INSTALL_DIR" || exit

# 如果是 Git 安装
if [ -d ".git" ]; then
    git fetch --all
    git reset --hard origin/main
else
    # 非 Git 安装，覆盖下载主面板和模块
    TMP_DIR=$(mktemp -d)
    curl -sSL "https://raw.githubusercontent.com/$REPO/main/vps_main.sh" -o "$TMP_DIR/vps_main.sh"
    chmod +x "$TMP_DIR/vps_main.sh"
    mv "$TMP_DIR/vps_main.sh" "$INSTALL_DIR/vps_main.sh"

    mkdir -p "$TMP_DIR/modules"
    module_files=$(curl -sSL "https://api.github.com/repos/$REPO/contents/modules" | grep '"name":' | cut -d '"' -f4)
    for file in $module_files; do
        curl -sSL "https://raw.githubusercontent.com/$REPO/main/modules/$file" -o "$TMP_DIR/modules/$file"
        chmod +x "$TMP_DIR/modules/$file"
    done

    for f in "$TMP_DIR/modules"/*; do
        mv "$f" "$MODULE_DIR/"
    done
    rm -rf "$TMP_DIR"
fi

echo "✅ 更新完成，backup 文件夹已保留"
read -n1 -s -r -p "按任意键返回主菜单..."
