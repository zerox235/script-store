# EasyTier

简单、安全、去中心化的异地组网方案。

<br />

## 项目简介

EasyTier 是一款简单、安全、去中心化的内网穿透和异地组网工具，适合远程办公、异地访问、游戏加速等多种场景。无需公网 IP，无需复杂配置，轻松实现不同地点设备间的安全互联。

<br />

## 官方文档

- 官网地址：https://easytier.cn
- 文档地址：https://easytier.cn/guide/introduction.html
- 下载地址：https://easytier.cn/guide/download.html

<br />

## 快速安装

```bash
curl -Ls https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/net/easytier/install-easytier.sh | bash
```

<br />

## 文件结构

```
/opt/easytier/
├── bin/              # 二进制文件目录
├── run/              # PID 文件目录
├── log/              # 日志文件目录
├── easytier-core.sh  # Core 服务管理脚本
└── easytier-web.sh   # Web 服务管理脚本
```

<br />

## 使用方法

### Core 服务管理

```bash
# 启动服务
/opt/easytier/easytier-core.sh start
# 停止服务
/opt/easytier/easytier-core.sh stop
# 重启服务
/opt/easytier/easytier-core.sh restart
# 查看状态
/opt/easytier/easytier-core.sh status
```

<br />

### Web 服务管理

```bash
# 启动服务
/opt/easytier/easytier-web.sh start
# 停止服务
/opt/easytier/easytier-web.sh stop
# 重启服务
/opt/easytier/easytier-web.sh restart
# 查看状态
/opt/easytier/easytier-web.sh status
```

<br />

## 配置说明

### easytier-core.sh 配置

| 参数 | 默认值 | 说明 |
|------|--------|------|
| base_dir | /opt/easytier | 基础目录 |
| console_address | udp://127.0.0.1:22020/user | 控制台地址 |

<br />

### easytier-web.sh 配置

| 参数 | 默认值 | 说明 |
|------|--------|------|
| base_dir | /opt/easytier | 基础目录 |
| run_mode | embed | 运行模式 (embed 或 web) |
| api_server_port | 11211 | API 服务端口 |
| api_host | http://127.0.0.1:11211 | API 主机地址 |
| config_server_port | 22020 | 配置服务端口 |
| config_server_protocol | udp | 配置服务协议 (tcp/udp) |

<br />

