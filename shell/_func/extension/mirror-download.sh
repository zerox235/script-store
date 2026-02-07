# ==================================================
# 镜像下载功能脚本
# [功能]：提供镜像下载等功能方法
# [示例]：load_inbuilt_script "extension/mirror-download"
# [日期]：2026-02-07
# [作者]：Kahle
# ==================================================



# 镜像地址使用方法：前缀代理型镜像加速、域名替换型镜像加速
# Github镜像列表（使用换行符分隔）
github_mirrors=$(cat << 'EOF'
https://ghfast.top/https://github.com
https://v6.gh-proxy.org/https://github.com
https://hk.gh-proxy.org/https://github.com
https://cdn.gh-proxy.org/https://github.com
https://edgeone.gh-proxy.org/https://github.com
EOF
)
githubusercontent_mirrors=$(cat << 'EOF'
https://ghfast.top/https://raw.githubusercontent.com
https://v6.gh-proxy.org/https://raw.githubusercontent.com
https://hk.gh-proxy.org/https://raw.githubusercontent.com
https://cdn.gh-proxy.org/https://raw.githubusercontent.com
https://edgeone.gh-proxy.org/https://raw.githubusercontent.com
EOF
)


# ======== 镜像下载 ========
# 功能: 优先尝试镜像地址下载，失败后回退到原始地址
# 参数1: 下载URL
# 参数2: 目标文件路径（可选，完整路径包含文件名，为空时从URL提取文件名保存到当前目录）
# 参数3: 存在策略（可选，默认skip）: skip=跳过, overwrite=覆盖, backup=备份后覆盖
# 参数4: 额外下载参数（可选，用于curl或wget的额外参数，如Cookie等）
# 返回值: 0=成功, 1=失败
# 示例[基本下载]: download_by_mirror "https://github.com/demo/repo.zip" "/tmp/repo.zip"
download_by_mirror() {
    local file_url="$1"
    local file_path="$2"
    local exist_strategy="$3"
    local extra_params="$4"
    # 检查参数是否为空
    if [ -z "$file_url" ]; then
        log_error "错误: 必须提供下载URL"
        return 1
    fi
    # 从URL中提取域名
    local domain=$(echo "$file_url" | sed -e 's|^[a-zA-Z]*://||' -e 's|/.*$||' -e 's|:.*$||')
    # 根据域名获取对应的镜像列表
    local mirror_list=""
    case "$domain" in
        github.com)
            mirror_list="$github_mirrors"
            ;;
        raw.githubusercontent.com)
            mirror_list="$githubusercontent_mirrors"
            ;;
    esac
    # 保存原始URL
    local original_url="$file_url"
    # 下载成功标志，尝试镜像下载
    local download_success=1
    if [ -n "$mirror_list" ]; then
        # 解析镜像列表，将镜像地址转换为数组元素
        IFS=$'\n' read -r -d '' -a mirrors <<< "$mirror_list" || true
        local mirror_count=${#mirrors[@]}
        log_info "检测到 $domain 支持镜像加速，共有 $mirror_count 个镜像可用"
        # 遍历镜像列表，尝试下载
        local idx=1
        for mirror_base in "${mirrors[@]}"; do
            # 构建镜像URL
            local mirror_url=$(echo "$file_url" | sed "s|https://${domain}|${mirror_base}|")
            log_info "尝试镜像下载 ($idx/$mirror_count): $mirror_url"
            # 尝试下载镜像
            if download "$mirror_url" "$file_path" "$exist_strategy" "$extra_params"; then
                download_success=0
                log_info "镜像下载成功"
                return 0
            fi
            # 下载失败时，删除临时文件
            log_warn "镜像下载失败，尝试下一个镜像"
            rm -f "$file_path"
            idx=$((idx + 1))
        done
        log_warn "所有镜像下载失败，尝试原始地址"
    fi
    # 镜像列表为空时/镜像列表下载失败时，尝试原始地址下载
    log_info "尝试原始地址下载: $original_url"
    if download "$original_url" "$file_path" "$exist_strategy" "$extra_params"; then
        download_success=0
        log_info "原始地址下载成功"
    else
        log_error "错误: 所有地址下载均失败"
    fi
    # 返回下载成功标志
    return $download_success
}
# =========================



