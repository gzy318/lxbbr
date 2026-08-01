#!/bin/bash
# ==========================================
# LXBBR 一键安装管理脚本
# 项目: https://github.com/gzy318/LXBBR
# 功能: 安装/更新/运行/卸载 LXBBR
# ==========================================

R='\033[31m'; G='\033[32m'; Y='\033[33m'; B='\033[34m'; C='\033[36m'; N='\033[0m'

LXBBR_URL="https://raw.githubusercontent.com/gzy318/LXBBR/main/lxbbr.sh"
LXBBR_FILE="./lxbbr.sh"
VERSION="1.0"

show_title() {
    clear
    echo -e "${C}═══════════════════════════════════════${N}"
    echo -e "${G}      LXBBR 一键安装管理脚本${N}"
    echo -e "${Y}     ${U}https://github.com/gzy318/LXBBR${N}"
    echo -e "${Y}     服务器推荐: ${U}https://www.rainyun.com/xls_${N}"
    echo -e "${Y}     个人博客: ${U}https://twbk.cn${N}"
    echo -e "${C}═══════════════════════════════════════${N}\n"
}

# 检测是否已安装
check_installed() {
    if [[ -f "$LXBBR_FILE" ]]; then
        return 0
    else
        return 1
    fi
}

# 下载 lxbbr.sh
download_lxbbr() {
    echo -e "${Y}正在从 GitHub 下载最新版 lxbbr.sh ...${N}"
    if command -v wget &>/dev/null; then
        wget -O "$LXBBR_FILE" "$LXBBR_URL"
    elif command -v curl &>/dev/null; then
        curl -o "$LXBBR_FILE" "$LXBBR_URL"
    else
        echo -e "${R}错误: 未找到 wget 或 curl，请先安装。${N}"
        return 1
    fi
    if [[ $? -eq 0 && -f "$LXBBR_FILE" ]]; then
        chmod +x "$LXBBR_FILE"
        echo -e "${G}下载成功！${N}"
        return 0
    else
        echo -e "${R}下载失败，请检查网络或稍后重试。${N}"
        return 1
    fi
}

# 安装/更新
install_or_update() {
    show_title
    echo -e "${B}========== 安装/更新 LXBBR ==========${N}"
    download_lxbbr
    if [[ $? -eq 0 ]]; then
        echo -e "${G}安装/更新完成！${N}"
    else
        echo -e "${R}安装失败。${N}"
    fi
    read -p "按回车继续..."
}

# 运行 LXBBR
run_lxbbr() {
    if check_installed; then
        show_title
        echo -e "${G}正在启动 LXBBR ...${N}"
        exec "$LXBBR_FILE"
    else
        echo -e "${R}未安装 LXBBR，请先执行安装。${N}"
        sleep 2
    fi
}

# 卸载
uninstall() {
    show_title
    echo -e "${B}========== 卸载 LXBBR ==========${N}"
    if check_installed; then
        read -p "确定要删除 lxbbr.sh 及其备份文件吗？[y/N] " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -f "$LXBBR_FILE"
            rm -f /etc/sysctl.conf.lxbbr.bak 2>/dev/null
            echo -e "${G}卸载完成。${N}"
        else
            echo -e "${Y}操作取消。${N}"
        fi
    else
        echo -e "${Y}未发现 LXBBR，无需卸载。${N}"
    fi
    sleep 2
}

# 查看状态
show_status() {
    show_title
    echo -e "${B}========== LXBBR 状态 ==========${N}"
    if check_installed; then
        echo -e " 状态: ${G}已安装${N}"
        echo -e " 路径: ${Y}$LXBBR_FILE${N}"
        lx_version=$(grep "^#.*v[0-9]" "$LXBBR_FILE" | head -1 | grep -o "v[0-9.]*" || echo "未知")
        echo -e " 版本: ${G}${lx_version}${N}"
    else
        echo -e " 状态: ${R}未安装${N}"
    fi
    echo -e " 项目主页: ${U}https://github.com/gzy318/LXBBR${N}"
    echo -e " 服务器推荐: ${U}https://www.rainyun.com/xls_${N}"
    echo -e " 个人博客: ${U}https://twbk.cn${N}"
    read -p "按回车继续..."
}

# 主菜单
main_menu() {
    while true; do
        show_title
        echo -e "${B}═══════════════════════════════════${N}"
        echo -e " ${G}1${N}. 安装/更新 LXBBR"
        echo -e " ${G}2${N}. 运行 LXBBR（主程序）"
        echo -e " ${G}3${N}. 查看当前状态"
        echo -e " ${G}4${N}. 卸载 LXBBR"
        echo -e " ${R}0${N}. 退出"
        echo -e "${B}═══════════════════════════════════${N}"
        read -p "请选择 [0-4]: " choice
        case $choice in
            1) install_or_update ;;
            2) run_lxbbr ;;
            3) show_status ;;
            4) uninstall ;;
            0) exit 0 ;;
            *) echo -e "${R}无效选项${N}"; sleep 1 ;;
        esac
    done
}

# 带参数运行（支持静默安装）
if [[ "$1" == "--install" ]] || [[ "$1" == "-i" ]]; then
    download_lxbbr && echo -e "${G}安装完成，执行 ./lxbbr.sh 启动${N}"
    exit 0
elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "LXBBR 一键安装脚本"
    echo "用法: ./install.sh [选项]"
    echo "  -i, --install   直接安装/更新，不进入菜单"
    echo "  -h, --help      显示此帮助"
    echo "  无参数          进入交互式菜单"
    exit 0
fi

main_menu
