#!/bin/bash
# VPS工具箱主面板
# By Bai

INSTALL_DIR="/opt/vps-tools"
MODULE_DIR="$INSTALL_DIR/modules"

# 确保模块目录存在
mkdir -p "$MODULE_DIR"

while true; do
    clear
    # 获取系统资源使用
    MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
    MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    MEM_USAGE=$(awk "BEGIN {printf \"%.1f\", $MEM_USED/$MEM_TOTAL*100}")

    DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    CPU_USAGE=$(printf "%.1f" $CPU_USAGE)

    clear
    echo "------------------------------------------------------------"
    echo "| VPS 工具箱                     |  By Bai                 |"
    echo "------------------------------------------------------------"
    echo "内存使用：已用: ${MEM_USED}M / 总: ${MEM_TOTAL}M (${MEM_USAGE}%)"
    echo "磁盘使用：${DISK_USED}/${DISK_TOTAL} (${DISK_USAGE}%)"
    echo "CPU 使用率：${CPU_USAGE}%"
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
                echo "❌ 系统信息模块不存在或不可执行"
                read -n1 -s -r -p "按任意键返回主菜单..."
            fi
            ;;
        2)
            if [[ -x "$MODULE_DIR/backup.sh" ]]; then
                "$MODULE_DIR/backup.sh"
            else
                echo "❌ 系统备份模块不存在或不可执行"
                read -n1 -s -r -p "按任意键返回主菜单..."
            fi
            ;;
        3)
            if [[ -x "$MODULE_DIR/update.sh" ]]; then
                "$MODULE_DIR/update.sh"
            else
                echo "❌ 更新模块不存在或不可执行"
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
