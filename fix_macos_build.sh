#!/bin/bash

# macOS 构建错误修复脚本
# 解决 "DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion" 错误

echo "🔧 开始修复 macOS 构建问题..."
echo ""

# 步骤 1: 清理 Flutter 构建缓存
echo "📦 步骤 1: 清理 Flutter 构建缓存..."
flutter clean
echo "✅ Flutter 缓存清理完成"
echo ""

# 步骤 2: 获取依赖
echo "📦 步骤 2: 获取 Flutter 依赖..."
flutter pub get
echo "✅ 依赖获取完成"
echo ""

# 步骤 3: 清理 macOS 特定的构建文件
echo "🧹 步骤 3: 清理 macOS 构建文件..."
rm -rf macos/Pods
rm -rf macos/Podfile.lock
rm -rf macos/Flutter/ephemeral
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "✅ macOS 构建文件清理完成"
echo ""

# 步骤 4: 重新安装 CocoaPods
echo "📦 步骤 4: 重新安装 CocoaPods 依赖..."
cd macos
pod repo update
pod install
cd ..
echo "✅ CocoaPods 安装完成"
echo ""

# 步骤 5: 重新生成 Flutter 配置
echo "⚙️  步骤 5: 重新生成 Flutter 配置..."
flutter precache --macos
echo "✅ Flutter 配置生成完成"
echo ""

# 步骤 6: 尝试构建
echo "🚀 步骤 6: 尝试构建 macOS 应用..."
flutter build macos --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ✅ ✅ 构建成功！"
    echo ""
    echo "你的应用位于: build/macos/Build/Products/Release/myapp_flt_02.app"
else
    echo ""
    echo "❌ 构建仍然失败。请尝试以下额外步骤："
    echo ""
    echo "1. 打开 Xcode 检查项目设置："
    echo "   open macos/Runner.xcworkspace"
    echo ""
    echo "2. 在 Xcode 中："
    echo "   - 选择 Runner 项目"
    echo "   - 选择 Runner target"
    echo "   - 在 General 标签页中，检查 Version 和 Build 字段"
    echo "   - 确保 Version 为: 1.0.2"
    echo "   - 确保 Build 为: 3"
    echo ""
    echo "3. 如果以上都正确，尝试在 Xcode 中直接构建"
    echo ""
    echo "4. 检查 Xcode 版本是否为最新版本："
    echo "   xcodebuild -version"
    echo ""
    echo "5. 如果使用的是 Xcode 14+，可能需要更新 macOS 部署目标："
    echo "   在 macos/Runner.xcodeproj 中设置 MACOSX_DEPLOYMENT_TARGET"
fi

