# FFmpeg 检测问题修复

## 🔍 问题描述

应用提示「未检测到 ffmpeg」，即使 macOS 系统已经通过 Homebrew 安装了 ffmpeg。

## 💡 问题原因

Flutter 应用的进程环境变量与终端环境不同。终端中的 `PATH` 可能包含 `/opt/homebrew/bin` 或 `/usr/local/bin`，但应用进程可能无法访问这些路径。

## ✅ 已实施的修复

### 1. 改进的 FFmpegHelper

更新了 `lib/utils/ffmpeg_helper.dart`，现在会：

#### 多重检测策略

```
1. 检查应用内打包的 ffmpeg
   ↓
2. 检查常见安装路径（直接文件检查）
   - /opt/homebrew/bin/ffmpeg  (Apple Silicon Mac)
   - /usr/local/bin/ffmpeg     (Intel Mac)
   - /usr/bin/ffmpeg           (系统安装)
   - /opt/local/bin/ffmpeg     (MacPorts)
   ↓
3. 使用 which 命令（设置完整 PATH）
   ↓
4. 直接尝试执行常见路径的 ffmpeg
```

#### 为什么这样改进？

- ❌ **之前**：只用 `which ffmpeg`，依赖环境变量 PATH
- ✅ **现在**：直接检查文件是否存在 + 多重策略回退

### 2. 新增诊断功能

在应用中添加了「FFmpeg 诊断信息」按钮（AppBar 右上角 ℹ️ 图标）

**诊断信息包括**：
- 当前平台
- 打包的 ffmpeg 路径
- 系统 ffmpeg 路径
- 所有检查过的路径及结果
- 最终检测到的路径
- FFmpeg 版本信息
- 错误信息（如果有）

## 🚀 使用方法

### 方法一：查看诊断信息（推荐）⭐

1. **运行应用**（开发模式）：
   ```bash
   flutter run -d macos
   ```

2. **点击诊断按钮**：
   - 在应用右上角找到 ℹ️ 图标
   - 点击查看详细的检测信息

3. **检查诊断结果**：
   ```
   平台: macos
   
   打包的 ffmpeg: 未找到
   系统 ffmpeg: /opt/homebrew/bin/ffmpeg
   
   检查的路径:
     ✓ /opt/homebrew/bin/ffmpeg
     ✗ /usr/local/bin/ffmpeg
     ✗ /usr/bin/ffmpeg
     ✗ /opt/local/bin/ffmpeg
   
   最终路径: /opt/homebrew/bin/ffmpeg
   是否可用: 是
   
   版本: ffmpeg version 6.0 ...
   ```

### 方法二：使用测试脚本

在终端运行测试脚本：

```bash
./test_ffmpeg_detection.sh
```

这会显示：
- ffmpeg 是否在 PATH 中
- 常见路径中是否存在 ffmpeg
- 当前的 PATH 环境变量
- 推荐的操作步骤

### 方法三：手动验证

```bash
# 1. 检查 ffmpeg 是否安装
which ffmpeg
ffmpeg -version

# 2. 检查常见路径
ls -la /opt/homebrew/bin/ffmpeg
ls -la /usr/local/bin/ffmpeg

# 3. 运行应用并查看控制台日志
flutter run -d macos
# 应该看到类似：
# ✓ 找到系统 ffmpeg: /opt/homebrew/bin/ffmpeg
```

## 🔧 故障排除

### 问题 1：诊断显示「未找到」

**可能原因**：
- ffmpeg 未安装
- ffmpeg 安装在非标准位置

**解决方案**：

```bash
# 安装或重新安装 ffmpeg
brew install ffmpeg

# 或者，如果已安装但检测不到
brew reinstall ffmpeg

# 验证安装
which ffmpeg
# 应该显示: /opt/homebrew/bin/ffmpeg 或 /usr/local/bin/ffmpeg
```

### 问题 2：诊断显示路径但仍提示未检测到

**可能原因**：
- 文件权限问题
- ffmpeg 损坏

**解决方案**：

```bash
# 检查文件权限
ls -la $(which ffmpeg)
# 应该显示: -rwxr-xr-x (可执行)

# 如果没有执行权限
chmod +x $(which ffmpeg)

# 测试 ffmpeg 是否能运行
ffmpeg -version
```

### 问题 3：Intel Mac vs Apple Silicon Mac

**Apple Silicon (M1/M2/M3)**：
- Homebrew 安装路径：`/opt/homebrew/bin/ffmpeg`
- 应用应该自动检测到

**Intel Mac**：
- Homebrew 安装路径：`/usr/local/bin/ffmpeg`
- 应用应该自动检测到

**验证架构**：
```bash
uname -m
# arm64 = Apple Silicon
# x86_64 = Intel

# 查看 Homebrew 路径
brew --prefix
# /opt/homebrew = Apple Silicon
# /usr/local = Intel
```

### 问题 4：开发模式正常，DMG 安装后失败

这是正常的！因为 DMG 应用没有打包 ffmpeg。

**解决方案**：

使用新的构建脚本，自动打包 ffmpeg：

```bash
./build_macos_dmg_with_ffmpeg.sh
```

这会：
- ✅ 检测系统 ffmpeg
- ✅ 复制到应用 Resources 目录
- ✅ 设置执行权限
- ✅ 创建包含 ffmpeg 的 DMG

## 📊 检测逻辑流程图

```
应用启动
    ↓
FFmpegHelper.getFFmpegPath()
    ↓
检查缓存
    ↓ (无缓存)
检查打包的 ffmpeg
    ├─ macOS: App.app/Contents/Resources/ffmpeg
    └─ Windows: App.exe 同目录/ffmpeg.exe
    ↓ (未找到)
检查常见路径（直接文件检查）
    ├─ /opt/homebrew/bin/ffmpeg  ✓ 找到！
    ├─ /usr/local/bin/ffmpeg
    ├─ /usr/bin/ffmpeg
    └─ /opt/local/bin/ffmpeg
    ↓
缓存路径 & 返回
    ↓
后续调用使用缓存路径
```

## 🎯 最佳实践

### 开发环境

1. **确保安装了 ffmpeg**：
   ```bash
   brew install ffmpeg
   ```

2. **运行时查看诊断信息**：
   - 点击 ℹ️ 按钮
   - 确认检测成功

3. **查看控制台日志**：
   ```bash
   flutter run -d macos
   ```
   应该看到：
   ```
   ✓ 找到系统 ffmpeg: /opt/homebrew/bin/ffmpeg
   ```

### 生产环境（DMG 分发）

1. **使用打包脚本**：
   ```bash
   ./build_macos_dmg_with_ffmpeg.sh
   ```

2. **验证打包**：
   ```bash
   # DMG 安装后，检查 ffmpeg 是否在应用内
   ls -lh /Applications/myapp_flt_02.app/Contents/Resources/ffmpeg
   ```

3. **测试功能**：
   - 打开应用
   - 点击诊断按钮
   - 应该显示：`打包的 ffmpeg: .../Contents/Resources/ffmpeg`

## 📝 代码改进说明

### 改进前（有问题）

```dart
// 只依赖 which 命令
final shell = Shell();
final result = await shell.run('which ffmpeg');
// ❌ 如果 PATH 不包含 ffmpeg，就检测失败
```

### 改进后（健壮）

```dart
// 1. 直接检查常见路径
final commonPaths = [
  '/opt/homebrew/bin/ffmpeg',
  '/usr/local/bin/ffmpeg',
  '/usr/bin/ffmpeg',
  '/opt/local/bin/ffmpeg',
];

for (final ffmpegPath in commonPaths) {
  final file = File(ffmpegPath);
  if (await file.exists()) {
    return ffmpegPath; // ✓ 找到！
  }
}

// 2. 回退到 which（设置完整 PATH）
final shell = Shell(
  environment: {
    'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin',
  },
);
// ...

// 3. 最后直接尝试执行
final result = await Process.run(ffmpegPath, ['-version']);
// ✓ 多重保险
```

## 🧪 测试建议

### 单元测试

```dart
// 测试 ffmpeg 检测
test('FFmpegHelper should detect system ffmpeg', () async {
  final path = await FFmpegHelper.getFFmpegPath();
  expect(path, isNotNull);
  expect(path, contains('ffmpeg'));
});

// 测试诊断功能
test('FFmpegHelper diagnosis should provide details', () async {
  final diagnosis = await FFmpegHelper.diagnose();
  expect(diagnosis['platform'], isNotNull);
  expect(diagnosis['is_available'], isNotNull);
});
```

### 集成测试

1. **在不同 Mac 上测试**：
   - Apple Silicon Mac (M1/M2/M3)
   - Intel Mac
   - 带/不带 ffmpeg 的环境

2. **测试不同安装方式**：
   - Homebrew
   - MacPorts
   - 手动编译安装

3. **测试 DMG 分发**：
   - 打包 ffmpeg 的版本
   - 不打包 ffmpeg 的版本（依赖系统）

## 📚 相关文件

- `lib/utils/ffmpeg_helper.dart` - FFmpeg 检测工具类
- `lib/pages/video_2x/video_2x.dart` - 视频处理页面（含诊断按钮）
- `build_macos_dmg_with_ffmpeg.sh` - 构建脚本（打包 ffmpeg）
- `test_ffmpeg_detection.sh` - 测试脚本
- `FFMPEG_DMG_FIX_GUIDE.md` - DMG 问题完整指南

## 💡 常见问题 FAQ

**Q: 为什么开发时能检测到，打包后检测不到？**
A: 开发时使用系统 ffmpeg，DMG 应用在沙盒中无法访问。需要使用 `build_macos_dmg_with_ffmpeg.sh` 打包 ffmpeg。

**Q: 我应该用哪个构建脚本？**
A: 
- `build_macos_dmg.sh` - 旧脚本，不打包 ffmpeg
- `build_macos_dmg_with_ffmpeg.sh` - 新脚本，自动打包 ffmpeg（推荐）

**Q: 诊断按钮在哪里？**
A: 应用右上角的 ℹ️ (info_outline) 图标。

**Q: 如何确认 ffmpeg 已正确安装？**
A: 运行 `which ffmpeg` 和 `ffmpeg -version`，应该有输出。

**Q: 支持哪些 ffmpeg 安装方式？**
A: Homebrew、MacPorts、手动编译等，只要安装在标准路径即可。

## 🎉 总结

通过这次改进：

1. ✅ **多重检测策略** - 不再依赖单一的环境变量
2. ✅ **直接路径检查** - 检查常见安装位置的文件
3. ✅ **诊断功能** - 方便调试和排查问题
4. ✅ **测试工具** - 提供脚本快速验证
5. ✅ **详细文档** - 完整的故障排除指南

现在应用应该能在大多数情况下正确检测到 ffmpeg！如果还有问题，使用诊断按钮查看详细信息。🎊

