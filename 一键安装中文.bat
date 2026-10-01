@echo off
title Claude Desktop 中文汉化安装器
chcp 65001 >nul 2>&1

:: 请求管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] 正在请求管理员权限以修改 WindowsApps 资源...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
echo [-] 开始安装 Claude Desktop 中文汉化补丁...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0localize-claude.ps1"

echo.
echo ========================================================
echo   操作已完成！如已打开 Claude 请按 Ctrl+R 刷新界面查看效果
echo ========================================================
echo.
pause
