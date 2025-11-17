# DMG 安装后 FFmpeg 闪退问题修复指南

## 📋 问题描述

在通过 DMG 安装应用后，执行 ffmpeg 的 2x 倍速功能时应用会闪退。

## 🔍 问题根本原因

### 1. **ffmpeg 未被打包到应用中**
原始的 `build_macos_dmg.sh` 脚本没有将 ffmpeg 打包进应用。代码尝试调用系统的 `ffmpeg` 命令，但 DMG 安装的应用在沙盒环境中无法访问系统命令。

### 2. **macOS 沙盒权限不足**
`Release.entitlements` 文件缺少必要的权限：
- ❌ 缺少文件读写权限
- ❌ 缺少执行外部进程的权限
- ❌ 应用沙盒限制了命令执行

## ✅ 已实施的修复方案

### 修复内容

1. **更新了 macOS 权限配置**
   - ✅ 修改 `macos/Runner/Release.entitlements`
   - ✅ 修改 `macos/Runner/DebugProfile.entitlements`
   - ✅ 添加文件访问权限
   - ✅ 禁用应用沙盒（工具型应用需要）
   - ✅ 添加网络访问权限

2. **创建了 FFmpegHelper 工具类**
   - ✅ 文件：`lib/utils/ffmpeg_helper.dart`
   - ✅ 自动检测打包的 ffmpeg
   - ✅ 回退到系统 ffmpeg（如果可用）
   - ✅ 提供统一的 ffmpeg 调用接口

3. **更新了视频处理代码**
   - ✅ 修改 `lib/pages/video_2x/video_2x.dart`
   - ✅ 使用 FFmpegHelper 代替直接调用系统命令
   - ✅ 更好的错误提示信息

4. **创建了新的构建脚本**
   - ✅ 文件：`build_macos_dmg_with_ffmpeg.sh`
   - ✅ 自动检测系统 ffmpeg
   - ✅ 将 ffmpeg 打包到应用的 Resources 目录
   - ✅ 设置正确的执行权限

## 🚀 使用新构建脚本

### 前提条件

确保你的 Mac 已安装 ffmpeg：

```bash
# 检查是否已安装
ffmpeg -version

# 如果未安装，使用 Homebrew 安装
brew install ffmpeg
```

### 构建步骤

1. **运行新的构建脚本**：

```bash
./build_macos_dmg_with_ffmpeg.sh
```

2. **脚本会自动执行**：
   - 检查 ffmpeg 是否安装
   - 清理构建缓存
   - 获取 Flutter 依赖
   - 构建 macOS 应用
   - **将 ffmpeg 打包到应用内**
   - 创建 DMG 安装包

3. **构建完成后**：
   - DMG 文件位于：`build/macos/myapp_flt_02_1.0.2.dmg`
   - 文件大小会比之前大（因为包含了 ffmpeg）

## 📦 打包后的应用结构

```
myapp_flt_02.app/
├── Contents/
│   ├── MacOS/
│   │   └── myapp_flt_02          # 应用主程序
│   ├── Resources/
│   │   ├── ffmpeg                # 打包的 ffmpeg（新增）
│   │   ├── AppIcon.icns
│   │   └── flutter_assets/
│   ├── Frameworks/
│   └── Info.plist
```

## 🔧 FFmpegHelper 工作原理

### 自动路径检测优先级

1. **优先使用打包的 ffmpeg**
   - 路径：`应用.app/Contents/Resources/ffmpeg`
   - 优点：独立、可靠、不依赖系统环境

2. **回退到系统 ffmpeg**
   - 通过 `which ffmpeg` 查找
   - 用于开发环境或用户自行安装了 ffmpeg 的情况

### 代码示例

```dart
// 检查 ffmpeg 是否可用
final isAvailable = await FFmpegHelper.isFFmpegAvailable();

// 获取 ffmpeg 路径
final ffmpegPath = await FFmpegHelper.getFFmpegPath();

// 执行 ffmpeg 命令
await FFmpegHelper.runFFmpegShell(
  '-i "input.mp4" -filter:v "setpts=0.5*PTS" "output.mp4"'
);

// 获取版本信息
final version = await FFmpegHelper.getFFmpegVersion();
```

## 📝 权限配置详解

### Release.entitlements 新增权限

```xml
<!-- 禁用应用沙盒（允许执行外部命令） -->
<key>com.apple.security.app-sandbox</key>
<false/>

<!-- 用户选择的文件读写权限 -->
<key>com.apple.security.files.user-selected.read-write</key>
<true/>

<!-- 下载目录读写权限 -->
<key>com.apple.security.files.downloads.read-write</key>
<true/>

<!-- 网络访问权限 -->
<key>com.apple.security.network.client</key>
<true/>

<!-- 允许 JIT 编译（Flutter 需要） -->
<key>com.apple.security.cs.allow-jit</key>
<true/>
```

### 为什么禁用沙盒？

对于需要执行外部命令（如 ffmpeg）的工具型应用：
- ✅ 必须禁用沙盒才能执行打包的二进制文件
- ✅ 必须禁用沙盒才能访问用户拖放的文件
- ⚠️ 这会使应用无法上架 Mac App Store（但对于直接分发的应用是可以的）

## 🧪 测试检查清单

构建完成后，按以下步骤测试：

### 1. 安装测试

```bash
# 打开 DMG
open build/macos/myapp_flt_02_1.0.2.dmg

# 拖动应用到 Applications 文件夹
# 打开应用（首次可能需要在「系统设置」→「隐私与安全性」中允许）
```

### 2. FFmpeg 功能测试

- [ ] 拖放一个视频文件
- [ ] 点击 "2x" 按钮
- [ ] 检查是否成功生成倍速视频
- [ ] 不应该闪退
- [ ] 应该显示「生成成功」消息

### 3. 验证 ffmpeg 打包

```bash
# 检查 ffmpeg 是否在应用内
ls -lh /Applications/myapp_flt_02.app/Contents/Resources/ffmpeg

# 测试执行
/Applications/myapp_flt_02.app/Contents/Resources/ffmpeg -version
```

### 4. 错误处理测试

- [ ] 如果删除打包的 ffmpeg，应用应显示「未检测到 ffmpeg」
- [ ] 如果系统有 ffmpeg，应自动回退使用系统版本

## 🐛 故障排除

### 问题 1：构建脚本报错「未检测到 ffmpeg」

**解决方案**：
```bash
# 安装 ffmpeg
brew install ffmpeg

# 验证安装
which ffmpeg
ffmpeg -version
```

### 问题 2：应用首次打开时提示「无法验证开发者」

**解决方案**：
1. 右键点击应用
2. 选择「打开」
3. 在弹出的对话框中点击「打开」

或者：
1. 打开「系统设置」
2. 前往「隐私与安全性」
3. 找到应用并点击「仍要打开」

### 问题 3：DMG 创建失败

**解决方案**：
```bash
# 确保 create-dmg 已安装
brew install create-dmg

# 清理旧文件
rm -rf build/macos/dmg
rm -f build/macos/*.dmg
rm -f build/macos/rw.*.dmg

# 重新运行构建
./build_macos_dmg_with_ffmpeg.sh
```

### 问题 4：应用仍然闪退

**调试步骤**：

1. **查看控制台日志**：
   ```bash
   # 打开 Console.app 查看崩溃日志
   open /Applications/Utilities/Console.app
   ```

2. **验证权限配置**：
   ```bash
   # 检查 entitlements
   codesign -d --entitlements - /Applications/myapp_flt_02.app
   ```

3. **手动测试 ffmpeg**：
   ```bash
   # 在应用内直接运行 ffmpeg
   /Applications/myapp_flt_02.app/Contents/Resources/ffmpeg -version
   ```

### 问题 5：ffmpeg 没有被打包进去

**检查方案**：
```bash
# 查看应用内容
ls -la /Applications/myapp_flt_02.app/Contents/Resources/

# 如果没有 ffmpeg，手动复制
cp $(which ffmpeg) /Applications/myapp_flt_02.app/Contents/Resources/
chmod +x /Applications/myapp_flt_02.app/Contents/Resources/ffmpeg
```

## 📊 文件大小对比

| 项目 | 不含 ffmpeg | 含 ffmpeg |
|------|------------|----------|
| .app 大小 | ~50 MB | ~150 MB |
| DMG 大小 | ~30 MB | ~90 MB |

*注意：ffmpeg 大约占用 100 MB*

## 🔒 安全注意事项

### 禁用沙盒的影响

**优点**：
- ✅ 可以执行打包的 ffmpeg
- ✅ 可以访问用户拖放的文件
- ✅ 功能完整，用户体验好

**缺点**：
- ⚠️ 无法上架 Mac App Store
- ⚠️ 需要用户手动允许打开（首次）
- ⚠️ 应用可以访问更多系统资源

**适用场景**：
- ✅ 工具型应用
- ✅ 直接分发（非 App Store）
- ✅ 需要执行外部命令的应用

## 📚 相关文档

- [macOS App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)
- [Entitlements 配置](https://developer.apple.com/documentation/bundleresources/entitlements)
- [Flutter macOS 部署](https://docs.flutter.dev/deployment/macos)
- [FFmpeg 官方文档](https://ffmpeg.org/documentation.html)

## 🎯 总结

通过以下三个关键修复：

1. ✅ **更新权限配置**：允许应用执行外部命令和访问文件
2. ✅ **打包 ffmpeg**：将 ffmpeg 嵌入应用，不依赖系统环境
3. ✅ **代码重构**：使用 FFmpegHelper 自动检测和使用 ffmpeg

现在你的应用应该可以在 DMG 安装后正常使用 ffmpeg 功能，不会再闪退！🎉

## 📞 获取帮助

如果问题仍然存在，请提供以下信息：

1. macOS 版本：`sw_vers`
2. Flutter 版本：`flutter --version`
3. FFmpeg 版本：`ffmpeg -version`
4. 控制台错误日志（Console.app）
5. 应用崩溃报告（在「系统设置」→「隐私与安全性」→「分析与改进」中查看）

