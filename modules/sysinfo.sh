#!/bin/bash
# 系统信息模块
INSTALL_DIR="/opt/vps-tools"

clear
echo "=============================="
echo "      系统信息查询"
echo "------------------------------"

# 主机名
HOSTNAME=$(hostname)

# 系统版本
OS_VERSION=$(awk -F= '/^PRETTY_NAME/{print $2}' /etc/os-release | tr -d '"')

# Linux内核
KERNEL=$(uname -r)

# CPU架构和型号
ARCH=$(uname -m)
CPU_MODEL=$(awk -F: '/model name/{print $2; exit}' /proc/cpuinfo | sed 's/^[ \t]*//')

# CPU占用
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100-$8"%"}')

# 内存
MEM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
MEM_USED=$(free -m | awk '/Mem:/{print $3}')
MEM_PERCENT=$(awk "BEGIN {printf \"%.2f\", $MEM_USED/$MEM_TOTAL*100}")

# 虚拟内存
SWAP_TOTAL=$(free -m | awk '/Swap:/{print $2}')
SWAP_USED=$(free -m | awk '/Swap:/{print $3}')

# 磁盘
DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
DISK_USED=$(df -h / | awk 'NR==2{print $3}')
DISK_PERCENT=$(df -h / | awk 'NR==2{print $5}')

# 网络流量
RX_BYTES=$(cat /sys/class/net/*/statistics/rx_bytes | awk '{sum+=$1} END {printf "%.2f", sum/1024/1024/1024}')
TX_BYTES=$(cat /sys/class/net/*/statistics/tx_bytes | awk '{sum+=$1} END {printf "%.2f", sum/1024/1024/1024}')

# 时区和时间
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
SYS_TIME=$(date +"%Y-%m-%d %I:%M %p")

# 运行时长
UPTIME_STR=$(awk '{printf "%d天 %d时 %d分\n",$1/86400,$1%86400/3600,$1%3600/60}' /proc/uptime)

# Docker信息
DOCKER_VER=$(docker version --format '{{.Server.Version}}, build {{.Server.Build}}' 2>/dev/null)
DOCKER_COMPOSE_VER=$(docker compose version 2>/dev/null)

CONTAINER_INFO=""
if command -v docker &>/dev/null && [ "$(docker ps -q)" ]; then
    mapfile -t containers < <(docker ps --format "{{.Names}} {{.Networks}}")
    for c in "${containers[@]}"; do
        name=$(echo "$c" | awk '{print $1}')
        net=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$name")
        if [ -z "$net" ]; then
            net="host"
        fi
        CONTAINER_INFO+="  $name  ($net)\n"
    done
fi

# 输出
printf "主机名:       %s\n" "$HOSTNAME"
printf "系统版本:     %s\n" "$OS_VERSION"\n
printf "Linux版本:    %s\n" "$KERNEL"\n
printf "CPU架构:      %s\n" "$ARCH"
printf "CPU型号:      %s\n" "$CPU_MODEL"\n
printf "CPU占用:      %s\n" "$CPU_USAGE"
printf "物理内存:     %s/%s Mi (%.2f%%)\n" "$MEM_USED" "$MEM_TOTAL" "$MEM_PERCENT"
printf "虚拟内存:     %s/%s Mi\n" "$SWAP_USED" "$SWAP_TOTAL"
printf "硬盘占用:     %s/%s (%s)\n" "$DISK_USED" "$DISK_TOTAL" "$DISK_PERCENT"
printf "总接收:       %.2f GB\n" "$RX_BYTES"
printf "总发送:       %.2f GB\n" "$TX_BYTES"
printf "系统时间:     %s %s\n" "$TIMEZONE" "$SYS_TIME"
printf "运行时长:     %s\n" "$UPTIME_STR"
printf "Docker版本:   %s\n" "$DOCKER_VER"
printf "Docker Compose版本:   %s\n" "$DOCKER_COMPOSE_VER"
printf "容器信息:\n%s" "$CONTAINER_INFO"

echo "------------------------------"
read -n1 -s -r -p "按任意键返回主菜单..."
