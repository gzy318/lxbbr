#!/bin/bash
# ==========================================
# LXBBR - 纯 BBR 管理工具箱 v1.0
# 项目: https://github.com/gzy318/LXBBR
# ==========================================

R='\033[31m'; G='\033[32m'; Y='\033[33m'; B='\033[34m'
P='\033[35m'; C='\033[36m'; N='\033[0m'; U='\033[4m'

[[ $EUID -ne 0 ]] && echo -e "${R}请使用 root 执行${N}" && exit 1

CONFIG_BACKUP="/etc/sysctl.conf.lxbbr.bak"

show_title() {
    clear
    echo -e "${C}═══════════════════════════════════════${N}"
    echo -e "${G}          LXBBR v1.0${N}"
    echo -e "${C}        BBR 管理工具箱${N}"
    echo -e "${Y}     ${U}https://github.com/gzy318/LXBBR${N}"
    echo -e "${Y}     服务器推荐: ${U}https://www.rainyun.com/xls_${N}"
    echo -e "${Y}     个人博客: ${U}https://twbk.cn${N}"
    echo -e "${C}═══════════════════════════════════════${N}\n"
}

get_distro() {
    if [[ -f /etc/debian_version ]]; then echo "debian"
    elif [[ -f /etc/redhat-release ]]; then echo "centos"
    else echo "unknown"; fi
}

check_kvm() {
    if [[ $(systemd-detect-virt 2>/dev/null) == "openvz" ]]; then
        echo -e "${R}错误: OpenVZ 不支持更换内核${N}"
        return 1
    fi
    return 0
}

safe_sysctl() {
    sysctl -w "$1" 2>/dev/null || true
}

# ---------- 1. 检测 BBR 状态 ----------
check_status() {
    show_title
    echo -e "${B}========== 当前 BBR 状态 ==========${N}"
    kernel=$(uname -r)
    echo -e " 内核版本 : ${G}${kernel}${N}"
    echo -e " 虚拟化   : ${G}$(systemd-detect-virt 2>/dev/null || echo '未知')${N}"

    if modinfo tcp_bbr 2>/dev/null | grep -q "^version:"; then
        bbr_ver=$(modinfo tcp_bbr 2>/dev/null | grep "^version:" | awk '{print $2}')
        echo -e " BBR版本  : ${G}${bbr_ver}${N}"
    elif grep -q "CONFIG_TCP_CONG_BBR=y" /boot/config-${kernel} 2>/dev/null; then
        echo -e " BBR支持  : ${G}是 (内核原生)${N}"
    else
        echo -e " BBR支持  : ${R}否 (需升级内核)${N}"
    fi

    cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "未知")
    qd=$(sysctl -n net.core.default_qdisc 2>/dev/null || echo "未知")
    echo -e " 当前算法 : ${G}${cc}${N}  |  队列 : ${G}${qd}${N}"

    lsmod | grep -q "bbr" && echo -e " 模块加载 : ${G}已加载${N}" || echo -e " 模块加载 : ${Y}未加载${N}"
    avail=$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null || echo "无法获取")
    echo -e " 可用算法 : ${Y}${avail}${N}"
    echo -e "${B}====================================${N}\n"
    read -p "按回车返回..."
}

# ---------- 2. 内核管理 ----------
upgrade_kernel_normal() {
    echo -e "${Y}正在升级内核到最新稳定版...${N}"
    distro=$(get_distro)
    if [[ "$distro" == "debian" ]]; then
        apt update && apt install -y linux-image-amd64 linux-headers-amd64
    elif [[ "$distro" == "centos" ]]; then
        rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
        rpm -Uvh https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
        yum --enablerepo=elrepo-kernel install -y kernel-ml
        grub2-set-default 0 && grub2-mkconfig -o /boot/grub2/grub.cfg
    else
        echo -e "${R}不支持自动升级${N}"; return
    fi
    echo -e "${G}内核安装完成，建议重启。${N}"
}

install_xanmod() {
    echo -e "${Y}正在安装 XanMod 内核 (支持 BBRv3)...${N}"
    distro=$(get_distro)
    if [[ "$distro" == "debian" ]]; then
        wget -qO- https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
        echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' > /etc/apt/sources.list.d/xanmod-release.list
        apt update && apt install -y linux-xanmod
    elif [[ "$distro" == "centos" ]]; then
        echo -e "${Y}CentOS 请使用 ELRepo 安装最新内核${N}"
        upgrade_kernel_normal
        return
    else
        echo -e "${R}不支持该系统${N}"; return
    fi
    echo -e "${G}XanMod 安装完成，重启后生效。${N}"
}

install_lts_kernel() {
    echo -e "${Y}选择 LTS 内核版本:${N}"
    echo " 1. 5.10 LTS"
    echo " 2. 5.15 LTS"
    echo " 3. 6.1 LTS"
    read -p "选择 [1-3]: " ver
    case $ver in
        1) kver="5.10" ;;
        2) kver="5.15" ;;
        3) kver="6.1" ;;
        *) echo -e "${R}无效${N}"; return ;;
    esac
    distro=$(get_distro)
    if [[ "$distro" == "debian" ]]; then
        echo -e "${Y}正在搜索内核包...${N}"
        pkg=$(apt-cache search linux-image-${kver} | grep -E "linux-image-${kver}\.[0-9]+-[0-9]+-amd64" | head -1 | awk '{print $1}')
        if [[ -n "$pkg" ]]; then
            apt install -y "$pkg"
            pkg_hdr=$(apt-cache search linux-headers-${kver} | grep -E "linux-headers-${kver}\.[0-9]+-[0-9]+-amd64" | head -1 | awk '{print $1}')
            [[ -n "$pkg_hdr" ]] && apt install -y "$pkg_hdr"
        else
            echo -e "${R}未找到 ${kver} 内核包，尝试安装最新 LTS${N}"
            upgrade_kernel_normal
        fi
    elif [[ "$distro" == "centos" ]]; then
        yum --enablerepo=elrepo-kernel install -y kernel-lt
        grub2-set-default 0 && grub2-mkconfig -o /boot/grub2/grub.cfg
    else
        echo -e "${R}不支持${N}"; return
    fi
    echo -e "${G}内核 ${kver} 安装完成。${N}"
}

uninstall_xanmod() {
    if ! rpm -qa 2>/dev/null | grep -q xanmod && ! dpkg -l 2>/dev/null | grep -q xanmod; then
        echo -e "${Y}未检测到 XanMod 内核${N}"
        return
    fi
    echo -e "${Y}正在卸载 XanMod...${N}"
    distro=$(get_distro)
    if [[ "$distro" == "debian" ]]; then
        apt purge -y linux-image-*xanmod* linux-headers-*xanmod*
        apt autoremove -y; update-grub
    else
        rpm -qa | grep xanmod | xargs rpm -e --nodeps 2>/dev/null
        grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
    echo -e "${G}卸载完成，重启后生效。${N}"
}

kernel_menu() {
    show_title
    echo -e "${B}========== 内核管理 ==========${N}"
    echo " 1. 安装 XanMod 内核 (BBRv3)"
    echo " 2. 安装 LTS 内核"
    echo " 3. 升级到最新稳定内核"
    echo " 4. 卸载 XanMod 内核"
    echo " 0. 返回"
    read -p "选择: " km
    case $km in
        1) check_kvm && install_xanmod ;;
        2) check_kvm && install_lts_kernel ;;
        3) check_kvm && upgrade_kernel_normal ;;
        4) uninstall_xanmod ;;
        0) return ;;
    esac
    sleep 1
}

# ---------- 3. 切换算法 ----------
set_algorithm() {
    algo=$1; qdisc=$2
    [[ -z "$qdisc" ]] && qdisc="fq"
    if ! sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -q "$algo"; then
        echo -e "${R}当前内核不支持 ${algo}${N}"
        return
    fi
    safe_sysctl "net.ipv4.tcp_congestion_control=$algo"
    safe_sysctl "net.core.default_qdisc=$qdisc"
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = $algo" >> /etc/sysctl.conf
    echo "net.core.default_qdisc = $qdisc" >> /etc/sysctl.conf
    echo -e "${G}✅ 已切换至 ${algo} + ${qdisc}${N}"
    sleep 1
}

switch_algorithm() {
    show_title
    echo -e "${B}========== 切换算法 ==========${N}"
    echo " 1. 原版 BBR + fq"
    echo " 2. BBR + cake"
    echo " 3. BBR + fq_codel"
    echo " 4. BBR2 + fq"
    echo " 5. BBR3 + fq (需 XanMod)"
    echo " 6. BBR Plus + fq"
    echo " 7. 切换回 Cubic (关闭加速)"
    echo " 8. 手动输入算法名"
    echo " 0. 返回"
    read -p "选择: " alg
    case $alg in
        1) set_algorithm "bbr" "fq" ;;
        2) set_algorithm "bbr" "cake" ;;
        3) set_algorithm "bbr" "fq_codel" ;;
        4) set_algorithm "bbr2" "fq" ;;
        5) set_algorithm "bbr3" "fq" ;;
        6) set_algorithm "bbrplus" "fq" ;;
        7) set_algorithm "cubic" "pfifo_fast" ;;
        8) read -p "输入算法名: " a; read -p "输入队列名 (默认 fq): " q; set_algorithm "$a" "${q:-fq}" ;;
        0) return ;;
    esac
}

# ---------- 4. 队列算法独立设置 ----------
set_qdisc() {
    show_title
    echo -e "${B}========== 设置队列算法 ==========${N}"
    echo " 1. fq          (最常用, 适合 BBR)"
    echo " 2. fq_codel    (低延迟, 适合建站)"
    echo " 3. cake        (高级流量整形)"
    echo " 4. pfifo_fast  (默认, 无加速)"
    echo " 0. 返回"
    read -p "选择: " qd
    case $qd in
        1) q="fq" ;;
        2) q="fq_codel" ;;
        3) q="cake" ;;
        4) q="pfifo_fast" ;;
        0) return ;;
        *) echo -e "${R}无效${N}"; return ;;
    esac
    safe_sysctl "net.core.default_qdisc=$q"
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    echo "net.core.default_qdisc = $q" >> /etc/sysctl.conf
    echo -e "${G}队列已切换为 ${q}${N}"
    sleep 1
}

# ---------- 5. 场景优化 ----------
scene_optimize() {
    show_title
    echo -e "${B}========== 场景优化向导 ==========${N}"
    echo -e " ${G}1${N}. 通用优化 (BBR + fq)"
    echo -e " ${G}2${N}. 低延迟优先 (BBR + fq_codel)"
    echo -e " ${G}3${N}. 高吞吐优先 (BBR + cake)"
    echo -e " ${R}0${N}. 返回"
    read -p "选择: " sc
    case $sc in
        1) set_algorithm "bbr" "fq" ;;
        2) set_algorithm "bbr" "fq_codel" ;;
        3) set_algorithm "bbr" "cake" ;;
        0) return ;;
    esac
    sleep 1
}

# ---------- 6. 开启 BBR 模块 ----------
load_bbr_module() {
    show_title
    echo -e "${B}========== 开启 BBR 模块 ==========${N}"
    if lsmod | grep -q "bbr"; then
        echo -e "${Y}BBR 模块已加载${N}"
    else
        modprobe tcp_bbr 2>/dev/null
        if lsmod | grep -q "bbr"; then
            echo -e "${G}BBR 模块加载成功${N}"
            echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
            echo -e "${G}已配置开机自动加载${N}"
        else
            echo -e "${R}加载失败，当前内核可能不支持 BBR${N}"
        fi
    fi
    sleep 1
}

# ---------- 7. 智能带宽检测优化 ----------
auto_optimize() {
    show_title
    echo -e "${B}========== 智能带宽检测优化 ==========${N}"
    echo -e "${Y}正在检测服务器带宽...${N}"
    
    if ! command -v speedtest-cli &>/dev/null; then
        pip install speedtest-cli 2>/dev/null || apt install -y speedtest-cli 2>/dev/null || yum install -y speedtest-cli 2>/dev/null
    fi
    
    speed_result=$(speedtest-cli --simple 2>/dev/null)
    if [[ -n "$speed_result" ]]; then
        download=$(echo "$speed_result" | grep "Download" | awk '{print $2}')
        echo -e " 下载速度: ${G}${download} Mbit/s${N}"
        
        if (( $(echo "$download > 500" | bc -l) )); then
            echo -e "${G}检测到高带宽 (${download} Mbit/s)，推荐 BBR + cake${N}"
            set_algorithm "bbr" "cake"
        else
            echo -e "${G}检测到标准带宽 (${download} Mbit/s)，推荐 BBR + fq${N}"
            set_algorithm "bbr" "fq"
        fi
    else
        echo -e "${Y}无法检测带宽，使用默认配置 BBR + fq${N}"
        set_algorithm "bbr" "fq"
    fi
    sleep 1
}

# ---------- 8. TCP 参数调优 ----------
tcp_tune() {
    show_title
    echo -e "${B}========== TCP 参数调优 ==========${N}"
    echo " 1. 设置 TCP 缓冲区 (4M/16M)"
    echo " 2. 启用 TCP Fast Open"
    echo " 3. 设置 BBR pacing 参数"
    echo " 4. 恢复 sysctl 默认 (需有备份)"
    echo " 0. 返回"
    read -p "选择: " t
    case $t in
        1)
            grep -q "net.ipv4.tcp_rmem" /etc/sysctl.conf || echo "net.ipv4.tcp_rmem = 4096 4194304 16777216" >> /etc/sysctl.conf
            grep -q "net.ipv4.tcp_wmem" /etc/sysctl.conf || echo "net.ipv4.tcp_wmem = 4096 4194304 16777216" >> /etc/sysctl.conf
            sysctl -p; echo -e "${G}缓冲区已设置${N}" ;;
        2)
            safe_sysctl "net.ipv4.tcp_fastopen=3"
            grep -q "net.ipv4.tcp_fastopen" /etc/sysctl.conf || echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
            echo -e "${G}TCP Fast Open 已启用${N}" ;;
        3)
            safe_sysctl "net.ipv4.tcp_pacing_ss_ratio=100"
            safe_sysctl "net.ipv4.tcp_pacing_ca_ratio=120"
            grep -q "tcp_pacing_ss_ratio" /etc/sysctl.conf || echo "net.ipv4.tcp_pacing_ss_ratio = 100" >> /etc/sysctl.conf
            grep -q "tcp_pacing_ca_ratio" /etc/sysctl.conf || echo "net.ipv4.tcp_pacing_ca_ratio = 120" >> /etc/sysctl.conf
            echo -e "${G}BBR pacing 参数已设置${N}" ;;
        4)
            if [[ -f $CONFIG_BACKUP ]]; then
                cp -f $CONFIG_BACKUP /etc/sysctl.conf
                sysctl -p
                echo -e "${G}已恢复至备份配置${N}"
            else
                echo -e "${R}未找到备份${N}"
            fi ;;
        0) return ;;
    esac
    sleep 1
}

# ---------- 9. 备份/恢复 ----------
backup_restore() {
    show_title
    echo -e "${B}========== 备份/恢复 ==========${N}"
    echo " 1. 备份当前 sysctl 配置"
    echo " 2. 恢复上次备份"
    echo " 0. 返回"
    read -p "选择: " br
    case $br in
        1) cp /etc/sysctl.conf $CONFIG_BACKUP; echo -e "${G}已备份至 $CONFIG_BACKUP${N}" ;;
        2) [[ -f $CONFIG_BACKUP ]] && cp -f $CONFIG_BACKUP /etc/sysctl.conf && sysctl -p && echo -e "${G}恢复成功${N}" || echo -e "${R}备份不存在${N}" ;;
        0) return ;;
    esac
    sleep 1
}

# ---------- 10. 系统工具 ----------
system_tools() {
    show_title
    echo -e "${B}========== 系统工具 ==========${N}"
    echo " 1. 环境预检"
    echo " 2. 清理旧内核"
    echo " 3. 回滚至默认 Cubic"
    echo " 0. 返回"
    read -p "选择: " st
    case $st in
        1)
            echo -e "${Y}环境预检...${N}"
            echo -e " Root权限: ${G}✓${N}"
            check_kvm
            echo -e " /boot 空间: $(df -h /boot | awk 'NR==2{print $4}') 可用"
            echo -e " 系统: $(get_distro)"
            echo -e " 内存: $(free -h | awk 'NR==2{print $2}')" ;;
        2)
            echo -e "${Y}清理旧内核...${N}"
            distro=$(get_distro)
            current=$(uname -r)
            if [[ "$distro" == "debian" ]]; then
                apt autoremove --purge -y linux-image-* linux-headers-* 2>/dev/null
            elif [[ "$distro" == "centos" ]]; then
                yum remove -y kernel-* --exclude=kernel-$current 2>/dev/null
            fi
            echo -e "${G}清理完成${N}" ;;
        3)
            set_algorithm "cubic" "pfifo_fast"
            echo -e "${G}已回滚至默认 Cubic${N}" ;;
        0) return ;;
    esac
    sleep 1
}

# ---------- 11. 一键全自动优化 ----------
auto_full() {
    show_title
    echo -e "${B}========== 一键全自动优化 ==========${N}"
    echo -e "${Y}即将执行以下操作:${N}"
    echo " 1. 检查并升级内核 (如需要)"
    echo " 2. 安装 XanMod 内核 + BBR v3"
    echo " 3. 启用 BBR 模块"
    echo " 4. 智能带宽检测并优化"
    echo " 5. 设置 TCP 缓冲区"
    echo -e "${Y}是否继续? [y/N]${N}"
    read -p "选择: " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && return
    
    check_kvm || return
    upgrade_kernel_normal
    install_xanmod
    load_bbr_module
    auto_optimize
    # 直接调用 tcp_tune 中的缓冲区设置
    grep -q "net.ipv4.tcp_rmem" /etc/sysctl.conf || echo "net.ipv4.tcp_rmem = 4096 4194304 16777216" >> /etc/sysctl.conf
    grep -q "net.ipv4.tcp_wmem" /etc/sysctl.conf || echo "net.ipv4.tcp_wmem = 4096 4194304 16777216" >> /etc/sysctl.conf
    sysctl -p 2>/dev/null
    
    echo -e "${G}✅ 全自动优化完成！建议重启服务器。${N}"
    read -p "是否现在重启? [y/N] " reboot_confirm
    [[ "$reboot_confirm" =~ ^[Yy]$ ]] && reboot
}

# ---------- 快捷命令处理 ----------
if [[ "$1" == "install" ]]; then
    auto_full
    exit 0
elif [[ "$1" == "status" ]]; then
    check_status
    exit 0
fi

# ---------- 主菜单 ----------
main() {
    while true; do
        show_title
        echo -e "${B}═══════════════════════════════════${N}"
        echo -e " ${G}1${N}. 检测 BBR 状态"
        echo -e " ${G}2${N}. 内核管理"
        echo -e " ${G}3${N}. 切换 BBR 算法"
        echo -e " ${G}4${N}. 设置队列算法"
        echo -e " ${G}5${N}. 场景优化向导"
        echo -e " ${G}6${N}. 开启 BBR 模块"
        echo -e " ${G}7${N}. 智能带宽检测优化"
        echo -e " ${G}8${N}. TCP 参数调优"
        echo -e " ${G}9${N}. 备份/恢复 sysctl"
        echo -e " ${G}10${N}. 系统工具"
        echo -e " ${G}11${N}. 一键全自动优化 ★"
        echo -e " ${G}12${N}. 重启服务器"
        echo -e " ${R}0${N}. 退出"
        echo -e "${B}═══════════════════════════════════${N}"
        read -p "请选择 [0-12]: " opt
        case $opt in
            1) check_status ;;
            2) kernel_menu ;;
            3) switch_algorithm ;;
            4) set_qdisc ;;
            5) scene_optimize ;;
            6) load_bbr_module ;;
            7) auto_optimize ;;
            8) tcp_tune ;;
            9) backup_restore ;;
            10) system_tools ;;
            11) auto_full ;;
            12) reboot ;;
            0) exit 0 ;;
            *) echo -e "${R}无效选项${N}"; sleep 1 ;;
        esac
    done
}

main
