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

## 重要说明

### macOS 应用沙盒配置

本应用**已禁用 macOS 应用沙盒**以支持：
- 执行系统中的 ffmpeg 命令
- 访问用户文件系统

**影响：**
- ✅ 可以正常使用 Homebrew 安装的 ffmpeg
- ✅ 可以访问任意文件夹保存输出文件
- ⚠️ **不能通过 Mac App Store 分发**（仅限直接分发或开发使用）

**如果需要 App Store 发布：**
需要将 ffmpeg 打包到应用内部，并重新启用应用沙盒。

## 运行应用

### 在 macOS 上运行

```bash
# 进入项目目录
cd myapp_flt_02

# 安装依赖
flutter pub get

# 清理缓存（首次运行或修改配置后）
flutter clean

# 运行应用
flutter run -d macos
```

### 构建 macOS 安装包

本项目支持两种 macOS 构建方式：

#### 方法 1：创建 DMG 安装包（推荐）

**使用自动化脚本：**
```bash
# 在项目根目录下运行
./build_macos_dmg.sh
```

**前置要求：**
- 需要安装 `create-dmg` 工具（脚本会自动安装）
- 或手动安装：`brew install create-dmg`

**特点：**
- ✅ 创建专业的 DMG 安装包
- ✅ 包含背景、图标布局
- ✅ 用户只需拖拽到 Applications 即可安装

#### 方法 2：构建 .app 应用（快速）

**使用简化脚本：**
```bash
# 在项目根目录下运行
./build_macos_simple.sh
```

**特点：**
- ✅ 快速构建，无需额外工具
- ✅ 直接生成 .app 文件
- ✅ 可以压缩后分发

#### 方法 3：手动构建

```bash
# 1. 清理缓存
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 构建 macOS 应用
flutter build macos --release

# 4. 查找构建结果
# .app 文件位于: build/macos/Build/Products/Release/myapp_flt_02.app
```

#### 安装包位置

**DMG 文件：**
```
build/macos/myapp_flt_02_1.0.0.dmg
```

**.app 文件：**
```
build/macos/Build/Products/Release/myapp_flt_02.app
```

#### 测试和安装

**测试 DMG：**
1. 双击 DMG 文件
2. 拖拽应用到 Applications 文件夹
3. 从启动台或 Applications 文件夹运行

**直接使用 .app：**
1. 双击 .app 文件直接运行
2. 或拖拽到 Applications 文件夹

#### 分发说明

- ✅ 可以直接分发 DMG 或 .app
- ✅ 用户无需安装 Flutter SDK
- ✅ 用户需要安装 ffmpeg（通过 Homebrew）
- ⚠️ 首次运行可能需要在"系统偏好设置 > 安全性与隐私"中允许运行
- ⚠️ 应用已禁用沙盒，不能通过 Mac App Store 分发

### 在 Windows 上运行

```bash
# 进入项目目录
cd myapp_flt_02

# 安装依赖
flutter pub get

# 运行应用
flutter run -d windows
```

### 构建 Windows 安装包

本项目支持两种构建方式：

#### 方法 1：使用自动化脚本（推荐）

**使用批处理脚本：**
```bash
# 在项目根目录下，双击或运行
build_windows_installer.bat
```

**使用 PowerShell 脚本：**
```powershell
# 在项目根目录下，右键 "使用 PowerShell 运行"
.\build_windows_installer.ps1
```

#### 方法 2：手动构建

```bash
# 1. 清理缓存
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 构建 Windows 应用
flutter build windows --release

# 4. 创建 MSIX 安装包
dart run msix:create
```

#### 安装包位置

构建完成后，安装包位于：
```
build\windows\x64\runner\Release\myapp_flt_02.msix
```

#### MSIX 包信息

- **应用名称**：文件拖拽应用
- **发布者**：wenbooo
- **版本**：1.0.0.0
- **支持的功能**：
  - 互联网访问
  - 可移动存储访问
  - 广泛的文件系统访问（支持执行 ffmpeg）

#### 安装说明

1. 双击 `.msix` 文件
2. 点击"安装"按钮
3. 等待安装完成
4. 在开始菜单中找到"文件拖拽应用"

#### 分发说明

- ✅ 可以直接分发 `.msix` 文件
- ✅ 用户无需安装 Flutter SDK
- ✅ 用户需要安装 ffmpeg（通过 Chocolatey 或手动）
- ⚠️ 首次安装可能需要启用"开发人员模式"或安装开发者证书

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
