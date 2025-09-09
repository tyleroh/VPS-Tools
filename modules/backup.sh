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

mkdir -p "$BACKUP_DIR"

# 输入校验函数，增加去重功能
validate_choice() {
    local input="$1"
    local max="$2"
    local allow_all="$3"
    local result=()
    for i in $input; do
        if [[ "$i" =~ ^[0-9]+$ ]] && [ "$i" -ge 1 ] && [ "$i" -le "$max" ]; then
            if [[ ! " ${result[@]} " =~ " $i " ]]; then
                result+=("$i")
            fi
        elif [[ "$allow_all" == "yes" ]] && [[ "$i" == "a" || "$i" == "all" ]]; then
            echo "all"
            return
        fi
    done
    echo "${result[@]}"
}

while true; do
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
        0) break ;;
        1)
            # ------------------- 系统备份 -------------------
            mapfile -t containers < <(docker ps --format "{{.Names}}")
            stop_list=()
            if [ ${#containers[@]} -gt 0 ]; then
                echo "可选择停用的 Docker 容器:"
                for i in "${!containers[@]}"; do
                    printf " %d) %s\n" "$((i+1))" "${containers[$i]}"
                done
                echo " a) all"

                read -rp "请输入序号(空格分隔, Enter跳过, 0返回主菜单): " docker_choice
                [[ "$docker_choice" == "0" ]] && continue
                if [[ -n "$docker_choice" ]]; then
                    valid_indices=$(validate_choice "$docker_choice" "${#containers[@]}" "yes")
                    if [[ "$valid_indices" == "all" ]]; then
                        stop_list=("${containers[@]}")
                    elif [[ -n "$valid_indices" ]]; then
                        for idx in $valid_indices; do
                            stop_list+=("${containers[$((idx-1))]}")
                        done
                    fi
                    for c in "${stop_list[@]}"; do
                        docker stop "$c" >/dev/null 2>&1
                        echo "已停用容器: $c"
                    done
                fi
            fi

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

            if [ ${#stop_list[@]} -gt 0 ]; then
                for c in "${stop_list[@]}"; do
                    docker start "$c" >/dev/null 2>&1
                    echo "已恢复容器: $c"
                done
            fi

            read -n1 -s -r -p "按任意键返回主菜单..."
            ;;
        2)
            # ------------------- 系统还原 -------------------
            mapfile -t backup_files < <(ls -1t "$BACKUP_DIR" | grep -E '\.tar\.gz|\.zip')
            if [ ${#backup_files[@]} -eq 0 ]; then
                echo "⚠️ 没有备份文件"
                read -n1 -s -r -p "按任意键返回主菜单..."
                continue
            fi

            echo "可用的备份文件:"
            for i in "${!backup_files[@]}"; do
                printf " %d) %s\n" "$((i+1))" "${backup_files[$i]}"
            done

            while true; do
                read -rp "请输入要还原的备份文件序号 (0返回主菜单): " bidx
                [[ "$bidx" == "0" ]] && continue 2
                valid_idx=$(validate_choice "$bidx" "${#backup_files[@]}")
                if [[ -z "$valid_idx" ]]; then
                    echo "⚠️ 无效序号，请重新输入"
                else
                    break
                fi
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
                [[ "$cat_choice" == "0" ]] && continue 2
                if [[ -z "$cat_choice" ]]; then
                    echo "⚠️ 必须指定还原分类"
                    continue
                fi
                valid_indices=$(validate_choice "$cat_choice" "${#MODULES[@]}" "yes")
                if [[ -z "$valid_indices" ]]; then
                    echo "⚠️ 无效输入，请重新输入"
                else
                    break
                fi
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

            # ------------------- Docker 停用选择 -------------------
            mapfile -t containers < <(docker ps --format "{{.Names}}")
            stop_list=()
            if [ ${#containers[@]} -gt 0 ]; then
                echo "可选择停用的 Docker 容器（Enter跳过, 0返回主菜单）"
                for i in "${!containers[@]}"; do
                    printf " %d) %s\n" "$((i+1))" "${containers[$i]}"
                done
                echo " a) all"

                while true; do
                    read -rp "请选择停用的容器序号: " docker_choice
                    [[ "$docker_choice" == "0" ]] && continue 2  # <-- 改这里，输入0直接返回主菜单
                    if [[ -z "$docker_choice" ]]; then
                        break
                    fi
                    valid_indices=$(validate_choice "$docker_choice" "${#containers[@]}" "yes")
                    if [[ -z "$valid_indices" ]]; then
                        echo "⚠️ 无效输入，请重新输入"
                    else
                        if [[ "$valid_indices" == "all" ]]; then
                            stop_list=("${containers[@]}")
                        else
                            for idx in $valid_indices; do
                                stop_list+=("${containers[$((idx-1))]}")
                            done
                        fi
                        break
                    fi
                done

                for c in "${stop_list[@]}"; do
                    docker stop "$c" >/dev/null 2>&1
                    echo "已停用容器: $c"
                done
            fi

            # ------------------- 解压还原 -------------------
            TMP_DIR=$(mktemp -d)
            success_count=0

            if [[ "$BACKUP_FILE" == *.tar.gz ]]; then
                tar -xzf "$BACKUP_FILE" -C "$TMP_DIR"
            elif [[ "$BACKUP_FILE" == *.zip ]]; then
                unzip -oq "$BACKUP_FILE" -d "$TMP_DIR"
            fi

            # --- 兼容套了一层目录 ---
            top_level_count=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
            if [ "$top_level_count" -eq 1 ]; then
                TMP_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d)
            fi
            # ----------------------------------------------

            for dir in "${restore_dirs[@]}"; do
                rel_path=$(echo "$dir" | sed 's|^/||')
                src_path="$TMP_DIR/$rel_path"

                if [ -d "$src_path" ]; then
                    mkdir -p "$dir"
                    cp -rp "$src_path/." "$dir/"
                    echo "已还原目录: $dir"
                    ((success_count++))
                elif [ -f "$src_path" ]; then
                    mkdir -p "$(dirname "$dir")"
                    cp -fp "$src_path" "$dir"
                    echo "已还原文件: $dir"
                    ((success_count++))
                else
                    echo "⚠️ 备份包中没有找到: $dir"
                fi
            done

            rm -rf "$TMP_DIR"

            if [ $success_count -eq 0 ]; then
                echo "❌ 还原失败，未成功恢复任何目录或文件"
            else
                echo "✅ 还原完成，成功恢复 $success_count 项"
            fi

            if [ ${#stop_list[@]} -gt 0 ]; then
                for c in "${stop_list[@]}"; do
                    docker start "$c" >/dev/null 2>&1
                    echo "已启用容器: $c"
                done
            fi

            read -n1 -s -r -p "按任意键返回主菜单..."
            ;;
        *)
            echo "⚠️ 无效输入"
            sleep 1
            ;;
    esac
done
