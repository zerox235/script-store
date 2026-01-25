#!/bin/bash
# ==================================================
# 基础功能脚本
# [功能]：基础功能脚本，提供了日志、远程引入等方法
# [日期]：2025-12-04
# [作者]：Kahle
# ==================================================


# ======== 【引入方式】 ========
# [进程替换]：无磁盘I/O，使用管道内存传输，更快（需要给文件授权，通过 ./test.sh 执行）
#remote_script="https://demo/test.sh"; source <(curl -Ls "$remote_script")
# [临时文件]：有磁盘写入和读取操作，适合处理大文件
#{ remote_script="https://demo/test.sh"; temp_file=$(mktemp) && curl -Ls "$remote_script" > "$temp_file" && source "$temp_file"; rm -f "$temp_file"; }
# 引入公共脚本（ curl -Ls 可以替换为 wget -qO- ）
#_D="/tmp/remote-func2512"; _F="$_D/_base.sh_$(date +%Y%m%d)"; _R="https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/shell/_func/_base.sh";
#mkdir -p "$_D" && { [ ! -f "$_F" ] && curl -Ls "$_R" > "$_F" || true; } && source "$_F"; find "$_D" -name "_base.sh_*" -mtime +1 -delete 2>/dev/null &
# =============================


# ======== 【常用常量】 ========
# 脚本文件名称
readonly script_file_name="$(basename "$0")";
# 日志颜色
readonly log_color_no='\033[0m';
readonly log_color_red='\033[0;31m';
readonly log_color_green='\033[0;32m';
readonly log_color_blue='\033[0;34m';
readonly log_color_yellow='\033[1;33m';
# =============================


# ======== 通用日志方法 ========
# 参数1: 日志级别
# 参数2: 颜色代码（默认: LOG_COLOR_NO）
# 参数3: 是否输出到stderr（1=是, 0=否, 默认：0）
# 参数4+: 日志消息
_log() {
    local level="$1"
    local color="${2:-$log_color_no}"
    local to_stderr="${3:-0}"
    local message="${@:4}"
    # 构建时间戳，构造日志消息
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_message="${timestamp} ${color}[${level}]${log_color_no} ${message}"
    # 根据to_stderr决定输出位置
    if [[ ${to_stderr} -eq 1 ]]; then
        echo -e "${log_message}" >&2
    else
        echo -e "${log_message}"
    fi
}
# ==============================


# ======== 常用日志方法 ========
log_info()  { _log "INFO " "${log_color_green}"   0 "$@"; }
log_info1() { _log "INFO " "${log_color_blue}"    0 "$@"; }
log_warn()  { _log "WARN " "${log_color_yellow}"  0 "$@"; }
log_error() { _log "ERROR" "${log_color_red}"     1 "$@"; }
# ==============================


# ======== 方法开始、结束日志方法 ========
# 示例：
#log_method_start "方法描述"
#log_method_end
log_method_start() {
    log_info1 ">>>>>>>>>>>>>>>> [start] >>>>>>>>>>>>>>>>";
    log_info1 ">>>> $1 <<<<";
}
log_method_end() {
    log_info1 "<<<<<<<<<<<<<<<< [ end ] <<<<<<<<<<<<<<<<\n";
}
# =====================================


# ======== 检查root权限 ========
# 描述: 检查当前用户是否具有root权限
# 返回值: 0=是root, 1=非root
# 示例[检查权限并退出]: if ! check_root; then exit 1; fi
check_root() {
    local uid who
    # 基于uid检查是否为root用户
    if type id >/dev/null 2>&1; then
        uid=$(id -u)
        if [ "$uid" -eq 0 ] 2>/dev/null; then
            return 0
        fi
    fi
    # 基于EUID检查是否为root用户
    if [ -n "$EUID" ] && [ "$EUID" -eq 0 ] 2>/dev/null; then
        return 0
    fi
    # 基于whoami检查是否为root用户
    if type whoami >/dev/null 2>&1; then
        who=$(whoami)
        if [ "$who" = "root" ]; then
            return 0
        fi
    fi
    # 其他情况，提示错误
    log_error "错误: 需要root权限" >&2
    log_error "请使用: sudo $0 $*" >&2
    return 1
}
# =============================


# ======== 创建目录/确保目录存在 ========
# 参数: 一个或多个目录路径
# 返回值: 0=全部成功, 非0=存在失败
# 示例[创建单个目录]: mkdirs "/tmp/logs" || exit 1
# 示例[创建多个目录]: mkdirs "/tmp/logs" "/var/run" "/opt/bin" || exit 1
mkdirs() {
    local failed=0
    for dir in "$@"; do
        if ! mkdir -p "$dir" 2>/dev/null; then
            log_error "无法创建目录: $dir" >&2
            failed=1
        fi
    done
    return $failed
}
# =====================================


# ======== 文件下载 ========
# 功能: 文件下载
# 参数1: 下载URL
# 参数2: 目标文件路径（可选，完整路径包含文件名，为空时从URL提取文件名保存到当前目录）
# 参数3: 存在策略（可选，默认skip）: skip=跳过, overwrite=覆盖, backup=备份后覆盖
# 参数4: 额外下载参数（可选，用于curl或wget的额外参数，如Cookie等）
# 返回值: 0=成功, 1=失败
# 示例[基本下载]: download "https://example.com/file.tar.gz" "/tmp/file.tar.gz"
# 示例[覆盖下载]: download "https://example.com/file.tar.gz" "/tmp/file.tar.gz" "overwrite"
# 示例[带Cookie下载]: download "https://example.com/file.tar.gz" "/tmp/file.tar.gz" "skip" "-b \"oraclelicense=accept-securebackup-cookie\""
download() {
    local file_url="$1"
    local file_path="$2"
    local exist_strategy="${3:-skip}"
    local extra_params="${4:-}"
    # 校验必需参数
    if [[ -z "$file_url" ]]; then
        log_error "错误: 必须提供下载URL"
        return 1
    fi
    # 处理目标路径为空的情况
    if [[ -z "$file_path" ]]; then
        local filename=$(basename "$file_url")
        if [[ -z "$filename" || "$filename" == "." || "$filename" == "/" ]]; then
            log_error "错误: 无法从URL提取文件名，请提供目标文件路径"
            return 1
        fi
        file_path="./$filename"
        log_info "目标路径未指定，默认保存到当前目录: $file_path"
    fi
    # 解析目标路径
    local file_dir=$(dirname "$file_path")
    local filename=$(basename "$file_path")
    # 创建目标目录
    mkdir -p "$file_dir" || {
        log_error "错误: 无法创建目标目录 $file_dir"
        return 1
    }
    # 处理目标文件已存在的情况
    if [[ -f "$file_path" ]]; then
        case "$exist_strategy" in
            "skip")
                log_warn "文件已存在，跳过下载: $file_path"
                return 0
                ;;
            "overwrite")
                log_info "文件已存在，将覆盖下载: $file_path"
                rm -f "$file_path"
                ;;
            "backup")
                local backup_path="${file_path}.bak"
                log_info "文件已存在，备份到: $backup_path"
                mv "$file_path" "$backup_path"
                ;;
            *)
                log_error "错误: 未知的存在策略: $exist_strategy"
                return 1
                ;;
        esac
    fi
    # 执行下载操作，依次尝试curl、wget、openssl
    local download_success=0
    if command -v curl &> /dev/null; then
        log_info "使用curl下载: $file_url -> $file_path"
        if ! curl -L -o "$file_path" $extra_params "$file_url"; then
            log_error "错误: curl下载失败"
            download_success=1
        fi
    elif command -v wget &> /dev/null; then
        log_info "使用wget下载: $file_url -> $file_path"
        if ! wget --no-check-certificate --no-cookies -O "$file_path" $extra_params "$file_url"; then
            log_error "错误: wget下载失败"
            download_success=1
        fi
    elif command -v openssl &> /dev/null; then
        local host=$(echo "$file_url" | awk -F/ '{print $3}')
        local path=$(echo "$file_url" | cut -d/ -f4- | sed 's/ /%20/g')
        local port=443
        if [[ "$file_url" == http://* ]]; then
            port=80
        fi
        log_info "使用OpenSSL下载: $file_url -> $file_path"
        if [[ "$file_url" == https://* ]]; then
            printf "GET /%s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n" "$path" "$host" | openssl s_client -connect "$host:$port" -quiet 2>/dev/null | sed '1,/^\r$/d' > "$file_path"
        else
            exec 3<>/dev/tcp/"$host"/"$port"
            printf "GET /%s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n" "$path" "$host" >&3
            cat <&3 | sed '1,/^\r$/d' > "$file_path"
            exec 3>&-
        fi
        if [[ ! -s "$file_path" ]]; then
            log_error "错误: OpenSSL下载失败"
            download_success=1
        fi
    else
        log_error "错误: 未找到curl或wget，无法下载"
        return 1
    fi
    # 下载失败处理
    if [[ $download_success -eq 1 ]]; then
        rm -f "$file_path"
        return 1
    fi
    # 验证下载文件是否存在
    if [[ ! -f "$file_path" ]]; then
        log_error "错误: 下载后文件不存在，请检查权限或磁盘空间"
        return 1
    fi
    # 验证下载文件是否为空
    if [[ ! -s "$file_path" ]]; then
        log_error "错误: 下载文件为空"
        rm -f "$file_path"
        return 1
    fi
    # 下载完成
    log_info "下载完成: $file_path"
    return 0
}
# =========================


# ======== 下载并执行远程脚本 ========
# 参数1: 远程脚本URL
# 参数2: 本地缓存目录（可选，默认/tmp/remote-func2512）
# 参数3: 缓存天数（可选，默认1天）
# 示例[基本用法]：load_remote_script "远程脚本的URL"
# 示例[指定缓存目录和缓存天数]：load_remote_script "远程脚本的URL" "/tmp/myscripts" 3
load_remote_script() {
    local remote_script_url="$1"
    local cache_dir="${2:-/tmp/remote-func2512}"
    local cache_days="${3:-1}"
    # 验证参数
    if [[ -z "$remote_script_url" ]]; then
        log_error "错误: 必须提供远程脚本URL"
        return 1
    fi
    # 提取脚本文件名
    local script_name=$(basename "$remote_script_url")
    local cache_file="$cache_dir/${script_name}_$(date +%Y%m%d)"
    # 创建缓存目录
    mkdir -p "$cache_dir" || {
        log_error "错误: 无法创建缓存目录 $cache_dir"
        return 1
    }
    # 下载脚本（如果缓存不存在）
    if [[ ! -f "$cache_file" ]]; then
        if ! download "$remote_script_url" "$cache_file" "overwrite"; then
            log_error "错误: 下载失败"
            return 1
        fi
    else
        log_info "使用缓存: $cache_file"
    fi
    # 执行脚本
    source "$cache_file" || {
        log_error "错误: 脚本执行失败"
        return 1
    }
    # 清理旧缓存（后台执行）
    if [[ -d "$cache_dir" ]]; then
        (find "$cache_dir" -name "${script_name}_*" -mtime "+${cache_days}" -delete 2>/dev/null) &
    fi
    # 结束
    return 0
}
# ==================================





