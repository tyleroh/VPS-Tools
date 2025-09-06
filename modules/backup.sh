#!/bin/bash
# ===============================
# VPS 系统备份/还原模块
# ===============================
# 作者: Tyler
# 说明:
#   - 主菜单放在脚本顶部
#   - 支持模块化备份/还原
#   - 支持 tar.gz / zip 备份文件
#   - 自动处理套一层目录的备份
#   - 支持停用 Docker 容器
# ===============================

# ------------------------------
# 主菜单
# ------------------------------
show_main_menu() {
    while true; do
        clear
        echo "=============================="
        echo "   系统备份/还原模块"
        echo "=============================="
        echo "1) 系统备份"
        echo "2) 系统还原"
        echo "0) 退出"
        echo "=============================="
        read -rp "请输入序号: " choice

        case $choice in
            1) backup_system ;;
            2) restore_system ;;
            0) exit 0 ;;
            *) echo "⚠️ 无效输入"; sleep 1 ;;
        esac
    done
}

# ------------------------------
# 配置区：安装目录 & 备份目录
# ------------------------------
INSTALL_DIR="/opt/vps-tools"
BACKUP_DIR="$INSTALL_DIR/backup"
mkdir -p "$BACKUP_DIR"

# ------------------------------
# 模块定义（新增或删除模块请修改此处）
# 格式: "模块名:/绝对路径1 /绝对路径2 ..."
# ------------------------------
MODULES=(
    "docker:/opt/compose"
    "nezha:/opt/nezha/dashboard"
    "ssl:/root/cert"
    "ufw:/etc/ufw/applications.d/custom"
    "xpanel:/etc/x-ui/x-ui.db /usr/local/x-ui/bin/config.json"
)

# ===============================
# 通用函数
# ===============================

validate_choice() {
    local input="$1"
    local max="$2"
    local allow_all="$3"
    local result=()
    for i in $input; do
        if [[ "$i" =~ ^[0-9]+$ ]] && [ "$i" -ge 1 ] && [ "$i" -le "$max" ]; then
            [[ ! " ${result[@]} " =~ " $i " ]] && result+=("$i")
        elif [[ "$allow_all" == "yes" ]] && [[ "$i" == "a" || "$i" == "all" ]]; then
            echo "all"
            return
        fi
    done
    echo "${result[@]}"
}

stop_docker_containers() {
    local containers=("$@")
    local stop_list=()
    if [ ${#containers[@]} -eq 0 ]; then
        return
    fi

    echo "可选择停用的 Docker 容器（Enter跳过, 0返回上级）"
    for i in "${!containers[@]}"; do
        printf " %d) %s\n" "$((i+1))" "${containers[$i]}"
    done
    echo " a) all"

    read -rp "请选择要停用的容器序号: " docker_choice
    [[ -z "$docker_choice" ]] && return
    [[ "$docker_choice" == "0" ]] && return

    valid_indices=$(validate_choice "$docker_choice" "${#containers[@]}" "yes")
    if [[ "$valid_indices" == "all" ]]; then
        stop_list=("${containers[@]}")
    else
        for idx in $valid_indices; do
            stop_list+=("${containers[$((idx-1))]}")
        done
    fi

    for c in "${stop_list[@]}"; do
        docker stop "$c" >/dev/null 2>&1
        echo "已停用容器: $c"
    done

    echo "${stop_list[@]}"
}

start_docker_containers() {
    local containers=("$@")
    for c in "${containers[@]}"; do
        docker start "$c" >/dev/null 2>&1
        echo "已启用容器: $c"
    done
}

# ===============================
# 系统备份函数
# ===============================
backup_system() {
    mapfile -t containers < <(docker ps --format "{{.Names}}")
    stop_list=($(stop_docker_containers "${containers[@]}"))

    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

    echo "[开始备份...]"
    echo "[备份目录/文件列表]:"
    tar_paths=""
    for m in "${MODULES[@]}"; do
        dirs=$(echo $m | cut -d: -f2)
        for dir in $dirs; do
            echo " $dir"
            tar_paths+="$dir "
        done
    done

    tar -czPf "$BACKUP_FILE" $tar_paths
    echo "✅ 备份完成: $BACKUP_FILE"

    [ ${#stop_list[@]} -gt 0 ] && start_docker_containers "${stop_list[@]}"
    read -n1 -s -r -p "按任意键返回主菜单..."
}

# ===============================
# 系统还原函数
# ===============================
restore_system() {
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

    while true; do
        read -rp "请输入要还原的备份文件序号 (0返回主菜单): " bidx
        [[ "$bidx" == "0" ]] && return
        valid_idx=$(validate_choice "$bidx" "${#backup_files[@]}")
        [[ -n "$valid_idx" ]] && break
        echo "⚠️ 无效序号，请重新输入"
    done
    BACKUP_FILE="$BACKUP_DIR/${backup_files[$((valid_idx-1))]}"

    echo "可还原分类:"
    for i in "${!MODULES[@]}"; do
        NAME=$(echo "${MODULES[$i]}" | cut -d: -f1)
        printf " %d) %s\n" "$((i+1))" "$NAME"
    done
    echo " a) 全部"

    while true; do
        read -rp "请输入要还原的分类序号 (空格分隔, 必须输入, 0返回主菜单): " cat_choice
        [[ "$cat_choice" == "0" ]] && return
        [[ -n "$cat_choice" ]] || { echo "⚠️ 必须指定还原分类"; continue; }
        valid_indices=$(validate_choice "$cat_choice" "${#MODULES[@]}" "yes")
        [[ -n "$valid_indices" ]] && break
        echo "⚠️ 无效输入，请重新输入"
    done

    restore_dirs=()
    if [[ "$valid_indices" == "all" ]]; then
        for m in "${MODULES[@]}"; do
            restore_dirs+=("$(echo $m | cut -d: -f2)")
        done
    else
        for idx in $valid_indices; do
            restore_dirs+=("$(echo ${MODULES[$((idx-1))]} | cut -d: -f2)")
        done
    fi

    # Docker 停用
    mapfile -t containers < <(docker ps --format "{{.Names}}")
    stop_list=($(stop_docker_containers "${containers[@]}"))

    # 解压备份
    TMP_DIR=$(mktemp -d)
    success_count=0

    if [[ "$BACKUP_FILE" == *.tar.gz ]]; then
        tar -xzf "$BACKUP_FILE" -C "$TMP_DIR"
    elif [[ "$BACKUP_FILE" == *.zip ]]; then
        unzip -oq "$BACKUP_FILE" -d "$TMP_DIR"
    fi

    # 自动处理顶层目录
    top_dirs=($(find "$TMP_DIR" -mindepth 1 -maxdepth 1))
    RESTORE_ROOT="$TMP_DIR"
    if [ ${#top_dirs[@]} -eq 1 ] && [ -d "${top_dirs[0]}" ]; then
        RESTORE_ROOT="${top_dirs[0]}"
    fi

    for dir in "${restore_dirs[@]}"; do
        rel_path=$(echo "$dir" | sed 's|^/||')
        src_path="$RESTORE_ROOT/$rel_path"

        if [ -d "$src_path" ]; then
            mkdir -p "$dir"
            cp -rp "$src_path/." "$dir/"
            echo "已还原目录: $dir"
            ((success_count++))
        elif [ -f "$src_path" ]; then
            mkdir -p "$(dirname "$dir")"
            cp -f "$src_path" "$dir"
            echo "已还原文件: $dir"
            ((success_count++))
        else
            echo "⚠️ 备份包中没有找到: $dir"
        fi
    done

    rm -rf "$TMP_DIR"

    [ $success_count -eq 0 ] && echo "❌ 还原失败" || echo "✅ 还原完成，成功恢复 $success_count 项"

    [ ${#stop_list[@]} -gt 0 ] && start_docker_containers "${stop_list[@]}"
    read -n1 -s -r -p "按任意键返回主菜单..."
}

# ===============================
# 启动主菜单
# ===============================
show_main_menu