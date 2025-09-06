#!/bin/bash
# 系统备份/还原模块 - 最终版
# By Bai

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
        0) break ;;
        1)
            # 获取可停用容器
            mapfile -t containers < <(docker ps --format '{{.Names}}' | sort -u)
            containers+=("all")
            echo "可停用的 Docker 容器:"
            for i in "${!containers[@]}"; do
                echo " $((i+1))) ${containers[i]}"
            done
            read -rp "请输入序号(空格分隔, 0返回主菜单): " docker_choice
            [[ "$docker_choice" == "0" ]] && continue

            stop_list=()
            for idx in $docker_choice; do
                [[ $idx -le ${#containers[@]} ]] && stop_list+=("${containers[$((idx-1))]}")
            done
            [[ ${#stop_list[@]} -gt 0 ]] && echo "停用容器: ${stop_list[*]}"

            # 停用容器
            for c in "${stop_list[@]}"; do
                [[ "$c" != "all" ]] && docker stop "$c" &>/dev/null
            done
            [[ " ${stop_list[*]} " =~ "all" ]] && docker stop $(docker ps -q) &>/dev/null

            # 开始备份
            echo "开始备份..."
            echo "备份目录:"
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

            # 启动容器
            for c in "${stop_list[@]}"; do
                [[ "$c" != "all" ]] && docker start "$c" &>/dev/null
            done
            [[ " ${stop_list[*]} " =~ "all" ]] && docker start $(docker ps -aq) &>/dev/null
            [[ ${#stop_list[@]} -gt 0 ]] && echo "已恢复容器: ${stop_list[*]}"

            read -n1 -s -r -p "按任意键返回主菜单..." </dev/tty
            ;;
        2)
            # 系统还原
            files=($(ls -1t "$BACKUP_DIR"/backup_*.tar.gz "$BACKUP_DIR"/backup_*.zip 2>/dev/null))
            if [[ ${#files[@]} -eq 0 ]]; then
                echo "没有备份文件"
                read -n1 -s -r -p "按任意键返回主菜单..." </dev/tty
                continue
            fi

            echo "可用的备份文件:"
            for i in "${!files[@]}"; do
                echo " $((i+1))) $(basename "${files[i]}")"
            done
            read -rp "请输入要还原的备份文件序号 (0返回主菜单): " restore_choice
            [[ "$restore_choice" == "0" ]] && continue
            if ! [[ "$restore_choice" =~ ^[0-9]+$ ]] || (( restore_choice < 1 || restore_choice > ${#files[@]} )); then
                echo "请输入有效序号！"
                read -n1 -s -r -p "按任意键返回主菜单..." </dev/tty
                continue
            fi
            backup_file="${files[$((restore_choice-1))]}"

            echo "可还原分类:"
            echo " 1) nezha"
            echo " 2) xpanel"
            echo " 3) ufw"
            echo " 4) ssl"
            echo " 5) docker"
            echo " a) 全部"
            read -rp "请输入要还原的分类序号 (空格分隔, 0返回主菜单): " categories
            [[ "$categories" == "0" ]] && continue
            if [[ -z "$categories" ]]; then
                echo "未选择还原分类"
                read -n1 -s -r -p "按任意键返回主菜单..." </dev/tty
                continue
            fi

            # 停用 Docker 容器
            mapfile -t containers < <(docker ps --format '{{.Names}}' | sort -u)
            containers+=("all")
            echo "停用选择的 Docker 容器（如有）"
            for i in "${!containers[@]}"; do
                echo " $((i+1))) ${containers[i]}"
            done
            read -rp "请选择停用的容器序号 (空格分隔, 0返回主菜单): " docker_choice
            [[ "$docker_choice" == "0" ]] && continue

            stop_list=()
            for idx in $docker_choice; do
                [[ $idx -le ${#containers[@]} ]] && stop_list+=("${containers[$((idx-1))]}")
            done
            [[ ${#stop_list[@]} -gt 0 ]] && echo "停用容器: ${stop_list[*]}"
            for c in "${stop_list[@]}"; do
                [[ "$c" != "all" ]] && docker stop "$c" &>/dev/null
            done
            [[ " ${stop_list[*]} " =~ "all" ]] && docker stop $(docker ps -q) &>/dev/null

            # 开始还原
            echo "开始还原分类..."
            if [[ "$categories" =~ "a" ]]; then
                tar -xzf "$backup_file" -C / 2>/dev/null || unzip -o "$backup_file" -d /
            else
                for cat in $categories; do
                    case $cat in
                        1) tar -xzf "$backup_file" -C / opt/nezha/dashboard 2>/dev/null || unzip -o "$backup_file" -d /opt/nezha/dashboard ;; 
                        2) tar -xzf "$backup_file" -C / etc/x-ui 2>/dev/null || unzip -o "$backup_file" -d /etc/x-ui ;;
                        3) tar -xzf "$backup_file" -C / etc/ufw 2>/dev/null || unzip -o "$backup_file" -d /etc/ufw ;;
                        4) tar -xzf "$backup_file" -C / root 2>/dev/null || unzip -o "$backup_file" -d /root ;;
                        5) tar -xzf "$backup_file" -C / opt/compose 2>/dev/null || unzip -o "$backup_file" -d /opt/compose ;;
                    esac
                done
            fi
            echo "✅ 还原完成"

            # 启动 Docker 容器
            for c in "${stop_list[@]}"; do
                [[ "$c" != "all" ]] && docker start "$c" &>/dev/null
            done
            [[ " ${stop_list[*]} " =~ "all" ]] && docker start $(docker ps -aq) &>/dev/null
            [[ ${#stop_list[@]} -gt 0 ]] && echo "已启用容器: ${stop_list[*]}"

            read -n1 -s -r -p "按任意键返回主菜单..." </dev/tty
            ;;
        *)
            echo "输入错误，请重新选择"
            sleep 1
            ;;
    esac
done
