# Windows 安装包构建脚本
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "构建 Windows 安装包" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 清理构建缓存
Write-Host "[1/4] 清理构建缓存..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "清理失败！" -ForegroundColor Red
    exit 1
}

# 2. 获取依赖
Write-Host ""
Write-Host "[2/4] 获取依赖..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "获取依赖失败！" -ForegroundColor Red
    exit 1
}

# 3. 构建 Windows 应用
Write-Host ""
Write-Host "[3/4] 构建 Windows 应用..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "构建应用失败！" -ForegroundColor Red
    exit 1
}

# 4. 创建 MSIX 安装包
Write-Host ""
Write-Host "[4/4] 创建 MSIX 安装包..." -ForegroundColor Yellow
dart run msix:create
if ($LASTEXITCODE -ne 0) {
    Write-Host "创建安装包失败！" -ForegroundColor Red
    exit 1
}

# 构建成功
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "构建完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "安装包位置: build\windows\x64\runner\Release\myapp_flt_02.msix" -ForegroundColor White
Write-Host ""
Write-Host "你可以：" -ForegroundColor White
Write-Host "1. 双击安装包进行安装" -ForegroundColor White
Write-Host "2. 右键点击 '应用信息' 查看详情" -ForegroundColor White
Write-Host "3. 分发给其他 Windows 用户使用" -ForegroundColor White
Write-Host ""

# 询问是否打开文件夹
$response = Read-Host "是否打开安装包所在文件夹？(Y/N)"
if ($response -eq 'Y' -or $response -eq 'y') {
    explorer "build\windows\x64\runner\Release"
}

