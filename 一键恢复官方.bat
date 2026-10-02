@echo off
title Claude Desktop 官方语言还原器
chcp 65001 >nul 2>&1

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] 正在请求管理员权限...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore-windowsapps-zh-cn.ps1"
