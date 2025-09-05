#!/bin/bash
# 系统备份/还原模块
# By Bai

MODULE_DIR=$(dirname "$0")
BACKUP_DIR="/opt/vps-tools/backup"
mkdir -p "$BACKUP_DIR"

while true; do
    clear
    echo "系统备份/还原模块"
    echo "=============================="
    echo "1) 系统备份"
    echo "2) 系统还原"
    echo "0) 返回主菜单"
    echo "=============================="
    read -rp "请输入序号: " choice

    case $choice in
        1)
            echo "🔹 可停用的 Docker 容器:"
            mapfile -t containers < <(docker ps --format '{{.Names}}' | sort -u)
            containers+=("all")
            for i in "${!containers[@]}"; do
                echo " $((i+1))) ${containers[i]}"
            done
            read -rp "请输入序号(空格分隔, 0返回主菜单): " docker_choice
            if [[ "$docker_choice" == "0" ]]; then continue; fi
            stop_list=()
            for idx in $docker_choice; do
                [[ $idx -le ${#containers[@]} ]] && stop_list+=("${containers[$((idx-1))]}")
            done
            echo "🔹 停用容器: ${stop_list[*]}"
            for c in "${stop_list[@]}"; do
                [[ "$c" != "all" ]] && docker stop "$c" &>/dev/null
            done
            [[ " ${stop_list[*]} " =~ "all" ]] && docker stop $(docker ps -q) &>/dev/null
            echo "🔹 开始备份..."
            echo "[备份目录]"
            echo " docker目录"
            echo " 哪吒监控"
            echo " SSL证书"
            echo " ufw防火自定义规则"
            echo " XPanel配置文件"
            backup_file="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
            tar -czf "$backup_file" \
                /opt/compose \
                /opt/nezha/dashboard \
                /root/cert \
                /etc/ufw/applications.d/custom \
                /etc/x-ui/x-ui.db \
                /usr/local/x-ui/bin/config.json &>/dev/null
            echo "✅ 备份完成: $backup_file"
            # 启动停用的容器
            for c in "${stop_list[@]}"; do
                [[ "$c" != "all" ]] && docker start "$c" &>/dev/null
            done
            [[ " ${stop_list[*]} " =~ "all" ]] && docker start $(docker ps -aq) &>/dev/null
            echo "🔹 已恢复容器: ${stop_list[*]}"
            read -n1 -s -r -p "按任意键返回主菜单..." </dev/tty
            ;;
        2)
            # 系统还原
            files=($(ls -1t "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null))
            if [[ ${#files[@]} -eq 0 ]]; then
                echo "⚠️ 没有备份文件"
                read -n1 -s -r -p "按任意键返回主菜单..." </dev/tty
                continue
            fi
            echo "🔹 可用的备份文件:"
            for i in "${!files[@]}"; do
                echo " $((i+1))) $(basename "${files[i]}")"
            done
            read -rp "请输入要还原的备份文件序号 (0返回主菜单): " restore_choice
            if [[ "$restore_choice" == "0" ]]; then continue; fi
            if ! [[ "$restore_choice" =~ ^[0-9]+$ ]] || (( restore_choice < 1 || restore_choice > ${#files[@]} )); then
                echo "⚠️ 请输入有效序号！"
                read -n1 -s -r -p "按任意键返回主菜单..." </dev/tty
                continue
            fi
            backup_file="${files[$((restore_choice-1))]}"
            echo "🔹 可还原分类:"
            echo " 1) nezha"
            echo " 2) xpanel"
            echo " 3) ufw"
            echo " 4) ssl"
            echo " 5) docker"
            echo " a) 全部"
            read -rp "请输入要还原的分类序号 (空格分隔, 0返回主菜单): " categories
            if [[ "$categories" == "0" ]]; then continue; fi
            valid=("1" "2" "3" "4" "5" "a")
            invalid=false
            for c in $categories; do
                if [[ ! " ${valid[*]} " =~ " $c " ]]; then
                    invalid=true
                    break
                fi
            done
            if $invalid; then
                echo "⚠️ 输入无效，未执行还原"
                read -n1 -s -r -p "按任意键返回主菜单..." </dev/tty
                continue
            fi
            echo "🔹 停用选择的 Docker 容器（如有）"
            mapfile -t containers < <(docker ps --format '{{.Names}}' | sort -u)
            containers+=("all")
            for i in "${!containers[@]}"; do
                echo " $((i+1))) ${containers[i]}"
            done
            read -rp "请选择停用的容器序号 (空格分隔, 0返回主菜单): " docker_choice
            if [[ "$docker_choice" == "0" ]]; then continue; fi
            stop_list=()
            for idx in $docker_choice; do
                [[ $idx -le ${#containers[@]} ]] && stop_list+=("${containers[$((idx-1))]}")
            done
            echo "🔹 停用容器: ${stop_list[*]}"
            for c in "${stop_list[@]}"; do
                [[ "$c" != "all" ]] && docker stop "$c" &>/dev/null
            done
            [[ " ${stop_list[*]} " =~ "all" ]] && docker stop $(docker ps -q) &>/dev/null

            echo "🔹 开始还原分类: $categories"
            tar -xzf "$backup_file" -C / \
                $( [[ "$categories" =~ "1" ]] && echo "/opt/nezha/dashboard" )
                $( [[ "$categories" =~ "2" ]] && echo "/etc/x-ui/x-ui.db /usr/local/x-ui/bin/config.json" )
                $( [[ "$categories" =~ "3" ]] && echo "/etc/ufw/applications.d/custom" )
                $( [[ "$categories" =~ "4" ]] && echo "/root/cert" )
                $( [[ "$categories" =~ "5" ]] && echo "/opt/compose" )
            echo "✅ 还原完成"
            for c in "${stop_list[@]}"; do
                [[ "$c" != "all" ]] && docker start "$c" &>/dev/null
            done
            [[ " ${stop_list[*]} " =~ "all" ]] && docker start $(docker ps -aq) &>/dev/null
            echo "🔹 已启用容器: ${stop_list[*]}"
            read -n1 -s -r -p "按任意键返回主菜单..." </dev/tty
            ;;
        0)
            break
            ;;
        *)
            echo "⚠️ 无效输入，请重新选择"
            sleep 1
            ;;
    esac
done