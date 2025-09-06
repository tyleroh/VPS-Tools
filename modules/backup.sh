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
            # -------------------
            # 系统备份
            # -------------------
            mapfile -t containers < <(docker ps --format "{{.Names}}")
            stop_list=()
            if [ ${#containers[@]} -gt 0 ]; then
                echo "可选择停用的 Docker 容器:"
                for i in "${!containers[@]}"; do
                    printf " %d) %s\n" "$((i+1))" "${containers[$i]}"
                done
                echo " a) all"
                read -rp "请输入序号(空格分隔, Enter跳过): " docker_choice

                if [[ -n "$docker_choice" ]]; then
                    if [[ "$docker_choice" == *"a"* || "$docker_choice" == *"all"* ]]; then
                        stop_list=("${containers[@]}")
                    else
                        for idx in $docker_choice; do
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
                paths=$(echo "$m" | cut -d: -f2)
                for p in $paths; do
                    echo " $p"
                    tar_paths+="$p "
                done
            done

            # 使用绝对路径备份
            tar -czPf "$BACKUP_FILE" $tar_paths
            echo "✅ 备份完成: $BACKUP_FILE"

            # 恢复被停用的容器
            if [ ${#stop_list[@]} -gt 0 ]; then
                for c in "${stop_list[@]}"; do
                    docker start "$c" >/dev/null 2>&1
                    echo "已恢复容器: $c"
                done
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
                continue
            fi

            echo "可用的备份文件:"
            for i in "${!backup_files[@]}"; do
                printf " %d) %s\n" "$((i+1))" "${backup_files[$i]}"
            done
            read -rp "请输入要还原的备份文件序号 (0返回主菜单): " bidx
            [[ "$bidx" == "0" ]] && continue

            if ! [[ "$bidx" =~ ^[0-9]+$ ]] || [ "$bidx" -lt 1 ] || [ "$bidx" -gt "${#backup_files[@]}" ]; then
                echo "⚠️ 请选择有效的备份文件"
                read -n1 -s -r -p "按任意键返回主菜单..."
                continue
            fi
            BACKUP_FILE="$BACKUP_DIR/${backup_files[$((bidx-1))]}"

            echo "可还原分类:"
            for i in "${!MODULES[@]}"; do
                NAME=$(echo "${MODULES[$i]}" | cut -d: -f1)
                printf " %d) %s\n" "$((i+1))" "$NAME"
            done
            echo " a) 全部"
            read -rp "请输入要还原的分类序号 (空格分隔, 必须输入): " cat_choice

            if [[ -z "$cat_choice" ]]; then
                echo "⚠️ 必须指定还原分类"
                read -n1 -s -r -p "按任意键返回主菜单..."
                continue
            fi

            restore_dirs=()
            if [[ "$cat_choice" == "a" ]]; then
                for m in "${MODULES[@]}"; do
                    restore_dirs+=("$(echo ${m} | cut -d: -f2)")
                done
            else
                for idx in $cat_choice; do
                    restore_dirs+=("$(echo ${MODULES[$((idx-1))]} | cut -d: -f2)")
                done
            fi

            # 停用 Docker 容器可选
            mapfile -t containers < <(docker ps --format "{{.Names}}")
            stop_list=()
            if [ ${#containers[@]} -gt 0 ]; then
                echo "可选择停用的 Docker 容器（Enter跳过）"
                for i in "${!containers[@]}"; do
                    printf " %d) %s\n" "$((i+1))" "${containers[$i]}"
                done
                echo " a) all"
                read -rp "请选择停用的容器序号: " docker_choice

                if [[ -n "$docker_choice" ]]; then
                    if [[ "$docker_choice" == *"a"* || "$docker_choice" == *"all"* ]]; then
                        stop_list=("${containers[@]}")
                    else
                        for idx in $docker_choice; do
                            stop_list+=("${containers[$((idx-1))]}")
                        done
                    fi

                    for c in "${stop_list[@]}"; do
                        docker stop "$c" >/dev/null 2>&1
                        echo "已停用容器: $c"
                    done
                fi
            fi

            echo "[开始还原分类...]"
            restore_success=0

            TMP_DIR=$(mktemp -d)

            # 解压备份到临时目录
            if [[ "$BACKUP_FILE" == *.tar.gz ]]; then
                tar -xzf "$BACKUP_FILE" -C "$TMP_DIR"
            elif [[ "$BACKUP_FILE" == *.zip ]]; then
                unzip -q "$BACKUP_FILE" -d "$TMP_DIR"
            fi

            for item in "${restore_dirs[@]}"; do
                rel_path=$(echo "$item" | sed 's|^/||')
                src_path="$TMP_DIR/$rel_path"

                if [ -e "$src_path" ]; then
                    # 自动创建父目录
                    parent_dir=$(dirname "$item")
                    mkdir -p "$parent_dir"

                    if [ -d "$src_path" ]; then
                        mkdir -p "$item"
                        rsync -a "$src_path"/ "$item"/
                    else
                        cp -f "$src_path" "$item"
                    fi
                    echo "已还原: $item"
                    restore_success=1
                else
                    echo "⚠️ 备份包中没有找到: $item"
                fi
            done

            rm -rf "$TMP_DIR"

            # 恢复被停用的容器
            if [ ${#stop_list[@]} -gt 0 ]; then
                for c in "${stop_list[@]}"; do
                    docker start "$c" >/dev/null 2>&1
                    echo "已启用容器: $c"
                done
            fi

            if [ $restore_success -eq 1 ]; then
                echo "✅ 还原完成"
            else
                echo "❌ 还原失败，未成功恢复任何目录或文件"
            fi

            read -n1 -s -r -p "按任意键返回主菜单..."
            ;;
        *)
            echo "⚠️ 无效输入"
            sleep 1
            ;;
    esac
done