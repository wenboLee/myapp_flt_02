在 Windows 机器上运行 build_windows_installer.bat

   gh release upload v1.0.0 build/windows/x64/runner/Release/myapp_flt_02.msix

# 编辑 Release 说明
gh release edit v1.0.0

# 添加更多文件
gh release upload v1.0.0 <file-path>

# 删除文件
gh release delete-asset v1.0.0 <asset-name>