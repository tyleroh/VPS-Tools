#!/bin/bash
# 系统信息模块

clear
HOSTNAME=$(hostname)
OS_VERSION=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
KERNEL_VERSION=$(uname -r)
ARCH=$(uname -m)
CPU_MODEL=$(lscpu | awk -F: '/Model name/ {print $2}' | sed 's/^ *//')
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
CPU_USAGE=$(printf "%.1f" $CPU_USAGE)
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_PERCENT=$(awk "BEGIN {printf \"%.1f\", $MEM_USED/$MEM_TOTAL*100}")
SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
SWAP_TOTAL=$(free -m | awk '/Swap:/ {print $2}')
DISK_INFO=$(df -h / | awk 'NR==2 {printf "%s/%s (%s)", $3,$2,$5}')
RX_BYTES=$(cat /sys/class/net/$(ip route get 1 | awk '{print $5}')/statistics/rx_bytes)
TX_BYTES=$(cat /sys/class/net/$(ip route get 1 | awk '{print $5}')/statistics/tx_bytes)
RX_GB=$(awk "BEGIN {printf \"%.2f\", $RX_BYTES/1024/1024/1024}")
TX_GB=$(awk "BEGIN {printf \"%.2f\", $TX_BYTES/1024/1024/1024}")
TIMEZONE=$(date +'%Z %Y-%m-%d %I:%M %p')
UPTIME=$(awk '{printf "%d天 %d时 %d分", $1/86400,$1%86400/3600,$1%3600/60}' /proc/uptime)

echo "📊 系统信息如下："
echo "------------------------------"
echo "主机名:       $HOSTNAME"
echo "系统版本:     $OS_VERSION"
echo "Linux版本:    $KERNEL_VERSION"
echo "------------------------------"
echo "CPU架构:      $ARCH"
echo "CPU型号:      $CPU_MODEL"
echo "------------------------------"
echo "CPU占用:      $CPU_USAGE%"
echo "物理内存:     ${MEM_USED}/${MEM_TOTAL} Mi (${MEM_PERCENT}%)"
echo "虚拟内存:     ${SWAP_USED}/${SWAP_TOTAL} Mi"
echo "硬盘占用:     $DISK_INFO"
echo "------------------------------"
echo "总接收:       ${RX_GB} GB"
echo "总发送:       ${TX_GB} GB"
echo "------------------------------"
echo "系统时间:     $TIMEZONE"
echo "运行时长:     $UPTIME"
echo "------------------------------"
docker -v &>/dev/null && echo "Docker版本: $(docker -v)"; docker compose version &>/dev/null && echo "Docker Compose版本: $(docker compose version)"
docker ps --format "  {{.Names}}  ({{.Networks}})"
echo "------------------------------"
read -n1 -s -r -p "按任意键返回主菜单..."
