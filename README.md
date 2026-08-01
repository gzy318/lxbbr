# LXBBR — BBR 管理工具箱


> 一个开源的 Linux TCP 加速管理工具箱，专注于 BBR 相关功能的配置与管理，让网络优化变得简单高效。

* * *

## 📖 目录

*   项目简介
    
*   功能特性
    
*   快速开始
    
*   使用截图
    
*   项目结构
    
*   系统要求
    
*   更新日志
    
*   致谢
    
*   联系方式
    

* * *

## 项目简介

**LXBBR** 是一个全中文交互的 BBR 管理工具箱，提供以下核心能力：

*   🔍 实时检测 BBR 状态（内核版本、算法、队列、模块加载）
    
*   🧠 多版本内核管理（XanMod / LTS / 稳定版）
    
*   🔄 多算法一键切换（BBR / BBR2 / BBR3 / BBR Plus / Cubic）
    
*   ⚙️ 场景化优化方案（通用 / 低延迟 / 高吞吐）
    
*   🚀 智能带宽检测，自动推荐最优配置
    
*   🛠️ 一站式全自动优化，新手也能轻松上手
    

无论你是服务器运维新手还是资深工程师，LXBBR 都能帮助你快速完成 TCP 网络调优。

* * *

## 功能特性

### 1\. 状态检测

*   当前内核版本与虚拟化类型
    
*   BBR 版本号（若已安装）
    
*   当前 TCP 拥塞控制算法
    
*   当前队列算法
    
*   BBR 模块加载状态
    
*   系统可用的算法列表
    

### 2\. 内核管理

*   安装 XanMod 内核（支持真 BBRv3）
    
*   安装 LTS 内核（5.10 / 5.15 / 6.1）
    
*   升级到最新稳定内核
    
*   卸载 XanMod 内核（安全回滚）
    

### 3\. 算法切换

*   原版 BBR + fq
    
*   BBR + cake（高吞吐场景）
    
*   BBR + fq\_codel（低延迟场景）
    
*   BBR2 + fq（下一代 BBR）
    
*   BBR3 + fq（需 XanMod 内核）
    
*   BBR Plus + fq（魔改版）
    
*   切换回 Cubic（关闭加速）
    
*   手动输入任意算法名
    

### 4\. 队列算法独立设置

*   `fq` —— 最常用，适合 BBR
    
*   `fq_codel` —— 低延迟，适合建站
    
*   `cake` —— 高级流量整形
    
*   `pfifo_fast` —— 系统默认，无加速
    

### 5\. 场景优化向导

*   通用优化（BBR + fq）
    
*   低延迟优先（BBR + fq\_codel）
    
*   高吞吐优先（BBR + cake）
    

### 6\. 开启 BBR 模块

*   手动加载 `tcp_bbr` 内核模块
    
*   配置开机自动加载
    

### 7\. 智能带宽检测优化

*   使用 `speedtest-cli` 检测服务器实际带宽
    
*   根据带宽自动推荐最优 BBR + 队列组合
    
*   高带宽（>500Mbit/s）推荐 BBR + cake
    
*   标准带宽推荐 BBR + fq
    

### 8\. TCP 参数调优

*   设置 TCP 缓冲区（rmem/wmem 4M/16M）
    
*   启用 TCP Fast Open（TFO）
    
*   设置 BBR pacing 参数（pacing\_ss\_ratio / pacing\_ca\_ratio）
    
*   恢复 sysctl 默认配置（需有备份）
    

### 9\. 备份与恢复

*   备份当前 `/etc/sysctl.conf` 配置
    
*   恢复上次备份的配置
    

### 10\. 系统工具

*   环境预检（权限、虚拟化、/boot 空间、系统版本、内存）
    
*   清理旧内核（保留当前内核）
    
*   回滚至默认 Cubic 算法
    

### 11\. 一键全自动优化 ⭐

*   自动完成以下全部操作：
    
    *   检查虚拟化兼容性
        
    *   升级到最新稳定内核
        
    *   安装 XanMod 内核（真 BBRv3）
        
    *   加载 BBR 模块并设置开机自启
        
    *   智能带宽检测并优化
        
    *   设置 TCP 缓冲区
        
*   完成后提示重启，一键生效
    

* * *

## 快速开始

### 运行安装管理脚本（安装/更新/卸载）

```
bash <(curl \-s https://raw.githubusercontent.com/gzy318/LXBBR/main/install.sh)
```

### 运行主程序

使用 `curl`（推荐）：

```
bash <(curl \-s https://raw.githubusercontent.com/gzy318/LXBBR/main/lxbbr.sh)
```
使用 `wget`：

```
wget -qO- https://raw.githubusercontent.com/gzy318/LXBBR/main/lxbbr.sh | bash
```
### 快捷命令（无需进入菜单）

一键全自动优化：

```
bash <(curl \-s https://raw.githubusercontent.com/gzy318/LXBBR/main/lxbbr.sh) install
```
快速查看当前 BBR 状态：

```
bash <(curl \-s https://raw.githubusercontent.com/gzy318/LXBBR/main/lxbbr.sh) status
```


* * *

## 项目结构


LXBBR/

├── lxbbr.sh # 主程序 —— BBR 管理工具箱

├── install.sh # 一键安装/更新/卸载脚本

└── README.md # 项目说明文档（本文件）

* * *

## 系统要求

| 项目 | 要求 |
| --- | --- |
| 操作系统 | Debian 9+ / Ubuntu 18.04+ / CentOS 7+ |
| 权限 | 需要 root 权限 |
| 虚拟化 | 不支持 OpenVZ（无法更换内核） |
| 网络 | 安装内核时需要连接互联网 |

* * *

## 更新日志

### v1.0（2026-08-01）

*   🎉 首个正式版本发布
    
*   支持 BBR / BBR2 / BBR3 / BBR Plus / Cubic 切换
    
*   支持 XanMod / LTS / 稳定版内核安装
    
*   新增智能带宽检测优化功能
    
*   新增一键全自动优化功能
    
*   支持快捷命令 `install` / `status`
    
*   新增安装管理脚本 `install.sh`
    
*   全中文交互，彩色菜单显示
    

* * *

## 致谢

本项目在开发过程中参考了以下优秀开源项目，在此表示感谢：

*   [XanMod](https://xanmod.org/) —— 高性能 Linux 内核，提供真 BBRv3 支持
    
*   [BBR Plus](https://github.com/xiaofd/bbrplus) —— 魔改 BBR，高并发优化
    
*   [speedtest-cli](https://github.com/sivel/speedtest-cli) —— 带宽测试工具
    
*   [ELRepo](https://elrepo.org/) —— CentOS 内核仓库
    

* * *

## 联系方式

*   **GitHub Issues**：[https://github.com/gzy318/LXBBR/issues](https://github.com/gzy318/LXBBR/issues)
    
*   **个人博客**：[https://twbk.cn](https://twbk.cn/)
    
*   **服务器推荐**：[https://www.rainyun.com/xls\_](https://www.rainyun.com/xls_)
    

* * *

## Star 支持

如果这个项目对你有帮助，欢迎点击右上角 **Star ⭐** 支持一下，你的支持是我持续更新的动力！

* * *

**LXBBR** —— 让 BBR 管理更简单 🚀
