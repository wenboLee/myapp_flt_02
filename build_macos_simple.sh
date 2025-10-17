#!/bin/bash

# macOS 简化构建脚本（不创建 DMG，仅构建 .app）
# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================"
echo "构建 macOS 应用"
echo -e "========================================${NC}"
echo ""

# 应用信息
APP_BUNDLE_NAME="myapp_flt_02"

# 1. 清理构建缓存
echo -e "${YELLOW}[1/3] 清理构建缓存...${NC}"
flutter clean
if [ $? -ne 0 ]; then
    echo -e "${RED}清理失败！${NC}"
    exit 1
fi

# 2. 获取依赖
echo ""
echo -e "${YELLOW}[2/3] 获取依赖...${NC}"
flutter pub get
if [ $? -ne 0 ]; then
    echo -e "${RED}获取依赖失败！${NC}"
    exit 1
fi

# 3. 构建 macOS 应用
echo ""
echo -e "${YELLOW}[3/3] 构建 macOS 应用...${NC}"
flutter build macos --release
if [ $? -ne 0 ]; then
    echo -e "${RED}构建应用失败！${NC}"
    exit 1
fi

# 构建成功
APP_PATH="build/macos/Build/Products/Release/${APP_BUNDLE_NAME}.app"
echo ""
echo -e "${GREEN}========================================"
echo "构建完成！"
echo -e "========================================${NC}"
echo ""
echo -e "${GREEN}应用位置: ${APP_PATH}${NC}"
echo ""
echo -e "${CYAN}你可以：${NC}"
echo "1. 双击 .app 文件直接运行"
echo "2. 拖拽到 Applications 文件夹安装"
echo "3. 压缩后分发给其他用户"
echo ""
echo -e "${YELLOW}提示：如果要创建 DMG 安装包，请运行 ./build_macos_dmg.sh${NC}"
echo ""

# 询问是否打开文件夹
read -p "是否在 Finder 中显示应用？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open -R "$APP_PATH"
fi

echo ""
echo -e "${GREEN}完成！${NC}"

