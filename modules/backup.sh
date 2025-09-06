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
        echo "可选择停用的 Docker 容器（Enter跳过, 0返回上级）"
        for i in "${!containers[@]}"; do
            printf " %d) %s\n" "$((i+1))" "${containers[$i]}"
        done
        echo " a) all"

        while true; do
            read -rp "请选择停用的容器序号: " docker_choice
            [[ "$docker_choice" == "0" ]] && break
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

    # 解压
    if [[ "$BACKUP_FILE" == *.tar.gz ]]; then
        tar -xzf "$BACKUP_FILE" -C "$TMP_DIR"
    elif [[ "$BACKUP_FILE" == *.zip ]]; then
        unzip -oq "$BACKUP_FILE" -d "$TMP_DIR"
    fi

    # 自动处理顶层目录（兼容套一层目录的情况）
    top_dirs=($(find "$TMP_DIR" -mindepth 1 -maxdepth 1))
    if [ ${#top_dirs[@]} -eq 1 ] && [ -d "${top_dirs[0]}" ]; then
        RESTORE_ROOT="${top_dirs[0]}"
    else
        RESTORE_ROOT="$TMP_DIR"
    fi

    # 开始还原
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