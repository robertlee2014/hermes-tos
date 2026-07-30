#!/bin/bash
# Hermes AI Agent - TOS 7 Deb 包构建脚本
# 按照 TOS 7 规范构建并校验 deb 包

set -e

APP_ID="hermes-app"
VERSION="0.1.9"
ARCH="amd64"
OUTPUT_DIR=".."

echo "=============================================="
echo "Hermes AI Agent - TOS 7 Deb 包构建"
echo "=============================================="
echo ""

# 步骤 1: 清理旧包
echo "[1/6] 清理旧包..."
rm -f "${OUTPUT_DIR}/${APP_ID}_${VERSION}_${ARCH}.deb"
rm -f "${OUTPUT_DIR}/${APP_ID}_${VERSION}_${ARCH}.deb.sha256"

# 步骤 2: 确保所有脚本使用 LF 换行符
echo "[2/6] 检查并转换换行符..."
find . -type f \( -name "*.sh" -o -name "*.service" -o -name "preinst" -o -name "postinst" -o -name "prerm" -o -name "postrm" \) | while read -r file; do
    if grep -q $'\r' "$file"; then
        echo "  转换 CRLF → LF: $file"
        sed -i 's/\r$//' "$file"
    fi
done
echo "  ✓ 换行符检查完成"

# 步骤 3: 校验配置文件
echo "[3/6] 校验配置文件..."

# 校验 config.ini JSON 格式
python3 -c "import json; json.load(open('config.ini'))" || { echo "ERROR: config.ini JSON 格式无效"; exit 1; }
echo "  ✓ config.ini JSON 格式有效"

# 校验 14 种语言
python3 << 'PYEOF'
required_langs = ['zh-cn', 'zh-hk', 'en-us', 'fr-fr', 'de-de',
                  'it-it', 'es-es', 'hu-hu', 'ja-jp', 'ko-kr',
                  'pl-pl', 'ru-ru', 'tr-tr', 'pt-pt']
with open('hermes-app.lang', 'r') as f:
    content = f.read()
for lang in required_langs:
    if f'[{lang}]' not in content:
        print(f"ERROR: 缺少语言：{lang}")
        exit(1)
print("  ✓ 14 种语言全部存在")
PYEOF

# 校验图标
python3 << 'PYEOF'
import json, os
config = json.load(open('config.ini'))
icon_path = config['icon']
icon_file = icon_path.lstrip('/')
full_path = f"usr/local/hermes-app/{icon_file}"
if not os.path.exists(full_path):
    print(f"ERROR: 图标未找到：{full_path}")
    exit(1)
with open(full_path, 'r') as f:
    content = f.read()
if '<svg' not in content or '</svg>' not in content:
    print("ERROR: 不是有效的 SVG 文件")
    exit(1)
if 'viewBox' not in content:
    print("ERROR: SVG 缺少 viewBox 属性")
    exit(1)
print(f"  ✓ 图标校验通过")
PYEOF

# 校验必填字段
python3 << 'PYEOF'
import json
config = json.load(open('config.ini'))
required = ['id', 'icon', 'publisher', 'exec', 'version', 'low_version',
            'category', 'depend', 'platform', 'application_type', 'user',
            'all_user_display']
for field in required:
    if field not in config:
        print(f"ERROR: 缺少必填字段：{field}")
        exit(1)
if config['application_type'] == 'deb':
    if not config.get('system_id'):
        print("ERROR: Deb 应用必须有 system_id")
        exit(1)
    if not config.get('package'):
        print("ERROR: Deb 应用必须有 package")
        exit(1)
if len(config['category']) > 3:
    print("ERROR: 最多 3 个分类")
    exit(1)
print("  ✓ 必填字段校验通过")
PYEOF

# 步骤 4: 设置权限
echo "[4/6] 设置文件权限..."
chmod 755 DEBIAN/preinst DEBIAN/postinst DEBIAN/prerm DEBIAN/postrm
chmod 755 usr/local/hermes-app/bin/hermes-start.sh
echo "  ✓ 权限设置完成"

# 步骤 5: 构建 deb 包
echo "[5/6] 构建 deb 包..."
cd /workspace/tos-hermes
dpkg-deb --build . "${OUTPUT_DIR}/${APP_ID}_${VERSION}_${ARCH}.deb"
echo "  ✓ deb 包构建完成"

# 步骤 6: 生成校验和
echo "[6/6] 生成 SHA-256 校验和..."
cd "${OUTPUT_DIR}"
sha256sum "${APP_ID}_${VERSION}_${ARCH}.deb" > "${APP_ID}_${VERSION}_${ARCH}.deb.sha256"
echo "  ✓ 校验和生成完成"

echo ""
echo "=============================================="
echo "构建完成！"
echo "=============================================="
echo ""
echo "输出文件:"
echo "  - ${APP_ID}_${VERSION}_${ARCH}.deb"
echo "  - ${APP_ID}_${VERSION}_${ARCH}.deb.sha256"
echo ""
echo "安装命令:"
echo "  sudo dpkg -i ${APP_ID}_${VERSION}_${ARCH}.deb"
echo ""
echo "提交到 TNAS 应用中心前，请确保:"
echo "  1. 将代码推送到公开 GitHub/Gitee 仓库"
echo "  2. 上传 deb 包和 sha256 文件到 Release"
echo "  3. 在开发者平台创建应用并关联仓库"
echo ""
