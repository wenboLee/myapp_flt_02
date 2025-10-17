# Windows 安装包构建指南

## 前提条件

### 必需的工具

1. **Flutter SDK**
   - 版本：3.9.2 或更高
   - 下载：https://flutter.dev/docs/get-started/install

2. **Visual Studio 2022**
   - 需要 "Desktop development with C++" 工作负载
   - 下载：https://visualstudio.microsoft.com/

3. **Git**
   - 用于版本控制
   - 下载：https://git-scm.com/

### 可选工具

1. **Windows SDK**
   - 通常随 Visual Studio 一起安装
   - 用于创建 MSIX 包

## 快速开始

### 使用自动化脚本（最简单）

1. 打开项目目录
2. 双击运行 `build_windows_installer.bat`
3. 等待构建完成
4. 在 `build\windows\x64\runner\Release\` 目录找到 `myapp_flt_02.msix`

### 使用 PowerShell（推荐）

```powershell
# 右键点击 build_windows_installer.ps1
# 选择 "使用 PowerShell 运行"
```

## 手动构建步骤

如果需要更多控制，可以手动执行以下步骤：

### 1. 清理项目

```bash
flutter clean
```

### 2. 获取依赖

```bash
flutter pub get
```

### 3. 构建 Windows 应用

```bash
flutter build windows --release
```

### 4. 创建 MSIX 安装包

```bash
dart run msix:create
```

## 输出文件

### MSIX 安装包

**位置：**
```
build\windows\x64\runner\Release\myapp_flt_02.msix
```

**文件大小：** 约 20-30 MB

**包含内容：**
- 应用可执行文件
- Flutter 引擎
- 所有依赖的 DLL 文件
- 应用资源和图标

### 便携版（无需安装）

如果不需要安装包，可以直接使用：

**位置：**
```
build\windows\x64\runner\Release\
```

**使用方法：**
1. 复制整个 Release 文件夹
2. 双击 `myapp_flt_02.exe` 运行

## 测试安装包

### 在本地测试

1. 双击 `myapp_flt_02.msix`
2. 点击"安装"按钮
3. 在开始菜单中找到"文件拖拽应用"
4. 运行并测试所有功能

### 卸载应用

1. 打开"设置" -> "应用" -> "已安装的应用"
2. 找到"文件拖拽应用"
3. 点击"卸载"

## 分发安装包

### 方法 1：直接分发 MSIX

**优点：**
- ✅ 文件小，单个文件
- ✅ 安装简单
- ✅ 自动更新支持

**缺点：**
- ⚠️ 需要开发者模式或签名证书
- ⚠️ Windows 10/11 专用

### 方法 2：分发便携版

**优点：**
- ✅ 无需安装
- ✅ 兼容性好
- ✅ 无需特殊权限

**缺点：**
- ❌ 文件夹较大
- ❌ 需要手动更新

## 签名证书（可选）

如果需要对 MSIX 进行签名以避免安全警告：

### 创建自签名证书

```powershell
# 在管理员 PowerShell 中运行
$cert = New-SelfSignedCertificate -Type CodeSigning -Subject "CN=wenbooo" -KeyUsage DigitalSignature -FriendlyName "Flutter App Signing" -CertStoreLocation "Cert:\CurrentUser\My"
```

### 配置 pubspec.yaml

在 `msix_config` 中添加：

```yaml
msix_config:
  certificate_path: path/to/certificate.pfx
  certificate_password: your_password
```

## 常见问题

### Q: 构建失败，提示找不到 Visual Studio

**A:** 确保已安装 Visual Studio 2022 并包含 "Desktop development with C++" 工作负载。

### Q: MSIX 创建失败

**A:** 
1. 检查 Windows SDK 是否已安装
2. 确保 `pubspec.yaml` 中的 MSIX 配置正确
3. 尝试使用管理员权限运行构建脚本

### Q: 安装时提示不受信任

**A:** 
1. 启用 Windows 开发者模式
2. 或者为 MSIX 添加签名证书

### Q: 应用启动后无法执行 ffmpeg

**A:** 
1. 确保用户已安装 ffmpeg
2. 检查 ffmpeg 是否在 PATH 环境变量中
3. 尝试重启应用或系统

## 高级配置

### 修改应用图标

1. 准备图标文件（.ico 格式）
2. 替换 `windows\runner\resources\app_icon.ico`
3. 重新构建

### 修改应用版本

编辑 `pubspec.yaml`：

```yaml
version: 1.0.1+2  # 版本号+构建号

msix_config:
  msix_version: 1.0.1.0  # MSIX 版本
```

### 添加应用功能

编辑 `pubspec.yaml` 中的 `capabilities`：

```yaml
msix_config:
  capabilities: 'internetClient,removableStorage,broadFileSystemAccess,webcam,microphone'
```

## 发布到 Microsoft Store（可选）

如果想要发布到 Microsoft Store：

1. 注册 Microsoft 开发者账号
2. 创建应用提交
3. 使用 Store 提供的证书签名
4. 提交审核

## 联系方式

如有问题，请提交 Issue：
https://github.com/wenboLee/myapp_flt_02/issues

