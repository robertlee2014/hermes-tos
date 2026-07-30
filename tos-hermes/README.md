# Hermes AI Agent for TOS 7

自进化 AI 智能体，支持 Web 界面操作与远程访问。基于 Hermes Agent 与 WebUI，提供可视化工作流编排、多模型支持与持久化记忆。

## 应用类型

- **类型**: Deb 应用（WebUI 内部打开 - iframe 模式）
- **架构**: x86_64 (amd64)
- **最低 TOS 版本**: 7.0.0

## 功能特点

- 🤖 自进化 AI 智能体核心
- 🎨 可视化 WebUI 工作流编排
- 🔌 多模型支持（本地 + 云端）
- 💾 持久化记忆与上下文管理
- 🔒 Unix Socket + 平台代理安全通信
- 📦 多层 pip 镜像与 GitHub 代理兜底

## 安装方式

### 从 TNAS 应用中心安装（推荐）

1. 登录 TOS 7 系统
2. 打开「应用中心」
3. 搜索 "Hermes AI Agent"
4. 点击「安装」

### 手动安装 deb 包

```bash
# 构建 deb 包
cd tos-hermes
dpkg-deb --build . ../com.nousresearch.hermes_0.1.9_amd64.deb

# 安装
sudo dpkg -i com.nousresearch.hermes_0.1.9_amd64.deb

# 启动服务
sudo systemctl start com.nousresearch.hermes

# 查看状态
sudo systemctl status com.nousresearch.hermes
```

## 访问方式

安装并启动后，通过 TOS 桌面应用图标访问，或在浏览器中访问：

```
http://<NAS_IP>/com.nousresearch.hermes/
```

## 技术架构

### 目录结构

```
/usr/local/com.nousresearch.hermes/
├── bin/
│   └── hermes-start.sh          # 启动脚本
├── images/icons/
│   └── com.nousresearch.hermes.svg
├── init.d/
│   └── com.nousresearch.hermes.service  # systemd 服务
└── data/                        # 运行时数据（安装时生成）
    ├── venv/                    # Python 虚拟环境
    ├── hermes-webui/            # WebUI 源码
    └── workspace/               # Agent 工作区
```

### 通信模式

- **前端**: TOS 桌面内嵌 iframe
- **后端**: Unix Socket (`/var/api/com.nousresearch.hermes.sock`)
- **代理**: TOS 平台代理 (`/v2/proxy/com.nousresearch.hermes/`)
- **鉴权**: Cookie + X-Csrf-Token

### 安全加固

- 非 root 用户运行 (`hermes:hermes`)
- `NoNewPrivileges=true`
- `ProtectSystem=strict`
- `PrivateTmp=true`
- 最小权限文件系统访问

## 依赖

- TOS 7.0+ (Ubuntu 22.04)
- Python 3.10+ (系统预装)
- git (用于克隆 WebUI)

## 开发指南

### 构建 deb 包

```bash
cd tos-hermes
dpkg-deb --build . ../com.nousresearch.hermes_0.1.9_amd64.deb
sha256sum ../com.nousresearch.hermes_0.1.9_amd64.deb > ../com.nousresearch.hermes_0.1.9_amd64.deb.sha256
```

### 校验配置

```bash
# 校验 config.ini JSON 格式
python3 -c "import json; json.load(open('config.ini'))"

# 校验 14 种语言
python3 validate_lang.py

# 校验图标
python3 validate_icon.py
```

## 常见问题

### Q: 安装后无法启动？

查看日志：
```bash
journalctl -u com.nousresearch.hermes -n 50
cat /var/log/com.nousresearch.hermes/install.log
```

### Q: 如何重置数据？

```bash
sudo systemctl stop com.nousresearch.hermes
sudo rm -rf /usr/local/com.nousresearch.hermes/data
sudo systemctl start com.nousresearch.hermes
```

### Q: 端口冲突怎么办？

本应用使用 Unix Socket 通信，不占用 TCP 端口，由 TOS 平台统一代理转发。

## 许可证

Apache 2.0

## 支持

- GitHub: https://github.com/NousResearch/hermes-agent
- 文档：https://nousresearch.com/docs
