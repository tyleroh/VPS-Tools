#!/bin/bash
INSTALL_DIR="/opt/vps-tools"
MODULE_DIR="$INSTALL_DIR/modules"

while true; do
    clear
    echo "=============================="
    echo "      VPS 工具箱  By Bai      "
    echo "=============================="
    echo "1) 查看系统信息"
    echo "2) 系统备份/还原"
    echo "9) 更新工具箱"
    echo "0) 退出"
    echo "=============================="
    read -rp "请输入序号: " choice

    case $choice in
        1) bash "$MODULE_DIR/sysinfo.sh" ;;
        2) bash "$MODULE_DIR/backup.sh" ;;
        9)
            echo "🔄 正在更新 VPS 工具箱..."
            cd "$INSTALL_DIR" && git pull
            echo "✅ 更新完成，按任意键返回菜单"
            read -n 1
            ;;
        0) exit 0 ;;
        *) echo "❌ 无效输入，请重试" && sleep 1 ;;
    esac
done
