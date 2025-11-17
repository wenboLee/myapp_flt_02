# 🚀 快速修复 - DMG FFmpeg 闪退问题

## 问题
DMG 安装后，执行 ffmpeg 2x 倍速功能闪退。

## 快速解决

### 方法一：使用新的构建脚本（推荐）⭐

```bash
# 确保安装了 ffmpeg
brew install ffmpeg

# 使用新脚本构建（会自动打包 ffmpeg）
./build_macos_dmg_with_ffmpeg.sh
```

### 方法二：修复现有构建（临时方案）

如果你已经构建了 DMG 但没有打包 ffmpeg，可以手动修复：

```bash
# 1. 重新构建（会使用新的权限配置）
flutter clean
flutter build macos --release

# 2. 手动复制 ffmpeg 到应用内
cp $(which ffmpeg) build/macos/Build/Products/Release/myapp_flt_02.app/Contents/Resources/
chmod +x build/macos/Build/Products/Release/myapp_flt_02.app/Contents/Resources/ffmpeg

# 3. 重新创建 DMG
./build_macos_dmg_with_ffmpeg.sh
```

## 已修复的内容

✅ **权限配置**
- 更新了 `Release.entitlements` 和 `DebugProfile.entitlements`
- 添加了文件访问权限
- 禁用了应用沙盒（允许执行外部命令）

✅ **FFmpeg 打包**
- 创建了 `build_macos_dmg_with_ffmpeg.sh` 脚本
- 自动将 ffmpeg 打包到应用内

✅ **代码改进**
- 创建了 `lib/utils/ffmpeg_helper.dart` 工具类
- 更新了 `lib/pages/video_2x/video_2x.dart`
- 自动检测打包的 ffmpeg 或系统 ffmpeg

## 测试

安装后测试 ffmpeg 功能：

```bash
# 1. 安装 DMG
open build/macos/myapp_flt_02_1.0.2.dmg
# 拖动到 Applications

# 2. 验证 ffmpeg 已打包
ls -lh /Applications/myapp_flt_02.app/Contents/Resources/ffmpeg

# 3. 打开应用并测试 2x 倍速功能
```

## 详细文档

- 📖 完整修复指南：[FFMPEG_DMG_FIX_GUIDE.md](./FFMPEG_DMG_FIX_GUIDE.md)
- 🔧 macOS 构建问题：[MACOS_BUILD_FIX.md](./MACOS_BUILD_FIX.md)

## 常见问题

**Q: 首次打开提示「无法验证开发者」？**
A: 右键点击应用 → 选择「打开」→ 确认打开

**Q: 应用仍然闪退？**
A: 查看 Console.app 日志，或运行：
```bash
/Applications/myapp_flt_02.app/Contents/MacOS/myapp_flt_02
```

**Q: 构建脚本找不到 ffmpeg？**
A: 先安装 ffmpeg：`brew install ffmpeg`

