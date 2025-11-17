#!/bin/bash

# macOS DMG 安装包构建脚本（包含 ffmpeg）
# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================"
echo "构建 macOS DMG 安装包（包含 ffmpeg）"
echo -e "========================================${NC}"
echo ""

# 应用信息
APP_NAME="文件拖拽应用"
APP_BUNDLE_NAME="myapp_flt_02"
VERSION="1.0.2"
OUTPUT_DIR="build/macos/dmg"
DMG_NAME="${APP_BUNDLE_NAME}_${VERSION}.dmg"

# 1. 检查 ffmpeg 是否已安装
echo -e "${YELLOW}[1/7] 检查 ffmpeg...${NC}"
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}错误：未检测到 ffmpeg！${NC}"
    echo -e "${YELLOW}请先安装 ffmpeg：${NC}"
    echo -e "  brew install ffmpeg"
    exit 1
fi

FFMPEG_PATH=$(which ffmpeg)
echo -e "${GREEN}✓ 找到 ffmpeg: $FFMPEG_PATH${NC}"

# 2. 清理构建缓存
echo ""
echo -e "${YELLOW}[2/7] 清理构建缓存...${NC}"
flutter clean
if [ $? -ne 0 ]; then
    echo -e "${RED}清理失败！${NC}"
    exit 1
fi

# 3. 获取依赖
echo ""
echo -e "${YELLOW}[3/7] 获取依赖...${NC}"
flutter pub get
if [ $? -ne 0 ]; then
    echo -e "${RED}获取依赖失败！${NC}"
    exit 1
fi

# 4. 构建 macOS 应用
echo ""
echo -e "${YELLOW}[4/7] 构建 macOS 应用...${NC}"
flutter build macos --release
if [ $? -ne 0 ]; then
    echo -e "${RED}构建应用失败！${NC}"
    exit 1
fi

# 5. 将 ffmpeg 打包到应用内
echo ""
echo -e "${YELLOW}[5/7] 将 ffmpeg 打包到应用内...${NC}"
APP_PATH="build/macos/Build/Products/Release/${APP_BUNDLE_NAME}.app"
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}找不到构建的应用：$APP_PATH${NC}"
    exit 1
fi

# 创建 Resources 目录（如果不存在）
RESOURCES_DIR="$APP_PATH/Contents/Resources"
mkdir -p "$RESOURCES_DIR"

# 复制 ffmpeg 到应用内
echo -e "${CYAN}复制 ffmpeg 到应用内...${NC}"
cp "$FFMPEG_PATH" "$RESOURCES_DIR/ffmpeg"
chmod +x "$RESOURCES_DIR/ffmpeg"

# 验证复制成功
if [ -f "$RESOURCES_DIR/ffmpeg" ]; then
    FFMPEG_SIZE=$(ls -lh "$RESOURCES_DIR/ffmpeg" | awk '{print $5}')
    echo -e "${GREEN}✓ ffmpeg 已打包 (大小: $FFMPEG_SIZE)${NC}"
else
    echo -e "${RED}❌ ffmpeg 打包失败！${NC}"
    exit 1
fi

# 6. 创建 DMG 目录结构
echo ""
echo -e "${YELLOW}[6/7] 准备 DMG 目录结构...${NC}"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 复制应用到 DMG 目录
cp -R "$APP_PATH" "$OUTPUT_DIR/"

# 创建应用程序文件夹的软链接
ln -s /Applications "$OUTPUT_DIR/Applications"

# 7. 创建 DMG 文件
echo ""
echo -e "${YELLOW}[7/7] 创建 DMG 文件...${NC}"

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
TEMP_OUTPUT_DMG="build/macos/temp_${DMG_NAME}"
FINAL_OUTPUT_DMG="build/macos/${DMG_NAME}"

# 删除可能存在的旧文件
rm -f "$TEMP_OUTPUT_DMG" "$FINAL_OUTPUT_DMG"
rm -f build/macos/rw.*.dmg

# 检查图标文件是否存在
ICON_PARAM=""
if [ -f "$APP_PATH/Contents/Resources/AppIcon.icns" ]; then
    ICON_PARAM="--volicon $APP_PATH/Contents/Resources/AppIcon.icns"
    echo -e "${GREEN}找到应用图标${NC}"
else
    echo -e "${YELLOW}未找到 AppIcon.icns，将使用默认图标${NC}"
fi

# 创建 DMG
echo -e "${CYAN}创建 DMG...${NC}"
create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_BUNDLE_NAME}.app" 150 190 \
    --hide-extension "${APP_BUNDLE_NAME}.app" \
    --app-drop-link 450 190 \
    $ICON_PARAM \
    "$FINAL_OUTPUT_DMG" \
    "$OUTPUT_DIR"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ DMG 创建成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${CYAN}文件位置：${NC}"
    echo -e "  $FINAL_OUTPUT_DMG"
    echo ""
    
    # 显示文件大小
    DMG_SIZE=$(ls -lh "$FINAL_OUTPUT_DMG" | awk '{print $5}')
    echo -e "${CYAN}文件大小：${NC}$DMG_SIZE"
    echo ""
    
    # 显示 ffmpeg 信息
    echo -e "${CYAN}已打包组件：${NC}"
    echo -e "  ✓ ${APP_NAME} 应用"
    echo -e "  ✓ ffmpeg (已集成到应用内)"
    echo ""
    
    echo -e "${YELLOW}注意事项：${NC}"
    echo -e "1. 首次打开时，系统可能提示「无法验证开发者」"
    echo -e "   解决方法：右键点击应用 → 选择「打开」→ 确认打开"
    echo -e "2. 或在「系统设置」→「隐私与安全性」中允许打开"
    echo -e "3. ffmpeg 已打包在应用内，无需单独安装"
    echo ""
    
    # 提示打开 Finder
    echo -e "${CYAN}是否在 Finder 中显示？(y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        open -R "$FINAL_OUTPUT_DMG"
    fi
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ DMG 创建失败${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${YELLOW}请检查：${NC}"
    echo -e "1. create-dmg 是否正确安装"
    echo -e "2. 是否有足够的磁盘空间"
    echo -e "3. 构建输出目录是否正确"
    exit 1
fi

