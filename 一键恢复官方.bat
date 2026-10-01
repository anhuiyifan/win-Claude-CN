@echo off
title Claude Desktop 官方语言还原器
chcp 65001 >nul 2>&1

:: 请求管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] 正在请求管理员权限...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
echo [-] 正在恢复 Claude Desktop 官方原版语言资源...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore-windowsapps-zh-cn.ps1"

echo.
echo ========================================================
echo   已恢复官方原版文件！如已打开 Claude 请重启客户端
echo ========================================================
echo.
pause
