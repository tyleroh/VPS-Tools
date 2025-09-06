#!/bin/bash
# 系统备份/还原模块
INSTALL_DIR="/opt/vps-tools"
BACKUP_DIR="$INSTALL_DIR/backup"

MODULES=(
"docker:/opt/compose"
"nezha:/opt/nezha/dashboard"
"ssl:/root/cert"
"ufw:/etc/ufw/applications.d/custom"
"xpanel:/etc/x-ui/x-ui.db /usr/local/x-ui/bin/config.json"
)

clear
echo "=============================="
echo "   系统备份/还原模块"
echo "=============================="
echo "1) 系统备份"
echo "2) 系统还原"
echo "0) 返回主菜单"
echo "=============================="
read -rp "请输入序号: " choice

case $choice in
    0) return ;;
    1)
        # -------------------
        # 系统备份
        # -------------------
        # 获取正在运行的容器
        mapfile -t containers < <(docker ps --format "{{.Names}}")
        echo "可选择停用的 Docker 容器:"
        for i in "${!containers[@]}"; do
            printf " %d) %s\n" "$((i+1))" "${containers[$i]}"
        done
        echo " a) all"
        read -rp "请输入序号(空格分隔, 0返回主菜单): " docker_choice

        [[ "$docker_choice" == "0" ]] && return

        stop_list=()
        if [[ "$docker_choice" == *"a"* || "$docker_choice" == *"all"* ]]; then
            stop_list=("${containers[@]}")
        else
            for idx in $docker_choice; do
                stop_list+=("${containers[$((idx-1))]}")
            done
        fi

        # 停用选中容器
        if [ ${#stop_list[@]} -gt 0 ]; then
            echo "停用容器: ${stop_list[*]}"
            for c in "${stop_list[@]}"; do
                docker stop "$c" >/dev/null 2>&1
            done
        fi

        # 备份
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"
        echo "[开始备份...]"
        echo "[备份目录]"
        for m in "${MODULES[@]}"; do
            DIRS=$(echo "$m" | cut -d: -f2)
            echo " $DIRS"
        done
        tar -czf "$BACKUP_FILE" $(for m in "${MODULES[@]}"; do echo -n "$(echo $m | cut -d: -f2) "; done)

        # 恢复 Docker
        if [ ${#stop_list[@]} -gt 0 ]; then
            for c in "${stop_list[@]}"; do
                docker start "$c" >/dev/null 2>&1
            done
        fi

        echo "✅ 备份完成: $BACKUP_FILE"
        if [ ${#stop_list[@]} -gt 0 ]; then
            echo "已恢复容器: ${stop_list[*]}"
        fi
        read -n1 -s -r -p "按任意键返回主菜单..."
        ;;
    2)
        # -------------------
        # 系统还原
        # -------------------
        mapfile -t backup_files < <(ls -1t "$BACKUP_DIR" | grep -E '\.tar\.gz|\.zip')
        if [ ${#backup_files[@]} -eq 0 ]; then
            echo "⚠️ 没有备份文件"
            read -n1 -s -r -p "按任意键返回主菜单..."
            return
        fi

        echo "可用的备份文件:"
        for i in "${!backup_files[@]}"; do
            printf " %d) %s\n" "$((i+1))" "${backup_files[$i]}"
        done
        read -rp "请输入要还原的备份文件序号 (0返回主菜单): " bidx
        [[ "$bidx" == "0" ]] && return

        if ! [[ "$bidx" =~ ^[0-9]+$ ]] || [ "$bidx" -lt 1 ] || [ "$bidx" -gt "${#backup_files[@]}" ]; then
            echo "⚠️ 请选择有效的备份文件"
            read -n1 -s -r -p "按任意键返回主菜单..."
            return
        fi

        BACKUP_FILE="$BACKUP_DIR/${backup_files[$((bidx-1))]}"

        # 选择还原分类
        echo "可还原分类:"
        for i in "${!MODULES[@]}"; do
            NAME=$(echo "${MODULES[$i]}" | cut -d: -f1)
            printf " %d) %s\n" "$((i+1))" "$NAME"
        done
        echo " a) 全部"
        read -rp "请输入要还原的分类序号 (空格分隔, 0返回主菜单): " cat_choice
        [[ "$cat_choice" == "0" ]] && return

        restore_dirs=()
        if [[ "$cat_choice" == *"a"* ]]; then
            for m in "${MODULES[@]}"; do
                restore_dirs+=("$(echo $m | cut -d: -f2)")
            done
        else
            for idx in $cat_choice; do
                restore_dirs+=("$(echo ${MODULES[$((idx-1))]} | cut -d: -f2)")
            done
        fi

        # 停用 Docker
        mapfile -t containers < <(docker ps --format "{{.Names}}")
        echo "停用选择的 Docker 容器（如有）"
        for i in "${!containers[@]}"; do
            printf " %d) %s\n" "$((i+1))" "${containers[$i]}"
        done
        echo " a) all"
        read -rp "请选择停用的容器序号 (空格分隔, 0返回主菜单): " docker_choice
        [[ "$docker_choice" == "0" ]] && return

        stop_list=()
        if [[ "$docker_choice" == *"a"* || "$docker_choice" == *"all"* ]]; then
            stop_list=("${containers[@]}")
        else
            for idx in $docker_choice; do
                stop_list+=("${containers[$((idx-1))]}")
            done
        fi

        if [ ${#stop_list[@]} -gt 0 ]; then
            for c in "${stop_list[@]}"; do
                docker stop "$c" >/dev/null 2>&1
            done
        fi

        # 开始还原
        echo "[开始还原分类...]"
        for dir in "${restore_dirs[@]}"; do
            echo " $dir"
        done

        if [[ "$BACKUP_FILE" == *.tar.gz ]]; then
            tar -xzf "$BACKUP_FILE" -C /
        elif [[ "$BACKUP_FILE" == *.zip ]]; then
            unzip -o "$BACKUP_FILE" -d /
        fi

        if [ ${#stop_list[@]} -gt 0 ]; then
            for c in "${stop_list[@]}"; do
                docker start "$c" >/dev/null 2>&1
            done
        fi

        echo "✅ 还原完成"
        if [ ${#stop_list[@]} -gt 0 ]; then
            echo "已启用容器: ${stop_list[*]}"
        fi
        read -n1 -s -r -p "按任意键返回主菜单..."
        ;;
    *)
        echo "⚠️ 无效输入"
        sleep 1
        ;;
esac
