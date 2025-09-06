#!/bin/bash
# VPS 工具箱主面板
# By Bai

INSTALL_DIR="/opt/vps-tools"
MODULE_DIR="$INSTALL_DIR/modules"
BACKUP_DIR="$INSTALL_DIR/backup"

# 确保模块和备份目录存在
mkdir -p "$MODULE_DIR" "$BACKUP_DIR"

while true; do
    clear
    # 主面板信息
    echo "------------------------------------------------------------"
    echo "| VPS 工具箱                     |  By Bai                 |"
    echo "------------------------------------------------------------"

    # 内存
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_percent=$(awk "BEGIN{printf \"%.1f\", $mem_used/$mem_total*100}")
    echo "内存使用：已用: ${mem_used}M / 总: ${mem_total}M (${mem_percent}%)"

    # 磁盘
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    disk_percent=$(df -h / | awk 'NR==2 {print $5}')
    echo "磁盘使用：${disk_used}/${disk_total} (${disk_percent})"

    # CPU 占用
    cpu_percent=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    echo "CPU 使用率：${cpu_percent}%"
    echo "------------------------------------------------------------"

    echo "1) 查看系统信息"
    echo "2) 系统备份/还原"
    echo "3) 更新工具箱"
    echo "0) 退出"
    echo "------------------------------------------------------------"
    read -rp "请输入序号: " choice

    case $choice in
        1)
            if [[ -x "$MODULE_DIR/sysinfo.sh" ]]; then
                "$MODULE_DIR/sysinfo.sh"
            else
                echo "❌ 系统信息模块不存在或不可执行: $MODULE_DIR/sysinfo.sh"
                read -n1 -s -r -p "按任意键返回主菜单..."
            fi
            ;;
        2)
            if [[ -x "$MODULE_DIR/backup.sh" ]]; then
                "$MODULE_DIR/backup.sh"
            else
                echo "❌ 系统备份模块不存在或不可执行: $MODULE_DIR/backup.sh"
                read -n1 -s -r -p "按任意键返回主菜单..."
            fi
            ;;
        3)
            if [[ -x "$MODULE_DIR/update.sh" ]]; then
                "$MODULE_DIR/update.sh"
            else
                echo "❌ 更新模块不存在或不可执行: $MODULE_DIR/update.sh"
                read -n1 -s -r -p "按任意键返回主菜单..."
            fi
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
