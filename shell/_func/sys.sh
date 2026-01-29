# ==================================================
# 系统功能脚本
# [功能]：提供系统检测、环境判断等功能方法
# [示例]：load_inbuilt_script "sys"
# [日期]：2026-01-29
# [作者]：Kahle
# ==================================================



# ======== 检测操作系统信息 ========
# 描述: 检测当前操作系统类型、版本和包管理器
# 返回值: 全局变量 os_name, os_version, os_type, pkg_mgr
# 返回码: 0=成功, 1=无法判断的操作系统
# 示例: detect_os && log_info "检测到: $os_name $os_version, 包管理器: $pkg_mgr"
detect_os() {
    os_name=$(grep -oP '^NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo "")
    os_version=$(grep -oP '^VERSION_ID="\K[^"]+' /etc/os-release 2>/dev/null | cut -d'.' -f1 || echo "")
    os_type=""
    pkg_mgr=""
    # 系统判断
    if [[ "$os_name" == *"CentOS"* ]]; then
        os_type="centos"
        pkg_mgr="yum"
        if [ "$os_version" -ge 8 ] 2>/dev/null; then
            pkg_mgr="dnf"
        fi
    elif [[ "$os_name" == *"Rocky"* ]]; then
        os_type="rocky"
        pkg_mgr="yum"
        if [ "$os_version" -ge 8 ] 2>/dev/null; then
            pkg_mgr="dnf"
        fi
    elif [[ "$os_name" == *"AlmaLinux"* ]]; then
        os_type="almalinux"
        pkg_mgr="yum"
        if [ "$os_version" -ge 8 ] 2>/dev/null; then
            pkg_mgr="dnf"
        fi
    elif [[ "$os_name" == *"Fedora"* ]]; then
        os_type="fedora"
        pkg_mgr="dnf"
    elif [[ "$os_name" == *"Ubuntu"* ]]; then
        os_type="ubuntu"
        pkg_mgr="apt"
    elif [[ "$os_name" == *"Debian"* ]]; then
        os_type="debian"
        pkg_mgr="apt"
    elif [[ "$os_name" == *"Kali"* ]]; then
        os_type="kali"
        pkg_mgr="apt"
    elif [[ "$os_name" == *"Arch"* ]]; then
        os_type="arch"
        pkg_mgr="pacman"
    elif [[ "$os_name" == *"Alpine"* ]]; then
        os_type="alpine"
        pkg_mgr="apk"
    elif [[ "$os_name" == *"openSUSE"* ]]; then
        os_type="opensuse"
        pkg_mgr="zypper"
    elif [[ "$os_name" == *"Gentoo"* ]]; then
        os_type="gentoo"
        pkg_mgr="emerge"
    elif [[ "$os_name" == *"Oracle Linux"* ]]; then
        os_type="oraclelinux"
        pkg_mgr="yum"
        if [ "$os_version" -ge 8 ] 2>/dev/null; then
            pkg_mgr="dnf"
        fi
    elif [[ "$os_name" == *"Red Hat"* ]]; then
        os_type="rhel"
        pkg_mgr="yum"
        if [ "$os_version" -ge 8 ] 2>/dev/null; then
            pkg_mgr="dnf"
        fi
    else
        log_error "无法判断的操作系统：$os_name"
        return 1
    fi
    log_info "检测到: $os_name $os_version, 类型: $os_type, 包管理器: $pkg_mgr"
    return 0
}
# =====================================



