# Hermes for TOS 7

Hermes 是一款自进化 AI 智能体应用，专为 TOS 7 系统设计。提供可视化工作流编排、多模型支持与持久化记忆，让您轻松构建和运行 AI 任务。

## 应用信息

- **应用名称**: Hermes
- **包标识符**: `hermes-app`
- **应用类型**: Deb 应用（WebUI 内部打开 - iframe 模式）
- **支持架构**: x86_64 (amd64)
- **最低系统要求**: TOS 7.0.0+

## 核心功能

- 🤖 **自进化 AI 智能体**: 自动学习优化，持续改进任务执行能力
- 🎨 **可视化工作流**: 拖拽式界面，轻松编排复杂 AI 任务
- 🔌 **多模型支持**: 兼容本地部署与云端 API，灵活切换
- 💾 **持久化记忆**: 上下文长期保存，支持跨会话连续对话
- 🔒 **安全通信**: Unix Socket + TOS 平台代理，数据不出内网
- 📦 **轻量安装包**: 仅包含核心启动脚本，运行时自动下载最新组件（hermes-agent 和 hermes-webui），确保始终使用最新版本

## 安装方式

### 方式一：TNAS 应用中心（推荐）

1. 登录 TOS 7 系统
2. 打开「应用中心」
3. 搜索 "**Hermes**"
4. 点击「安装」按钮

系统将自动下载并配置所有依赖，无需手动操作。应用将安装到当前 deb 包所在磁盘，并在该磁盘创建 `HermesWorkspace` 目录用于存储运行时数据。

### 方式二：手动安装 deb 包

```bash
# 进入项目目录
cd tos-hermes

# 构建 deb 包
./build.sh

# 安装 deb 包
sudo dpkg -i ../hermes-app_*.deb

# 启动服务
sudo systemctl start hermes-app

# 查看运行状态
sudo systemctl status hermes-app
```

> **安装路径说明**：
> - 应用会自动检测 deb 包安装的磁盘（如 `/volume1`, `/volume2` 等）
> - 在该磁盘下创建 `/HermesWorkspace/` 目录作为数据工作区
> - 所有动态下载的数据（Python 虚拟环境、WebUI 源码、Agent 工作区）均存储于 `HermesWorkspace` 下
> - 二进制文件和配置文件仍位于标准系统路径 `/usr/local/hermes-app/`

## 访问方式

安装完成后，通过以下方式访问 Hermes：

### 方法 1：TOS 桌面（推荐）
1. 登录 TOS 网页界面
2. 在桌面或应用中心找到 "**Hermes**" 图标
3. 点击图标，应用将在新窗口中打开

### 方法 2：浏览器直接访问

```
http://<您的 NAS IP>/hermes-app/
```

> **关于 URL 路径的说明**：
> - 路径 `/hermes-app/` 必须与应用包标识符完全一致，**无法简化**。
> - 这是 TOS 7 的安全路由机制，确保不同应用间的命名空间隔离。
> - **推荐方式**：通过 TOS 桌面应用图标访问，自动跳转且无需记忆地址。

> **注意**: 应用通过 TOS 平台统一代理，不直接暴露端口，确保安全性。

## 技术架构

### 目录结构

```
# 系统路径（静态文件）
/usr/local/hermes-app/
├── bin/
│   └── hermes-start.sh          # 启动脚本
├── images/icons/
│   └── hermes-app.svg           # 应用图标
└── init.d/
    └── hermes-app.service       # systemd 服务配置

# 数据路径（动态数据，位于 deb 安装磁盘）
/volumeX/HermesWorkspace/        # X 为实际磁盘编号（如 volume1, volume2）
├── venv/                        # Python 虚拟环境（首次启动时生成）
├── hermes-agent/                # AI 智能体源码（首次启动时自动下载）
├── hermes-webui/                # WebUI 源码（首次启动时自动下载）
└── workspace/                   # Agent 工作区与记忆存储

# 说明：应用包本身仅包含启动脚本和配置文件（约 50KB），不包含 hermes-agent 和 hermes-webui 源码。
# 首次启动时会自动从 GitHub 克隆最新代码到 HermesWorkspace 目录，确保始终使用最新版本。
```

> **说明**：TOS 系统可能有多个磁盘（`/volume1`, `/volume2` 等），deb 包安装时会自动检测目标磁盘，并在该磁盘根目录创建 `HermesWorkspace` 文件夹用于存储所有运行时数据。

### 通信机制

| 组件 | 实现方式 |
|------|---------|
| **前端展示** | TOS 桌面内嵌 iframe |
| **后端服务** | Unix Socket (`/var/api/hermes-app.sock`) |
| **请求代理** | TOS 平台代理 (`/v2/proxy/hermes-app/`) |
| **身份验证** | Cookie + X-Csrf-Token 双重校验 |

### 安全特性

- ✅ 独立用户运行 (`hermes:hermes`)，非 root 权限
- ✅ `NoNewPrivileges=true` 防止提权
- ✅ `ProtectSystem=strict` 保护系统文件
- ✅ `PrivateTmp=true` 隔离临时文件
- ✅ 最小化文件系统访问权限

## 系统依赖

- TOS 7.0+ (基于 Ubuntu 22.04)
- Python 3.10+ (系统预装)
- Git (用于克隆 WebUI 组件)

## 开发者指南

### 构建 deb 包

```bash
cd tos-hermes

# 使用构建脚本（自动校验 + 打包）
./build.sh

# 或手动构建
dpkg-deb --build . ../hermes-app_$(date +%Y%m%d)_amd64.deb
sha256sum ../hermes-app_*.deb > ../hermes-app_*.deb.sha256
```

### 配置校验

```bash
# 校验 config.ini JSON 格式
python3 -c "import json; json.load(open('config.ini'))"

# 校验语言文件（14 种语言）
python3 -c "
with open('hermes-app.lang') as f:
    langs = [l.split('=')[0] for l in f if '=' in l]
    print(f'已支持 {len(langs)} 种语言：{langs}')
"

# 校验 SVG 图标格式
grep -q 'viewBox' usr/local/hermes-app/images/icons/hermes-app.svg && echo '图标格式正确'
```

### CI/CD

项目包含 GitHub Actions 工作流，推送代码后自动构建并上传 deb 包到 Release。

## 常见问题

### Q: 安装后无法启动？

**解决方案**:
```bash
# 查看详细日志
journalctl -u hermes-app -n 50 --no-pager

# 查看安装日志
cat /var/log/hermes-app/install.log

# 重启服务
sudo systemctl restart hermes-app
```

### Q: 如何重置所有数据？

**警告**: 此操作将删除所有工作流、记忆和配置！

```bash
sudo systemctl stop hermes-app
# 查找 HermesWorkspace 所在磁盘（通常在 /volume1, /volume2 等）
sudo rm -rf /volume*/HermesWorkspace
sudo systemctl start hermes-app
```

> **提示**：如果不确定 `HermesWorkspace` 的位置，可以运行 `find /volume* -maxdepth 1 -type d -name "HermesWorkspace"` 来查找。

### Q: 如何查看版本号？

```bash
# 查看已安装包版本
dpkg -l | grep hermes-app

# 或在应用内查看（设置页面）
```

### Q: 会占用系统端口吗？

不会。本应用使用 Unix Socket 进行内部通信，不占用任何 TCP/UDP 端口，由 TOS 平台统一代理转发，避免端口冲突。

## 升级与卸载

### 升级应用
```bash
sudo dpkg -i hermes-app_new_version.deb
sudo systemctl restart hermes-app
```

### 卸载应用
```bash
sudo apt remove hermes-app
# 或
sudo dpkg -r hermes-app
```

> **数据保留说明**：
> - 卸载时会询问是否保留 `HermesWorkspace` 数据目录
> - 选择"是"则保留所有工作流和记忆，重新安装后可继续使用
> - 选择"否"则完全删除 `/volume*/HermesWorkspace` 目录
> - 手动删除数据：`sudo rm -rf /volume*/HermesWorkspace`

## 相关资源

- **项目主页**: https://github.com/NousResearch/hermes-agent
- **官方文档**: https://nousresearch.com/docs
- **TOS 开发指南**: https://github.com/TerraMasterOfficial/test2026

## 许可证

Apache License 2.0

---

**享受您的 AI 智能体之旅！** 🚀
