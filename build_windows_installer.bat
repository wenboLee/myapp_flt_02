@echo off
echo ========================================
echo 构建 Windows 安装包
echo ========================================
echo.

echo [1/4] 清理构建缓存...
call flutter clean
if %errorlevel% neq 0 goto error

echo.
echo [2/4] 获取依赖...
call flutter pub get
if %errorlevel% neq 0 goto error

echo.
echo [3/4] 构建 Windows 应用...
call flutter build windows --release
if %errorlevel% neq 0 goto error

echo.
echo [4/4] 创建 MSIX 安装包...
call dart run msix:create
if %errorlevel% neq 0 goto error

echo.
echo ========================================
echo 构建完成！
echo ========================================
echo.
echo 安装包位置: build\windows\x64\runner\Release\myapp_flt_02.msix
echo.
echo 你可以：
echo 1. 双击安装包进行安装
echo 2. 右键点击 "应用信息" 查看详情
echo 3. 分发给其他 Windows 用户使用
echo.
pause
goto end

:error
echo.
echo ========================================
echo 构建失败！
echo ========================================
echo.
pause
exit /b 1

:end

