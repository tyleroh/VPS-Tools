#!/bin/bash
# 系统信息模块

clear
echo "=============================="
echo "        系统信息"
echo "=============================="

# 基本信息
hostname=$(hostname)
os_version=$(lsb_release -d 2>/dev/null | awk -F"\t" '{print $2}')
[[ -z "$os_version" ]] && os_version=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
kernel_version=$(uname -r)
cpu_arch=$(uname -m)
cpu_model=$(lscpu | grep "Model name" | head -1 | awk -F: '{print $2}' | sed 's/^[[:space:]]*//')

# 内存
mem_total=$(free -m | awk '/Mem:/ {print $2}')
mem_used=$(free -m | awk '/Mem:/ {print $3}')
mem_percent=$(awk "BEGIN{printf \"%.1f\", $mem_used/$mem_total*100}")

# 交换
swap_total=$(free -m | awk '/Swap:/ {print $2}')
swap_used=$(free -m | awk '/Swap:/ {print $3}')

# 磁盘
disk_used=$(df -h / | awk 'NR==2 {print $3}' | sed 's/G//; s/M//')
disk_total=$(df -h / | awk 'NR==2 {print $2}' | sed 's/G//; s/M//')
disk_percent=$(df -h / | awk 'NR==2 {print $5}')

# 网络流量
default_iface=$(ip route show default | awk '/default/ {print $5}')
rx_bytes=$(cat /sys/class/net/$default_iface/statistics/rx_bytes)
tx_bytes=$(cat /sys/class/net/$default_iface/statistics/tx_bytes)
rx_gb=$(awk "BEGIN{printf \"%.2f\", $rx_bytes/1024/1024/1024}")
tx_gb=$(awk "BEGIN{printf \"%.2f\", $tx_bytes/1024/1024/1024}")

# 系统时间
timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
system_time=$(date "+%Y-%m-%d %I:%M %p")
uptime_info=$(uptime -p | sed 's/up //' \
    | sed -E 's/([0-9]+) days?/\1天/' \
    | sed -E 's/([0-9]+) hours?/\1时/' \
    | sed -E 's/([0-9]+) minutes?/\1分/')

# Docker
docker_version=$(docker version --format 'Docker version {{.Server.Version}}, build {{.Server.BuildID}}' 2>/dev/null)
docker_compose=$(docker compose version 2>/dev/null)
docker_count=$(docker ps -a --format '{{.Names}}' | wc -l)
docker_images=$(docker images -q | wc -l)

# 输出信息
echo "主机名:       $hostname"
echo "系统版本:     $os_version"
echo "Linux版本:    $kernel_version"
echo "CPU架构:      $cpu_arch"
echo "CPU型号:      $cpu_model"
echo "物理内存:     ${mem_used}/${mem_total}M (${mem_percent}%)"
echo "虚拟内存:     ${swap_used}/${swap_total}M"
echo "硬盘占用:     ${disk_used}G/${disk_total}G (${disk_percent})"
echo "总接收:       ${rx_gb}G"
echo "总发送:       ${tx_gb}G"
echo "系统时间:     ${timezone} $system_time"
echo "运行时长:     $uptime_info"
echo "Docker版本:   "
echo "$docker_version"
echo "Docker Compose版本: $docker_compose"
echo "容器: $docker_count  镜像: $docker_images"

# 容器信息
docker ps -a --format '{{.Names}} {{.Networks}}' | while read line; do
    name=$(echo $line | awk '{print $1}')
    net=$(echo $line | awk '{print $2}')
    if [[ $net != "host" ]]; then
        ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$name")
        echo "  $name  ($ip)"
    else
        echo "  $name  ($net)"
    fi
done

read -n1 -s -r -p "按任意键返回主菜单..."
