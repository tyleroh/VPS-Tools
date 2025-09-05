#!/bin/bash
# 系统信息模块
# By Bai

echo "📊 系统信息如下："
echo "------------------------------"
echo "CPU: $(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
echo "BIOS: $(dmidecode -s bios-version 2>/dev/null || echo N/A)"
echo "内存: $(free -h | awk '/Mem:/ {print $2}')"
echo "已用内存: $(free -h | awk '/Mem:/ {print $3}')"
echo "磁盘用量: $(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')"

# Docker 容器数量及详细信息
docker_count=$(docker ps -q | wc -l)
echo "Docker 容器数量: $docker_count"

if [[ $docker_count -gt 0 ]]; then
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