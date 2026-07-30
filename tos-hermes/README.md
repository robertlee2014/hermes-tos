# Hermes for TOS 7

Hermes 是一款自进化 AI 智能体应用，专为 TOS 7 系统设计。提供可视化工作流编排、多模型支持与持久化记忆，让您轻松构建和运行 AI 任务。

## 应用信息

- **应用名称**: Hermes
- **包标识符**: `com.nousresearch.hermes`
- **应用类型**: Deb 应用（WebUI 内部打开 - iframe 模式）
- **支持架构**: x86_64 (amd64)
- **最低系统要求**: TOS 7.0.0+

## 核心功能

- 🤖 **自进化 AI 智能体**: 自动学习优化，持续改进任务执行能力
- 🎨 **可视化工作流**: 拖拽式界面，轻松编排复杂 AI 任务
- 🔌 **多模型支持**: 兼容本地部署与云端 API，灵活切换
- 💾 **持久化记忆**: 上下文长期保存，支持跨会话连续对话
- 🔒 **安全通信**: Unix Socket + TOS 平台代理，数据不出内网
- 📦 **智能安装**: 多层 pip 镜像与 GitHub 代理兜底，安装更稳定

## 安装方式

### 方式一：TNAS 应用中心（推荐）

1. 登录 TOS 7 系统
2. 打开「应用中心」
3. 搜索 "**Hermes**"
4. 点击「安装」按钮

系统将自动下载并配置所有依赖，无需手动操作。

### 方式二：手动安装 deb 包

```bash
# 进入项目目录
cd tos-hermes

# 构建 deb 包
./build.sh

# 安装 deb 包
sudo dpkg -i ../com.nousresearch.hermes_*.deb

# 启动服务
sudo systemctl start com.nousresearch.hermes

# 查看运行状态
sudo systemctl status com.nousresearch.hermes
```

## 访问方式

安装完成后，通过以下方式访问 Hermes：

### 方法 1：TOS 桌面（推荐）
1. 登录 TOS 网页界面
2. 在桌面或应用中心找到 "**Hermes**" 图标
3. 点击图标，应用将在新窗口中打开

### 方法 2：浏览器直接访问

```
http://<您的 NAS IP>/com.nousresearch.hermes/
```

> **关于 URL 路径的说明**：
> - 路径 `/com.nousresearch.hermes/` 必须与应用包标识符完全一致，**无法简化**。
> - 这是 TOS 7 的安全路由机制，确保不同应用间的命名空间隔离。
> - **推荐方式**：通过 TOS 桌面应用图标访问，自动跳转且无需记忆地址。

> **注意**: 应用通过 TOS 平台统一代理，不直接暴露端口，确保安全性。

## 技术架构

### 目录结构

```
/usr/local/com.nousresearch.hermes/
├── bin/
│   └── hermes-start.sh          # 启动脚本
├── images/icons/
│   └── com.nousresearch.hermes.svg  # 应用图标
├── init.d/
│   └── com.nousresearch.hermes.service  # systemd 服务配置
└── data/                        # 运行时数据（首次启动时生成）
    ├── venv/                    # Python 虚拟环境
    ├── hermes-webui/            # WebUI 源码
    └── workspace/               # Agent 工作区与记忆存储
```

### 通信机制

| 组件 | 实现方式 |
|------|---------|
| **前端展示** | TOS 桌面内嵌 iframe |
| **后端服务** | Unix Socket (`/var/api/com.nousresearch.hermes.sock`) |
| **请求代理** | TOS 平台代理 (`/v2/proxy/com.nousresearch.hermes/`) |
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
dpkg-deb --build . ../com.nousresearch.hermes_$(date +%Y%m%d)_amd64.deb
sha256sum ../com.nousresearch.hermes_*.deb > ../com.nousresearch.hermes_*.deb.sha256
```

### 配置校验

```bash
# 校验 config.ini JSON 格式
python3 -c "import json; json.load(open('config.ini'))"

# 校验语言文件（14 种语言）
python3 -c "
with open('com.nousresearch.hermes.lang') as f:
    langs = [l.split('=')[0] for l in f if '=' in l]
    print(f'已支持 {len(langs)} 种语言：{langs}')
"

# 校验 SVG 图标格式
grep -q 'viewBox' usr/local/com.nousresearch.hermes/images/icons/com.nousresearch.hermes.svg && echo '图标格式正确'
```

### CI/CD

项目包含 GitHub Actions 工作流，推送代码后自动构建并上传 deb 包到 Release。

## 常见问题

### Q: 安装后无法启动？

**解决方案**:
```bash
# 查看详细日志
journalctl -u com.nousresearch.hermes -n 50 --no-pager

# 查看安装日志
cat /var/log/com.nousresearch.hermes/install.log

# 重启服务
sudo systemctl restart com.nousresearch.hermes
```

### Q: 如何重置所有数据？

**警告**: 此操作将删除所有工作流、记忆和配置！

```bash
sudo systemctl stop com.nousresearch.hermes
sudo rm -rf /usr/local/com.nousresearch.hermes/data
sudo systemctl start com.nousresearch.hermes
```

### Q: 如何查看版本号？

```bash
# 查看已安装包版本
dpkg -l | grep com.nousresearch.hermes

# 或在应用内查看（设置页面）
```

### Q: 会占用系统端口吗？

不会。本应用使用 Unix Socket 进行内部通信，不占用任何 TCP/UDP 端口，由 TOS 平台统一代理转发，避免端口冲突。

## 升级与卸载

### 升级应用
```bash
sudo dpkg -i com.nousresearch.hermes_new_version.deb
sudo systemctl restart com.nousresearch.hermes
```

### 卸载应用
```bash
sudo apt remove com.nousresearch.hermes
# 或
sudo dpkg -r com.nousresearch.hermes
```

> 卸载时会询问是否保留数据，根据需求选择即可。

## 相关资源

- **项目主页**: https://github.com/NousResearch/hermes-agent
- **官方文档**: https://nousresearch.com/docs
- **TOS 开发指南**: https://github.com/TerraMasterOfficial/test2026

## 许可证

Apache License 2.0

---

**享受您的 AI 智能体之旅！** 🚀
