#!/bin/bash
# ==================================================
# EasyTier Web 服务管理脚本
# [功能]：支持启动/停止/重启操作，可配置使用 easytier-web-embed 或 easytier-web
# [文档]：https://easytier.cn/guide/network/web-console.html
# [日期]：2026-05-02
# [作者]：Kahle
# ==================================================


# 引入公共脚本（ curl -Ls 可以替换为 wget -qO- ）
_D="/tmp/remote-func2512"; _F="$_D/_base.sh_$(date +%Y%m%d)"; _R="https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/_func/_base.sh";
mkdir -p "$_D" && { [ ! -f "$_F" ] && curl -Ls "$_R" > "$_F" || true; } && source "$_F"; find "$_D" -name "_base.sh_*" -mtime +1 -delete 2>/dev/null &

# ======== 配置区域 ========
# 基础目录
base_dir="/opt/easytier"
# 选择运行模式: embed 或 web （EasyTier的web控制台有2个版本）
# embed: 使用 easytier-web-embed (web前端 + web api后端)
# web: 使用 easytier-web (仅web api后端)
run_mode="embed"
# 服务端口配置
api_server_port="11211"
api_host="http://127.0.0.1:11211"
config_server_port="22020"
config_server_protocol="udp"
# =========================



# 派生路径
bin_dir="${base_dir}/bin"
run_dir="${base_dir}/run"
log_dir="${base_dir}/log"

# 根据运行模式选择二进制文件
if [ "${run_mode}" = "embed" ]; then
    binary_name="easytier-web-embed"
elif [ "${run_mode}" = "web" ]; then
    binary_name="easytier-web"
else
    log_error "run_mode 必须是 'embed' 或 'web'"
    exit 1
fi

binary_path="${bin_dir}/${binary_name}"
pid_file="${run_dir}/${binary_name}.pid"
log_file="${log_dir}/${binary_name}.log"

# 确保目录存在
ensure_dirs() {
    mkdir -p "${bin_dir}"
    mkdir -p "${run_dir}"
    mkdir -p "${log_dir}"
}

# 启动服务
start() {
    ensure_dirs

    if [ ! -f "${binary_path}" ]; then
        log_error "二进制文件不存在 - ${binary_path}"
        exit 1
    fi

    if [ -f "${pid_file}" ]; then
        pid=$(cat "${pid_file}")
        if kill -0 "${pid}" 2>/dev/null; then
            log_info "服务已在运行 (PID: ${pid})"
            exit 0
        else
            log_warn "发现残留的 PID 文件，正在清理..."
            rm -f "${pid_file}"
        fi
    fi

    log_info "启动 ${binary_name}..."
    nohup "${binary_path}" \
        --api-server-port "${api_server_port}" \
        --api-host "${api_host}" \
        --config-server-port "${config_server_port}" \
        --config-server-protocol "${config_server_protocol}" \
        > "${log_file}" 2>&1 &

    echo $! > "${pid_file}"
    log_info "服务已启动 (PID: $(cat "${pid_file}"))"
    log_info "日志文件: ${log_file}"
}

# 停止服务
stop() {
    if [ -f "${pid_file}" ]; then
        pid=$(cat "${pid_file}")
        if kill -0 "${pid}" 2>/dev/null; then
            log_info "停止 ${binary_name} (PID: ${pid})..."
            kill "${pid}"
            sleep 2
            if kill -0 "${pid}" 2>/dev/null; then
                log_warn "强制终止服务..."
                kill -9 "${pid}"
            fi
            rm -f "${pid_file}"
            log_info "服务已停止"
        else
            log_warn "PID 文件存在但进程不存在，清理 PID 文件..."
            rm -f "${pid_file}"
        fi
    else
        log_info "服务未运行 (未找到 PID 文件)"
    fi
}

# 查看状态
status() {
    if [ -f "${pid_file}" ]; then
        pid=$(cat "${pid_file}")
        if kill -0 "${pid}" 2>/dev/null; then
            log_info "${binary_name} 正在运行 (PID: ${pid})"
            exit 0
        else
            log_warn "PID 文件存在但进程未运行"
            exit 1
        fi
    else
        log_info "${binary_name} 未运行"
        exit 1
    fi
}

# 显示帮助信息
usage() {
    log_info1 "用法: $0 {start|stop|restart|status}"
    log_info1 ""
    log_info1 "配置说明:"
    log_info1 "  修改脚本头部的配置区域来自定义以下参数:"
    log_info1 "  - base_dir: 基础目录 (默认: /opt/easytier)"
    log_info1 "  - run_mode: 运行模式 (embed 或 web)"
    log_info1 "  - api_server_port: API 服务端口"
    log_info1 "  - api_host: API 主机地址"
    log_info1 "  - config_server_port: 配置服务端口"
    log_info1 "  - config_server_protocol: 配置服务协议 (tcp/udp)"
    log_info1 ""
    log_info1 "文件结构:"
    log_info1 "  ${base_dir}/"
    log_info1 "  bin/          # 二进制文件目录"
    log_info1 "  run/          # PID 文件目录"
    log_info1 "  log/          # 日志文件目录"
    log_info1 "  easytier-web.sh  # 当前脚本"
}

# 主逻辑
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    status)
        status
        ;;
    *)
        usage
        exit 1
        ;;
esac