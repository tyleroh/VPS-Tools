#!/bin/bash
# 系统信息模块

show_sysinfo() {
    clear
    echo "========= 系统信息 ========="

    # 系统基本信息
    os=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
    kernel=$(uname -r)
    arch=$(uname -m)
    cpu_model=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')

    # CPU 使用率（取 1 秒平均）
    cpu_usage=$(top -bn2 | grep "Cpu(s)" | tail -n1 | awk '{print 100-$8}' | awk '{printf "%.1f", $1}')

    # 内存使用（MiB 转换为 M，取整）
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    mem_percent=$(awk "BEGIN {printf \"%.1f\", ($mem_used/$mem_total)*100}")

    # 硬盘使用情况（取根分区）
    disk_used=$(df -h --total | grep ' /$' | awk '{print $3}')
    disk_total=$(df -h --total | grep ' /$' | awk '{print $2}')
    disk_percent=$(df -h --total | grep ' /$' | awk '{print $5}' | tr -d '%')

    # 网络流量（转为 GB，保留两位小数）
    rx_bytes=$(cat /proc/net/dev | awk '/eth0|ens/ {rx+=$2} END {print rx}')
    tx_bytes=$(cat /proc/net/dev | awk '/eth0|ens/ {tx+=$10} END {print tx}')
    rx_gb=$(awk "BEGIN {printf \"%.2f\", $rx_bytes/1024/1024/1024}")
    tx_gb=$(awk "BEGIN {printf \"%.2f\", $tx_bytes/1024/1024/1024}")

    # 系统时间（Asia/Shanghai）
    sys_time=$(TZ="Asia/Shanghai" date "+%Y-%m-%d %I:%M %p")

    # 运行时长
    uptime_seconds=$(awk '{print int($1)}' /proc/uptime)
    days=$((uptime_seconds/86400))
    hours=$(( (uptime_seconds%86400)/3600 ))
    minutes=$(( (uptime_seconds%3600)/60 ))

    # Docker 信息
    docker_version=$(docker --version 2>/dev/null)
    compose_version=$(docker compose version 2>/dev/null)
    container_count=$(docker ps -q 2>/dev/null | wc -l)
    image_count=$(docker images -q 2>/dev/null | wc -l)

    # 打印结果
    echo "系统版本:   $os"
    echo "Linux版本:  $kernel"
    echo "CPU架构:    $arch"
    echo "CPU型号:    $cpu_model"
    echo "CPU占用:    ${cpu_usage}%"
    echo "物理内存:   ${mem_used}/${mem_total}M (${mem_percent}%)"
    echo "硬盘占用:   ${disk_used}/${disk_total} (${disk_percent}%)"
    echo "总接收:     ${rx_gb} GB"
    echo "总发送:     ${tx_gb} GB"
    echo "系统时间:   Asia/Shanghai $sys_time"
    echo "运行时长:   ${days}天 ${hours}时 ${minutes}分"

    echo -e "\nDocker版本"
    echo "$docker_version"
    echo "$compose_version"
    echo "容器: $container_count  镜像: $image_count"

    # 容器信息
    if command -v docker &>/dev/null; then
        echo "容器信息:"
        docker ps --format "table {{.Names}}\t{{.Networks}}" | tail -n +2
    fi

    echo "----------------------------"
    read -n 1 -s -r -p "按任意键返回主菜单..."
}
