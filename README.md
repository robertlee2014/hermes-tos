# Hermes AI Agent — TOS 7 Native Application (.deb)

> **⚠️ 重要声明：本仓库仅为 TOS 打包层**
>
> 本 `.deb` 应用是对以下两个上游项目的 **TOS 原生封装**，并非独立项目：
> - 🤖 **[NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)** — 自进化 AI 智能体核心
> - 🖥️ **[nesquena/hermes-webui](https://github.com/nesquena/hermes-webui)** — Hermes Agent 的 Web 管理界面
>
> 本仓库**不包含**这两个项目的源码，安装时从 GitHub 动态下载最新版本（支持本地兜底）。

## 项目定位

| 组件 | 来源 | 说明 |
|------|------|------|
| **AI 智能体** | [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) | 通过 pip 安装到 venv |
| **Web 界面** | [nesquena/hermes-webui](https://github.com/nesquena/hermes-webui) | 安装时 git clone |
| **deb 打包层** | 本仓库 | deb 元数据 + 生命周期脚本 |

本仓库只负责：
- 将上述两个项目打包成 TOS 可识别的 `.deb` 格式
- 处理 TOS 安装/卸载/升级生命周期
- 解决国内网络访问 GitHub 的困难（多级镜像/代理兜底 + **本地源码兜底**）
- 提供多磁盘支持（自动检测安装卷，在对应卷创建 `HermesWorkspace`）
- 支持用户自定义源码路径（配置文件/环境变量）

**所有 AI 功能、WebUI 界面均由上游项目提供。**

## 🏗️ 项目结构

```
tos-hermes/
├── DEBIAN/
│   ├── control                 # deb 包控制信息
│   ├── preinst                 # 安装前：检测目标磁盘卷
│   ├── postinst                # ★ 核心安装逻辑（venv, pip, webui 下载，本地兜底）
│   ├── prerm                   # 卸载前：停止服务
│   └── postrm                  # 卸载后：清理数据
├── usr/local/hermes-app/
│   ├── bin/
│   │   └── hermes-start.sh     # 启动脚本
│   ├── init.d/
│   │   └── hermes-app.service  # systemd 服务
│   ├── images/icons/
│   │   └── hermes-app.svg      # 应用图标
│   ├── ui/                     # ★ UI 配置（桌面入口）
│   │   ├── config              # 应用入口配置
│   │   └── images/
│   │       ├── icon_64.png     # 64x64 图标
│   │       └── icon_256.png    # 256x256 图标
│   └── etc/
│       └── sources.conf.example # 源码路径配置示例
├── config.ini                  # TOS 应用中心配置
├── hermes-app.lang             # 多语言支持
├── build.sh                    # 构建脚本
└── README.md                   # 本文件
```

## 🎯 设计原则

- **纯原生**：不依赖 Docker，使用 TOS 预装的 Python 3
- **在线安装**：安装时现场创建 venv，通过网络下载 hermes-agent 和 hermes-webui
- **多层网络兜底**：
  - **pip 镜像链**：阿里云 → 清华 TUNA → 中科大 USTC → 华为云 → 腾讯云 → PyPI 官方
  - **GitHub 代理链**：ghproxy.com → coderkeeper → gitclone → ddlc → 直连
- **本地源码兜底**：支持用户预先上传源码到任意路径（网络失败时自动使用）
- **多磁盘支持**：自动检测 TOS 磁盘卷（/volume1-/volume5），在对应卷创建 `HermesWorkspace`
- **自定义源码路径**：支持三种方式指定源码位置：
  1. 配置文件 `/etc/hermes-app/sources.conf`
  2. 环境变量 `HERMES_AGENT_SOURCE`, `HERMES_WEBUI_SOURCE`
  3. 默认路径 `${DATA_DIR}/hermes-agent-source`, `${DATA_DIR}/hermes-webui-source`
- **不捆绑源码**：deb 仅含元数据和脚本（~13KB），业务代码安装时动态获取

## 🚀 构建

```bash
cd tos-hermes
chmod +x build.sh
./build.sh              # 自动递增 patch 版本
./build.sh 0.2.0        # 指定新版本
./build.sh --noinc      # 保持当前版本
```

## 📦 安装

### 方式一：TOS 应用中心（推荐）

1. 从 [Releases](https://github.com/huxinga1/hermes-fnos/releases) 下载最新的 `.deb` 文件
2. 在 TOS → **应用中心** → **手动安装** → 选择 deb 文件
3. 安装过程中：
   - 自动检测目标磁盘卷
   - 在该卷创建 `/HermesWorkspace/` 目录
   - 尝试网络下载源码（多层代理兜底）
   - 若失败，检查本地兜底路径

### 方式二：命令行安装

```bash
sudo dpkg -i hermes-app_0.1.9_amd64.deb
sudo systemctl start hermes-app
```

### 🔧 本地源码兜底（网络受限环境）

如果网络环境无法访问 GitHub，可预先准备源码：

#### 方法 1：配置文件（推荐）

创建 `/etc/hermes-app/sources.conf`：

```bash
sudo mkdir -p /etc/hermes-app
sudo nano /etc/hermes-app/sources.conf
```

内容：

```ini
HERMES_AGENT_SOURCE="/volume1/my-sources/hermes-agent"
HERMES_WEBUI_SOURCE="/volume1/my-sources/hermes-webui"
```

#### 方法 2：环境变量

在安装前设置环境变量：

```bash
export HERMES_AGENT_SOURCE="/volume1/my-sources/hermes-agent"
export HERMES_WEBUI_SOURCE="/volume1/my-sources/hermes-webui"
sudo dpkg -i hermes-app_0.1.9_amd64.deb
```

#### 方法 3：默认路径

将源码解压到默认位置：

```bash
/volumeX/HermesWorkspace/hermes-agent-source/
/volumeX/HermesWorkspace/hermes-webui-source/
```

**优先级**：环境变量 > 配置文件 > 默认路径

## 🌐 访问

| 方式 | 地址 |
|------|------|
| **内网** | `http://NAS_IP:8787` |
| **TOS 穿透** | 应用中心提供的官方隧道链接 |
| **桌面入口** | 应用图标 → 新窗口打开 |

## 🔄 升级

```bash
# 下载新版 deb
sudo dpkg -i hermes-app_0.2.0_amd64.deb

# 或从应用中心点击升级
```

升级时会自动：
- 备份用户数据（`HermesWorkspace` 不受影响）
- 更新静态文件（`/usr/local/hermes-app/`）
- 保留虚拟环境和已安装的依赖

## 📂 目录结构

| 路径 | 用途 | 是否持久化 |
|------|------|-----------|
| `/usr/local/hermes-app/` | 静态文件（二进制、脚本、图标） | ❌ 升级时覆盖 |
| `/volumeX/HermesWorkspace/` | 动态数据（venv, 源码，工作区） | ✅ 永久保留 |
| `/var/log/hermes-app/` | 日志文件 | ✅ 永久保留 |
| `/etc/hermes-app/` | 配置文件 | ✅ 永久保留 |

## 📚 上游项目

| 项目 | 用途 | 安装方式 |
|------|------|----------|
| [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) | AI 智能体核心（pip 包） | `pip install hermes-agent` |
| [nesquena/hermes-webui](https://github.com/nesquena/hermes-webui) | Web 管理界面（Flask 应用） | `git clone` → `pip install -r requirements.txt` |

本仓库仅负责编排上述两个项目的 TOS 集成部署。

## ⚙️ 技术栈

| 组件 | 版本/规格 |
|------|-----------|
| **Hermes Agent** | 最新 PyPI (安装时动态获取) |
| **Hermes WebUI** | 最新 GitHub release (安装时动态获取) |
| **TOS Python** | 3.x（系统预装） |
| **dpkg-deb** | Debian 包工具 |

## 📜 许可

本仓库（deb 打包层）为 TOS 社区贡献的开源项目。上游项目遵循其各自的许可证。

- [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) — Apache 2.0
- [nesquena/hermes-webui](https://github.com/nesquena/hermes-webui) — 请查阅其仓库
