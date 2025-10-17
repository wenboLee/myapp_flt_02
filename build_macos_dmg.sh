#!/bin/bash

# macOS DMG 安装包构建脚本
# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================"
echo "构建 macOS DMG 安装包"
echo -e "========================================${NC}"
echo ""

# 应用信息
APP_NAME="文件拖拽应用"
APP_BUNDLE_NAME="myapp_flt_02"
VERSION="1.0.0"
OUTPUT_DIR="build/macos/dmg"
DMG_NAME="${APP_BUNDLE_NAME}_${VERSION}.dmg"

# 1. 清理构建缓存
echo -e "${YELLOW}[1/5] 清理构建缓存...${NC}"
flutter clean
if [ $? -ne 0 ]; then
    echo -e "${RED}清理失败！${NC}"
    exit 1
fi

# 2. 获取依赖
echo ""
echo -e "${YELLOW}[2/5] 获取依赖...${NC}"
flutter pub get
if [ $? -ne 0 ]; then
    echo -e "${RED}获取依赖失败！${NC}"
    exit 1
fi

# 3. 构建 macOS 应用
echo ""
echo -e "${YELLOW}[3/5] 构建 macOS 应用...${NC}"
flutter build macos --release
if [ $? -ne 0 ]; then
    echo -e "${RED}构建应用失败！${NC}"
    exit 1
fi

# 4. 创建 DMG 目录结构
echo ""
echo -e "${YELLOW}[4/5] 准备 DMG 目录结构...${NC}"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 复制应用到 DMG 目录
APP_PATH="build/macos/Build/Products/Release/${APP_BUNDLE_NAME}.app"
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}找不到构建的应用：$APP_PATH${NC}"
    exit 1
fi

cp -R "$APP_PATH" "$OUTPUT_DIR/"

# 创建应用程序文件夹的软链接
ln -s /Applications "$OUTPUT_DIR/Applications"

# 5. 创建 DMG 文件
echo ""
echo -e "${YELLOW}[5/5] 创建 DMG 文件...${NC}"

# 检查是否安装了 create-dmg
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}未检测到 create-dmg，正在安装...${NC}"
    brew install create-dmg
    if [ $? -ne 0 ]; then
        echo -e "${RED}安装 create-dmg 失败！请手动安装：brew install create-dmg${NC}"
        exit 1
    fi
fi

# 创建 DMG
OUTPUT_DMG="build/macos/${DMG_NAME}"
rm -f "$OUTPUT_DMG"

create-dmg \
  --volname "${APP_NAME}" \
  --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "${APP_BUNDLE_NAME}.app" 150 185 \
  --hide-extension "${APP_BUNDLE_NAME}.app" \
  --app-drop-link 450 185 \
  --no-internet-enable \
  "$OUTPUT_DMG" \
  "$OUTPUT_DIR"

if [ $? -ne 0 ]; then
    echo -e "${RED}创建 DMG 失败！${NC}"
    exit 1
fi

# 清理临时目录
rm -rf "$OUTPUT_DIR"

# 构建成功
echo ""
echo -e "${GREEN}========================================"
echo "构建完成！"
echo -e "========================================${NC}"
echo ""
echo -e "${GREEN}DMG 文件位置: ${OUTPUT_DMG}${NC}"
echo ""
echo -e "文件信息："
ls -lh "$OUTPUT_DMG"
echo ""
echo -e "${CYAN}你可以：${NC}"
echo "1. 双击 DMG 文件进行测试"
echo "2. 拖拽 ${APP_NAME}.app 到 Applications 文件夹安装"
echo "3. 分发 DMG 文件给其他 macOS 用户"
echo ""

# 询问是否打开文件夹
read -p "是否在 Finder 中显示 DMG 文件？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open -R "$OUTPUT_DMG"
fi

echo ""
echo -e "${GREEN}完成！${NC}"

