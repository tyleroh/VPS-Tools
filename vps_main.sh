#!/bin/bash
# VPS工具箱主面板 - 简洁版
# By Bai

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$SCRIPT_DIR/modules"

# 获取系统资源使用情况
get_sysinfo() {
    MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_USED_PERCENT=$(df -h / | awk 'NR==2 {print $5}')
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk -F'id,' '{print 100 - $1}' | awk '{printf "%.1f%%\n",$1}')
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
        1) bash "$MODULE_DIR/sysinfo.sh" ;;        # 详细系统信息模块
        2) bash "$MODULE_DIR/backup.sh" ;;         # 系统备份/还原
        3) bash "$MODULE_DIR/update.sh" ;;         # 更新工具箱
        0) exit 0 ;;
        *) echo "输入错误，请重新选择"; sleep 1 ;;
    esac
done
