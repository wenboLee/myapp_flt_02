# 文件拖拽应用

这是一个基于 Flutter 开发的 Windows 桌面应用，支持拖拽多个文件并显示文件列表。

## 功能特性

- ✅ 支持拖拽单个或多个文件
- ✅ 拖拽时显示视觉反馈
- ✅ 文件列表展示，包含文件名和完整路径
- ✅ 根据文件类型显示不同图标
- ✅ 支持移除单个文件
- ✅ 支持清空所有文件
- ✅ 空状态提示
- ✅ **视频合并功能**：使用 ffmpeg 合并两个视频文件（支持 m3u8、ts、mp4 等格式）

## 前置要求

### FFmpeg 安装

使用视频合并功能需要先安装 ffmpeg：

**Windows:**
```bash
# 使用 Chocolatey
choco install ffmpeg

# 或使用 Scoop
scoop install ffmpeg

# 或手动下载：https://ffmpeg.org/download.html
```

**macOS:**
```bash
brew install ffmpeg
```

**Linux:**
```bash
sudo apt install ffmpeg
```

安装后，在命令行输入 `ffmpeg -version` 验证是否安装成功。

## 运行应用

### 在 Windows 上运行

```bash
# 进入项目目录
cd myapp_flt_02

# 安装依赖
flutter pub get

# 运行应用
flutter run -d windows
```

### 构建 Windows 应用

```bash
# 构建 Release 版本
flutter build windows --release

# 构建产物在：build/windows/x64/runner/Release/
```

## 使用说明

### 基础操作

1. 启动应用后，会看到一个拖拽区域
2. 从文件资源管理器中选择一个或多个文件
3. 拖拽文件到拖拽区域
4. 松开鼠标释放文件
5. 文件列表会显示所有拖拽的文件
6. 点击文件右侧的 "×" 按钮可以移除单个文件
7. 点击右上角的清空按钮可以清空所有文件

### 视频合并操作

1. 拖拽至少 2 个视频文件（如 `video.m3u8` 和 `audio.m3u8`）到应用中
2. 点击操作栏中的"合并视频"按钮
3. 选择输出文件的保存位置
4. 等待合并完成
5. 合并成功后会显示输出文件名，可点击"打开文件夹"查看结果

**支持的命令格式：**
```bash
ffmpeg -i video.m3u8 -i audio.m3u8 -c copy output.mp4
```

**注意事项：**
- 需要先安装 ffmpeg 才能使用视频合并功能
- 支持的视频格式：m3u8、ts、mp4、avi、mov、mkv、flv、wmv
- 合并时取前两个视频文件作为输入

## 支持的文件类型图标

应用会根据文件扩展名显示不同的图标：

- 📄 PDF - `.pdf`
- 📝 Word - `.doc`, `.docx`
- 📊 Excel - `.xls`, `.xlsx`
- 🖼️ 图片 - `.jpg`, `.jpeg`, `.png`, `.gif`
- 🎬 视频 - `.mp4`, `.avi`, `.mov`
- 🎵 音频 - `.mp3`, `.wav`
- 📦 压缩包 - `.zip`, `.rar`
- 📃 文本 - `.txt`
- 📎 其他文件类型

## 技术栈

- **Flutter**: 3.9.2+
- **desktop_drop**: 0.7.0 - 桌面文件拖拽支持
- **cross_file**: 0.3.4+2 - 跨平台文件抽象
- **process_run**: 1.2.0 - 执行系统命令
- **file_picker**: 8.1.6 - 文件选择器
- **path**: 1.9.0 - 路径处理
- **Material Design 3** - 现代化 UI 设计
- **FFmpeg** - 视频处理工具

## 项目结构

```
lib/
  ├── main.dart                    # 应用入口
  │   └── MyApp                    # 应用主类
  └── pages/
      └── home/
          └── home_page.dart       # 首页文件
              ├── FileDropScreen   # 文件拖拽界面
              └── _FileListItem    # 文件列表项组件
```

## 开发环境要求

- Flutter SDK 3.9.2 或更高版本
- Dart SDK 3.2 或更高版本
- Windows 10 或更高版本（用于 Windows 构建）
- Visual Studio 2022 with C++ Desktop Development（Windows 构建依赖）

## 许可证

本项目仅供学习和参考使用。
