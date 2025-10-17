# macOS 安装包构建指南

## 前提条件

### 必需的工具

1. **Flutter SDK**
   - 版本：3.9.2 或更高
   - 下载：https://flutter.dev/docs/get-started/install

2. **Xcode**
   - 版本：14.0 或更高
   - 从 Mac App Store 安装

3. **Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

### 可选工具（用于 DMG）

1. **Homebrew**
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **create-dmg**
   ```bash
   brew install create-dmg
   ```

## 快速开始

### 方法 1：创建 DMG 安装包（推荐）

```bash
# 在项目根目录下运行
./build_macos_dmg.sh
```

**特点：**
- ✅ 自动化构建流程
- ✅ 创建专业的 DMG 安装包
- ✅ 包含拖拽安装界面
- ✅ 自动检测并安装 create-dmg

### 方法 2：快速构建 .app

```bash
# 在项目根目录下运行
./build_macos_simple.sh
```

**特点：**
- ✅ 快速构建
- ✅ 无需额外工具
- ✅ 直接生成可运行的 .app

## 手动构建步骤

### 1. 清理项目

```bash
flutter clean
```

### 2. 获取依赖

```bash
flutter pub get
```

### 3. 构建 macOS 应用

```bash
flutter build macos --release
```

### 4. 创建 DMG（可选）

#### 使用 create-dmg

```bash
# 安装 create-dmg
brew install create-dmg

# 创建 DMG
create-dmg \
  --volname "文件拖拽应用" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "myapp_flt_02.app" 150 185 \
  --hide-extension "myapp_flt_02.app" \
  --app-drop-link 450 185 \
  "myapp_flt_02.dmg" \
  "build/macos/Build/Products/Release/myapp_flt_02.app"
```

#### 使用 hdiutil（系统自带）

```bash
# 创建临时目录
mkdir -p dmg_temp
cp -R build/macos/Build/Products/Release/myapp_flt_02.app dmg_temp/
ln -s /Applications dmg_temp/Applications

# 创建 DMG
hdiutil create -volname "文件拖拽应用" \
  -srcfolder dmg_temp \
  -ov -format UDZO \
  myapp_flt_02.dmg

# 清理
rm -rf dmg_temp
```

## 输出文件

### DMG 安装包

**位置：**
```
build/macos/myapp_flt_02_1.0.0.dmg
```

**文件大小：** 约 30-50 MB

**包含内容：**
- myapp_flt_02.app
- Applications 文件夹快捷方式
- 自定义背景和图标布局

### .app 应用包

**位置：**
```
build/macos/Build/Products/Release/myapp_flt_02.app
```

**文件大小：** 约 40-60 MB

**包含内容：**
- 应用可执行文件
- Flutter 引擎
- 所有依赖的动态库
- 应用资源和图标

## 测试安装包

### 测试 DMG

1. **挂载 DMG**
   ```bash
   open build/macos/myapp_flt_02_1.0.0.dmg
   ```

2. **拖拽安装**
   - 将应用图标拖拽到 Applications 文件夹

3. **运行应用**
   - 从启动台或 Finder 中打开应用

4. **首次运行处理**
   - 如果系统提示"无法验证开发者"，请前往：
   - 系统偏好设置 > 安全性与隐私 > 通用
   - 点击"仍然打开"

### 测试 .app

```bash
# 直接运行
open build/macos/Build/Products/Release/myapp_flt_02.app

# 或安装到 Applications
cp -R build/macos/Build/Products/Release/myapp_flt_02.app /Applications/
```

## 代码签名（可选）

### 为什么需要签名？

- ✅ 避免"无法验证开发者"警告
- ✅ 通过 Gatekeeper 验证
- ✅ 提升用户信任度

### 申请开发者证书

1. 加入 Apple Developer Program（$99/年）
2. 在 Xcode 中登录 Apple ID
3. Xcode > Preferences > Accounts
4. 下载开发者证书

### 签名应用

```bash
# 查看可用证书
security find-identity -v -p codesigning

# 签名应用
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name" \
  build/macos/Build/Products/Release/myapp_flt_02.app

# 验证签名
codesign --verify --verbose \
  build/macos/Build/Products/Release/myapp_flt_02.app

# 检查签名信息
codesign -dvv \
  build/macos/Build/Products/Release/myapp_flt_02.app
```

### 公证（Notarization）

对于 macOS 10.15+ 的分发，建议进行公证：

```bash
# 创建应用包
ditto -c -k --keepParent \
  build/macos/Build/Products/Release/myapp_flt_02.app \
  myapp_flt_02.zip

# 提交公证
xcrun notarytool submit myapp_flt_02.zip \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

# 装订公证票据
xcrun stapler staple \
  build/macos/Build/Products/Release/myapp_flt_02.app
```

## 分发选项

### 选项 1：DMG 安装包

**优点：**
- ✅ 专业、用户友好
- ✅ 标准的 macOS 安装方式
- ✅ 包含拖拽安装界面

**适用场景：**
- 正式发布
- 给非技术用户
- 需要品牌展示

### 选项 2：.app 压缩包

**优点：**
- ✅ 文件更小
- ✅ 构建简单
- ✅ 可以通过网盘分发

**适用场景：**
- 开发测试
- 内部分发
- 技术用户

```bash
# 创建压缩包
cd build/macos/Build/Products/Release/
zip -r myapp_flt_02.zip myapp_flt_02.app
```

### 选项 3：通过 GitHub Releases

1. 构建 DMG 或 .app.zip
2. 创建 GitHub Release
3. 上传构建产物
4. 添加版本说明

## 应用信息配置

### 修改应用名称

编辑 `macos/Runner/Configs/AppInfo.xcconfig`：

```
PRODUCT_NAME = 文件拖拽应用
PRODUCT_BUNDLE_IDENTIFIER = cn.wenbooo.myappflt02
```

### 修改版本号

编辑 `pubspec.yaml`：

```yaml
version: 1.0.1+2  # 版本号+构建号
```

### 更换应用图标

1. 准备图标（.icns 格式）
2. 替换 `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png`
3. 或直接替换 .icns 文件

## 常见问题

### Q: 构建失败，提示 "No provisioning profile"

**A:** 这是正常的，macOS 桌面应用不需要配置文件。如果仍然失败，检查 Xcode 配置。

### Q: 应用无法打开，提示"已损坏"

**A:** 这是因为应用未签名。解决方法：
```bash
# 移除隔离属性
xattr -cr /Applications/myapp_flt_02.app
```

### Q: 如何减小应用大小？

**A:** 
1. 使用 Release 模式构建
2. 移除未使用的资源
3. 考虑使用代码混淆

### Q: 如何添加启动参数？

**A:** 编辑 `macos/Runner/Info.plist`，添加所需的配置。

### Q: 如何支持暗黑模式？

**A:** Flutter 自动支持，确保使用 Theme.of(context) 获取颜色。

## 卸载应用

### 手动卸载

```bash
# 删除应用
rm -rf /Applications/myapp_flt_02.app

# 删除用户数据（如果有）
rm -rf ~/Library/Application\ Support/cn.wenbooo.myappflt02
rm -rf ~/Library/Caches/cn.wenbooo.myappflt02
rm -rf ~/Library/Preferences/cn.wenbooo.myappflt02.plist
```

## 高级配置

### 自定义 DMG 背景

1. 创建背景图片（1000x600 像素）
2. 使用 create-dmg 的 `--background` 参数

```bash
create-dmg \
  --background "assets/dmg_background.png" \
  ...
```

### 添加许可协议

```bash
create-dmg \
  --eula "LICENSE.txt" \
  ...
```

### 自定义窗口外观

```bash
create-dmg \
  --window-pos 200 120 \
  --window-size 800 600 \
  --text-size 12 \
  ...
```

## 持续集成

### GitHub Actions 示例

```yaml
name: Build macOS App

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      - run: flutter pub get
      - run: flutter build macos --release
      - run: brew install create-dmg
      - run: ./build_macos_dmg.sh
      - uses: actions/upload-artifact@v3
        with:
          name: macos-dmg
          path: build/macos/*.dmg
```

## 联系方式

如有问题，请提交 Issue：
https://github.com/wenboLee/myapp_flt_02/issues

