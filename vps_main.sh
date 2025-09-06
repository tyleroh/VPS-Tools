#!/bin/bash
# VPS工具箱主面板 - 简洁版 + 模块调用
# By Bai

INSTALL_DIR="/opt/vps-tools"
MODULE_DIR="$INSTALL_DIR/modules"

mkdir -p "$MODULE_DIR"

get_sysinfo() {
    MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_USED_PERCENT=$(df -h / | awk 'NR==2 {print $5}')
    CPU_USAGE=$(awk -v RS="" '/cpu /{u=$2+$4; t=$2+$4+$5; printf "%.1f%%", u/t*100}' /proc/stat)
}

while true; do
    clear
    get_sysinfo
    echo "------------------------------------------------------------"
    echo "| VPS 工具箱                     |  By Bai                 |"
    echo "------------------------------------------------------------"
    echo "内存使用：已用: ${MEM_USED}Mi / 总: ${MEM_TOTAL}Mi"
    echo "磁盘使用：${DISK_USED_PERCENT} 已用 / 总: ${DISK_TOTAL}"
    echo "CPU 使用率：${CPU_USAGE}"
    echo "------------------------------------------------------------"
    echo "1) 查看系统信息"
    echo "2) 系统备份/还原"
    echo "3) 更新工具箱"
    echo "0) 退出"
    echo "------------------------------------------------------------"
    read -rp "请输入序号: " choice

    case $choice in
        1)
            [[ -x "$MODULE_DIR/sysinfo.sh" ]] && bash "$MODULE_DIR/sysinfo.sh" || echo "❌ sysinfo模块不存在"
            ;;
        2)
            [[ -x "$MODULE_DIR/backup.sh" ]] && bash "$MODULE_DIR/backup.sh" || echo "❌ backup模块不存在"
            ;;
        3)
            [[ -x "$MODULE_DIR/update.sh" ]] && bash "$MODULE_DIR/update.sh" || echo "❌ update模块不存在"
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
