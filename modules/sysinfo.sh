#!/bin/bash
# 系统信息模块 - 自动获取动态信息
# By Bai

# 基础信息
HOSTNAME=$(hostname)
OS_VER=$(lsb_release -d 2>/dev/null | awk -F"\t" '{print $2}' || grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
KERNEL_VER=$(uname -r)
ARCH=$(uname -m)
CPU_MODEL=$(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100-$8"%"}')
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_PERCENT=$(awk "BEGIN {printf \"%.2f\",($MEM_USED/$MEM_TOTAL)*100}")
VIRT_TOTAL=$(free -m | awk '/Swap:/ {print $2}')
VIRT_USED=$(free -m | awk '/Swap:/ {print $3}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')
UPTIME=$(uptime -p)

# 网络信息动态获取
DEFAULT_IF=$(ip route | grep default | awk '{print $5}' | head -1)
DNS=$(grep ^nameserver /etc/resolv.conf | awk '{print $2}' | head -1)
IPV4=$(curl -s https://ipinfo.io/ip)
ISP=$(curl -s https://ipinfo.io/org)
GEO=$(curl -s https://ipinfo.io/loc)
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')

# 网络算法
NETWORK_ALGO=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')

# Docker信息
DOCKER_VER=$(docker --version 2>/dev/null || echo N/A)
DOCKER_COMPOSE_VER=$(docker compose version 2>/dev/null || echo N/A)
DOCKER_CONTAINERS=$(docker ps -q | wc -l)
DOCKER_IMAGES=$(docker images -q | wc -l)

clear
echo "系统信息查询"
echo "-------------"
echo "主机名:       $HOSTNAME"
echo "系统版本:     $OS_VER"
echo "Linux版本:    $KERNEL_VER"
echo "-------------"
echo "CPU架构:      $ARCH"
echo "CPU型号:      $CPU_MODEL"
echo "-------------"
echo "CPU占用:      $CPU_USAGE"
echo "物理内存:     $MEM_USED/$MEM_TOTAL M (${MEM_PERCENT}%)"
echo "虚拟内存:     $VIRT_USED/$VIRT_TOTAL M"
echo "硬盘占用:     $DISK_USAGE"
echo "-------------"
echo "总接收:       $(cat /sys/class/net/$DEFAULT_IF/statistics/rx_bytes 2>/dev/null)"
echo "总发送:       $(cat /sys/class/net/$DEFAULT_IF/statistics/tx_bytes 2>/dev/null)"
echo "-------------"
echo "网络算法:     $NETWORK_ALGO"
echo "-------------"
echo "运营商:       $ISP"
echo "IPv4地址:     $IPV4"
echo "DNS地址:      $DNS"
echo "地理位置:     $GEO"
echo "系统时间:     $(date)"
echo "时区:         $TIMEZONE"
echo "-------------"
echo "运行时长:     $UPTIME"
echo "-------------"
echo "Docker版本："
echo "$DOCKER_VER"
echo "Docker Compose版本："
echo "$DOCKER_COMPOSE_VER"
echo "容器: $DOCKER_CONTAINERS  镜像: $DOCKER_IMAGES"
if [[ $DOCKER_CONTAINERS -gt 0 ]]; then
    echo "容器信息:"
    for name in $(docker ps --format '{{.Names}}' | sort -u); do
        network=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$name")
        network_mode=$(docker inspect -f '{{.HostConfig.NetworkMode}}' "$name")
        if [[ "$network_mode" == "host" ]]; then
            echo "  $name  (host)"
        else
            echo "  $name  ($network)"
        fi
    done
fi
echo "------------------------------"

read -n1 -s -r -p "按任意键返回主菜单..." </dev/tty
