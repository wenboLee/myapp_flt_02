#!/bin/bash

# FFmpeg 检测测试脚本

echo "========================================"
echo "FFmpeg 检测测试"
echo "========================================"
echo ""

echo "1. 检查 ffmpeg 是否在 PATH 中..."
if command -v ffmpeg &> /dev/null; then
    echo "✓ ffmpeg 在 PATH 中"
    FFMPEG_PATH=$(which ffmpeg)
    echo "  路径: $FFMPEG_PATH"
    echo "  版本: $(ffmpeg -version 2>&1 | head -n 1)"
else
    echo "✗ ffmpeg 不在 PATH 中"
fi

echo ""
echo "2. 检查常见安装位置..."

# 常见路径
COMMON_PATHS=(
    "/opt/homebrew/bin/ffmpeg"
    "/usr/local/bin/ffmpeg"
    "/usr/bin/ffmpeg"
    "/opt/local/bin/ffmpeg"
)

for path in "${COMMON_PATHS[@]}"; do
    if [ -f "$path" ]; then
        echo "✓ 找到: $path"
        # 检查是否可执行
        if [ -x "$path" ]; then
            echo "  可执行: 是"
        else
            echo "  可执行: 否"
        fi
    else
        echo "✗ 未找到: $path"
    fi
done

echo ""
echo "3. 检查当前环境变量 PATH..."
echo "  $PATH"

echo ""
echo "4. 推荐操作..."

if command -v ffmpeg &> /dev/null; then
    echo "✓ ffmpeg 已正确安装，应用应该能检测到"
    echo ""
    echo "如果应用仍然检测不到，请："
    echo "1. 重启应用"
    echo "2. 点击应用中的「FFmpeg 诊断信息」按钮查看详细信息"
else
    echo "✗ 未检测到 ffmpeg"
    echo ""
    echo "请安装 ffmpeg："
    echo "  brew install ffmpeg"
    echo ""
    echo "或者使用构建脚本打包 ffmpeg 到应用："
    echo "  ./build_macos_dmg_with_ffmpeg.sh"
fi

echo ""
echo "========================================"

