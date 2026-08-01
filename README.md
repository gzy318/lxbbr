# LXBBR — BBR 管理工具箱

开源协议：MIT License
项目地址：https://github.com/gzy318/LXBBR


## 项目简介

LXBBR 是一个开源的 Linux TCP 加速管理工具箱，专注于 BBR 相关功能的配置与管理。提供内核升级、算法切换、队列设置、场景优化等一体化操作，适合服务器运维人员快速部署和调优网络性能。


## 功能特性

1. 状态检测
   显示当前内核版本、BBR 版本、当前算法、队列算法、模块加载状态、可用算法列表

2. 内核管理
   安装 XanMod 内核（支持 BBRv3）
   安装 LTS 内核（5.10 / 5.15 / 6.1）
   升级到最新稳定内核
   卸载 XanMod 内核

3. 算法切换
   原版 BBR + fq
   BBR + cake
   BBR + fq_codel
   BBR2 + fq
   BBR3 + fq（需 XanMod 内核）
   BBR Plus + fq
   切换回 Cubic（关闭加速）
   手动输入算法名

4. 队列算法独立设置
   fq（最常用，适合 BBR）
   fq_codel（低延迟，适合建站）
   cake（高级流量整形）
   pfifo_fast（默认，无加速）

5. 场景优化向导
   通用优化（BBR + fq）
   低延迟优先（BBR + fq_codel）
   高吞吐优先（BBR + cake）

6. 开启 BBR 模块
   加载 tcp_bbr 模块并配置开机自动加载

7. 智能带宽检测优化
   自动检测服务器带宽，根据带宽大小推荐最优 BBR + 队列组合

8. TCP 参数调优
   设置 TCP 缓冲区（4M/16M）
   启用 TCP Fast Open
   设置 BBR pacing 参数
   恢复 sysctl 默认配置

9. 备份与恢复
   备份当前 sysctl 配置
   恢复上次备份

10. 系统工具
    环境预检（检查 root 权限、虚拟化类型、/boot 空间、系统版本、内存大小）
    清理旧内核（保留当前内核，删除其余旧内核）
    回滚至默认 Cubic

11. 一键全自动优化
    自动完成：内核升级 → XanMod 安装 → BBR 模块加载 → 带宽检测 → TCP 缓冲区设置

12. 重启服务器


## 快速开始

运行主程序（BBR 管理）：
bash <(curl -s https://raw.githubusercontent.com/gzy318/LXBBR/main/lxbbr.sh)

或使用 wget：
wget -qO- https://raw.githubusercontent.com/gzy318/LXBBR/main/lxbbr.sh | bash

运行安装管理脚本（安装/更新/卸载）：
bash <(curl -s https://raw.githubusercontent.com/gzy318/LXBBR/main/install.sh)

快捷命令（无需进入菜单）：
一键全自动优化：bash <(curl -s https://raw.githubusercontent.com/gzy318/LXBBR/main/lxbbr.sh) install
快速查看状态：bash <(curl -s https://raw.githubusercontent.com/gzy318/LXBBR/main/lxbbr.sh) status


## 使用截图

运行后会显示如下界面：

═══════════════════════════════════════
          LXBBR v1.0
        BBR 管理工具箱
     https://github.com/gzy318/LXBBR
     服务器推荐: https://www.rainyun.com/xls_
     个人博客: https://twbk.cn
═══════════════════════════════════════

═══════════════════════════════════════
 1. 检测 BBR 状态
 2. 内核管理
 3. 切换 BBR 算法
 4. 设置队列算法
 5. 场景优化向导
 6. 开启 BBR 模块
 7. 智能带宽检测优化
 8. TCP 参数调优
 9. 备份/恢复 sysctl
 10. 系统工具
 11. 一键全自动优化 ★
 12. 重启服务器
 0. 退出
═══════════════════════════════════════


## 项目结构

LXBBR/
├── lxbbr.sh          # 主程序，BBR 管理工具箱
├── install.sh        # 一键安装/更新/卸载脚本
└── README.md         # 项目说明文档


## 系统要求

操作系统：Debian 9+ / Ubuntu 18.04+ / CentOS 7+
权限要求：需要 root 权限
虚拟化限制：不支持 OpenVZ（无法更换内核）


## 更新日志

v1.0（2026-08-01）
- 首个正式版本发布
- 支持 BBR / BBR2 / BBR3 / BBR Plus 切换
- 支持 XanMod / LTS / 稳定版内核安装
- 新增智能带宽检测优化
- 新增一键全自动优化
- 支持快捷命令 install / status
- 新增安装管理脚本 install.sh


## 致谢

XanMod - 高性能 Linux 内核
BBR Plus - 魔改 BBR
speedtest-cli - 带宽测试工具


## 联系方式

GitHub Issues：https://github.com/gzy318/LXBBR/issues
个人博客：https://twbk.cn
服务器推荐：https://www.rainyun.com/xls_

如果这个项目对你有帮助，欢迎 Star 支持！
