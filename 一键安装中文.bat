@echo off
title Claude Desktop 中文汉化安装器
chcp 65001 >nul 2>&1

:: 管理员权限检测与自动提权
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] 正在请求管理员权限以修改 WindowsApps 资源...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0localize-claude.ps1"
