#!/bin/bash
# VPS工具箱主面板
# By Bai

INSTALL_DIR="/opt/vps-tools"
MODULE_DIR="$INSTALL_DIR/modules"

# 确保模块目录存在
mkdir -p "$MODULE_DIR"

# 主循环
while true; do
    clear
    echo "=============================="
    echo "      VPS 工具箱 主面板"
    echo "=============================="
    echo "1) 查看系统信息"
    echo "2) 系统备份/还原"
    echo "3) 更新工具箱"
    echo "0) 退出"
    echo "=============================="
    read -rp "请输入序号: " choice

    case $choice in
        1)
            # 系统信息模块
            if [[ -x "$MODULE_DIR/sysinfo.sh" ]]; then
                "$MODULE_DIR/sysinfo.sh"
            else
                echo "❌ 系统信息模块不存在或不可执行: $MODULE_DIR/sysinfo.sh"
            fi
            read -n1 -s -r -p "按任意键返回主菜单..."
            ;;
        2)
            # 系统备份/还原模块
            if [[ -x "$MODULE_DIR/backup.sh" ]]; then
                "$MODULE_DIR/backup.sh"
            else
                echo "❌ 系统备份模块不存在或不可执行: $MODULE_DIR/backup.sh"
            fi
            read -n1 -s -r -p "按任意键返回主菜单..."
            ;;
        3)
            # 更新工具箱模块
            if [[ -x "$MODULE_DIR/update.sh" ]]; then
                "$MODULE_DIR/update.sh"
            else
                echo "❌ 更新模块不存在或不可执行: $MODULE_DIR/update.sh"
            fi
            read -n1 -s -r -p "按任意键返回主菜单..."
            ;;
        0)
            echo "退出 VPS 工具箱"
            exit 0
            ;;
        *)
            echo "⚠️ 无效输入，请重新选择"
            sleep 1
            ;;
    esac
done