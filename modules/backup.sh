#!/bin/bash
# VPS工具箱 - 系统备份/还原模块
# By Bai

INSTALL_DIR="/opt/vps-tools"
BACKUP_DIR="$INSTALL_DIR/backup"
LOG_DIR="$INSTALL_DIR/logs"
LOG_FILE="$LOG_DIR/backup.log"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# 文件分类，后续增加直接在这里添加
declare -A FILE_GROUPS=(
    ["docker"]="/opt/compose"
    ["nezha"]="/opt/nezha/dashboard"
    ["ssl"]="/root/cert"
    ["ufw"]="/etc/ufw/applications.d/custom"
    ["xpanel"]="/etc/x-ui/x-ui.db /usr/local/x-ui/bin/config.json"
)

pause() { read -n1 -s -r -p "按任意键返回..."; }

# 日志记录函数
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

# 获取所有正在运行的容器
list_containers() {
    docker ps --format '{{.Names}}'
}

# 停用指定容器
stop_containers() {
    local containers=("$@")
    local stopped=()
    for c in "${containers[@]}"; do
        if docker ps -q -f name="^$c$" | grep -q .; then
            docker stop "$c" >/dev/null
            stopped+=("$c")
        fi
    done
    echo "${stopped[@]}"
}

# 启动指定容器
start_containers() {
    local containers=("$@")
    for c in "${containers[@]}"; do
        docker start "$c" >/dev/null
    done
}

# 系统备份
do_backup() {
    echo "正在列出运行中的 Docker 容器..."
    mapfile -t containers < <(list_containers)
    containers+=("all")
    to_stop=()
    if [[ ${#containers[@]} -gt 0 ]]; then
        echo "可选择停用的容器（空格分隔，多选）："
        i=1
        for c in "${containers[@]}"; do
            echo " $i) $c"
            i=$((i+1))
        done
        read -p "请输入序号: " sel
        sel_idx=($sel)
        for idx in "${sel_idx[@]}"; do
            idx=$((idx-1))
            [[ $idx -ge 0 && $idx -lt ${#containers[@]} ]] && to_stop+=("${containers[$idx]}")
        done
        if [[ " ${to_stop[*]} " =~ " all " ]]; then
            mapfile -t to_stop < <(list_containers)
        fi
    fi

    [[ ${#to_stop[@]} -gt 0 ]] && log "停用容器: ${to_stop[*]}" && stop_containers "${to_stop[@]}"

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"
    log "=== 开始备份 ==="
    log "备份文件: $BACKUP_FILE"

    tar -czvf "$BACKUP_FILE" \
        "${FILE_GROUPS["docker"]}" \
        "${FILE_GROUPS["nezha"]}" \
        "${FILE_GROUPS["ssl"]}" \
        ${FILE_GROUPS["ufw"]} \
        ${FILE_GROUPS["xpanel"]} 2>&1 | tee -a "$LOG_FILE"

    # 保留最新10个备份
    cd "$BACKUP_DIR"
    ls -1t backup_*.tar.gz | tail -n +11 | xargs -r rm -f

    log "=== 备份完成 ==="
    [[ ${#to_stop[@]} -gt 0 ]] && start_containers "${to_stop[@]}"
    pause
}

# 系统还原
do_restore() {
    echo "可用的备份文件："
    mapfile -t backups < <(ls -1t "$BACKUP_DIR"/backup_*.tar.gz "$BACKUP_DIR"/backup_*.zip 2>/dev/null)
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo "没有找到备份文件！"
        pause
        return
    fi

    i=1
    for f in "${backups[@]}"; do
        echo " $i) $(basename "$f")"
        i=$((i+1))
    done
    read -p "请输入要还原的备份文件序号: " idx
    restore_file="${backups[$((idx-1))]}"
    [[ ! -f "$restore_file" ]] && echo "选择无效！" && return
    log "=== 开始还原 ==="
    log "选择备份文件: $(basename "$restore_file")"

    echo "正在列出运行中的 Docker 容器..."
    mapfile -t containers < <(list_containers)
    containers+=("all")
    to_stop=()
    if [[ ${#containers[@]} -gt 0 ]]; then
        echo "可选择停用的容器（空格分隔，多选）："
        i=1
        for c in "${containers[@]}"; do echo " $i) $c"; i=$((i+1)); done
        read -p "请输入序号: " sel
        sel_idx=($sel)
        for idx in "${sel_idx[@]}"; do
            idx=$((idx-1))
            [[ $idx -ge 0 && $idx -lt ${#containers[@]} ]] && to_stop+=("${containers[$idx]}")
        done
        if [[ " ${to_stop[*]} " =~ " all " ]]; then
            mapfile -t to_stop < <(list_containers)
        fi
    fi
    [[ ${#to_stop[@]} -gt 0 ]] && log "停用容器: ${to_stop[*]}" && stop_containers "${to_stop[@]}"

    # 还原文件选择
    echo "可还原分类："
    i=1
    keys=("${!FILE_GROUPS[@]}")
    for k in "${keys[@]}"; do
        echo " $i) $k"
        i=$((i+1))
    done
    echo " all) 全部"
    read -p "请输入要还原的分类序号(空格分隔): " sel
    restore_choice=($sel)
    log "还原分类: ${restore_choice[*]}"

    TMPDIR=$(mktemp -d)
    if [[ "$restore_file" == *.tar.gz ]]; then
        tar -xzf "$restore_file" -C "$TMPDIR"
    elif [[ "$restore_file" == *.zip ]]; then
        unzip -q "$restore_file" -d "$TMPDIR"
    fi

    if [[ " ${restore_choice[*]} " =~ " all " ]]; then
        cp -r "$TMPDIR"/* /
    else
        for idx in "${restore_choice[@]}"; do
            idx=$((idx-1))
            k="${keys[$idx]}"
            for path in ${FILE_GROUPS[$k]}; do
                cp -r "$TMPDIR$path" "$path"
            done
        done
    fi
    rm -rf "$TMPDIR"
    log "=== 还原完成 ==="

    if [[ ${#to_stop[@]} -gt 0 ]]; then
        read -p "是否重启刚才停用的容器？(y/n): " yn
        [[ "$yn" == "y" ]] && start_containers "${to_stop[@]}" && log "重启容器: ${to_stop[*]}"
    fi
    pause
}

# 主菜单
while true; do
    clear
    echo "=============================="
    echo "      系统备份/还原模块"
    echo "=============================="
    echo "1) 系统备份"
    echo "2) 系统还原"
    echo "0) 返回主菜单"
    echo "=============================="
    read -rp "请输入序号: " choice
    case $choice in
        1) do_backup ;;
        2) do_restore ;;
        0) break ;;
        *) echo "无效输入" && sleep 1 ;;
    esac
done
