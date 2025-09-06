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
    # 获取系统信息
    HOSTNAME=$(hostname)
    OS=$(lsb_release -d 2>/dev/null | cut -f2- || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
    KERNEL=$(uname -r)
    ARCH=$(uname -m)
    MEM_TOTAL=$(free -m | awk '/Mem:/ {printf "%.2f", $2/1024}')
    MEM_USED=$(free -m | awk '/Mem:/ {printf "%.2f", $3/1024}')
    MEM_PERCENT=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}')
    CPU_LOAD=$(top -bn1 | awk '/Cpu\(s\)/ {print 100-$8"%"}')
    NET_RX=$(cat /sys/class/net/$(ip route | grep default | awk '{print $5}')/statistics/rx_bytes)
    NET_TX=$(cat /sys/class/net/$(ip route | grep default | awk '{print $5}')/statistics/tx_bytes)
    NET_RX_GB=$(awk "BEGIN{printf \"%.2f\",$NET_RX/1024/1024/1024}")
    NET_TX_GB=$(awk "BEGIN{printf \"%.2f\",$NET_TX/1024/1024/1024}")
    TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
    SYS_TIME=$(date "+%Y-%m-%d %I:%M %p")
    UPTIME=$(uptime -p)
    DOCKER_VER=$(docker version --format '{{.Server.Version}}, build {{.Server.BuildID}}' 2>/dev/null)
    DOCKER_COMPOSE_VER=$(docker compose version 2>/dev/null)

    echo "------------------------------------------------------------"
    printf "| %-28s | %-23s |\n" "VPS 工具箱" "By Bai"
    echo "------------------------------------------------------------"
    echo "内存使用：已用: ${MEM_USED}G / 总: ${MEM_TOTAL}G"
    echo "磁盘使用：${DISK_PERCENT} 已用 / 总: ${DISK_TOTAL}"
    echo "CPU 使用率：${CPU_LOAD}"
    echo "------------------------------------------------------------"
    echo "1) 查看系统信息"
    echo "2) 系统备份/还原"
    echo "3) 更新工具箱"
    echo "0) 退出"
    echo "------------------------------------------------------------"

    read -rp "请输入序号: " choice

    case $choice in
        1)
            [[ -x "$MODULE_DIR/sysinfo.sh" ]] && "$MODULE_DIR/sysinfo.sh"
            ;;
        2)
            [[ -x "$MODULE_DIR/backup.sh" ]] && "$MODULE_DIR/backup.sh"
            ;;
        3)
            [[ -x "$MODULE_DIR/update.sh" ]] && "$MODULE_DIR/update.sh"
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
