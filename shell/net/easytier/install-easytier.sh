#!/bin/bash
# ==================================================
# EasyTier 安装脚本
# [功能]：EasyTier 安装
# [文档]：https://easytier.cn/guide/download.html
# [日期]：2026-05-02
# [作者]：Kahle
# ==================================================


# 引入公共脚本（ curl -Ls 可以替换为 wget -qO- ）
_D="/tmp/remote-func2512"; _F="$_D/_base.sh_$(date +%Y%m%d)"; _R="https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/shell/_func/_base.sh";
mkdir -p "$_D" && { [ ! -f "$_F" ] && curl -Ls "$_R" > "$_F" || true; } && source "$_F"; find "$_D" -name "_base.sh_*" -mtime +1 -delete 2>/dev/null &


set -e

base_dir="/opt/easytier"
bin_dir="${base_dir}/bin"
run_dir="${base_dir}/run"
log_dir="${base_dir}/log"
pkg_dir="/opt/pkg/easytier"

binary_url="https://ghfast.top/https://github.com/EasyTier/EasyTier/releases/download/v2.4.5/easytier-linux-x86_64-v2.4.5.zip"
script_urls=(
    "https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/shell/net/easytier/easytier-core.sh"
    "https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/shell/net/easytier/easytier-web.sh"
)

log_info "开始安装 EasyTier..."

log_info "创建目录结构..."
mkdirs "${bin_dir}" "${run_dir}" "${log_dir}" "${pkg_dir}" || exit 1

pkg_zip="${pkg_dir}/easytier-linux-x86_64-v2.4.5.zip"
if [ -f "${pkg_zip}" ]; then
    log_info "二进制文件已存在，跳过下载..."
else
    log_info "下载二进制文件到 ${pkg_dir}..."
    curl -Ls "${binary_url}" -o "${pkg_zip}"
fi

log_info "解压二进制文件到 ${bin_dir}..."
unzip -o "${pkg_zip}" -d "${bin_dir}"
mv -f "${bin_dir}/easytier-linux-x86_64"/* "${bin_dir}/"
rm -rf "${bin_dir}/easytier-linux-x86_64"

log_info "下载管理脚本..."
for url in "${script_urls[@]}"; do
    filename=$(basename "${url}")
    log_info "  下载 ${filename}..."
    curl -Ls "${url}" -o "${base_dir}/${filename}"
    chmod +x "${base_dir}/${filename}"
done

log_info "设置二进制文件权限..."
find "${bin_dir}" -type f -executable -exec chmod +x {} \;

log_info "安装完成!"
log_info ""
log_info "文件结构:"
log_info "  ${base_dir}/"
log_info "  ├── bin/              # 二进制文件"
log_info "  ├── run/              # PID 文件"
log_info "  ├── log/              # 日志文件"
log_info "  ├── easytier-core.sh  # Core 服务管理脚本"
log_info "  └── easytier-web.sh   # Web 服务管理脚本"
log_info ""
log_info "使用示例:"
log_info "  ${base_dir}/easytier-core.sh start   # 启动 Core 服务"
log_info "  ${base_dir}/easytier-web.sh start    # 启动 Web 服务"
