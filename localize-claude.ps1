#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Claude Desktop Windows 一键全自动深度精校汉化脚本
.DESCRIPTION
    自动定位 Claude 路径（支持 WindowsApps 与 AppData 版），赋权注入中文 JSON 与语言白名单。
#>

param(
    [switch]$Restore,
    [string]$CustomAppDir = ""
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Info  { param($msg) Write-Host "[-] $msg" -ForegroundColor Cyan }
function Write-Succ  { param($msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Fail  { param($msg) Write-Host "[X] $msg" -ForegroundColor Red }

# 1. 管理员权限自检与提权
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {
    Write-Warn "检测到需要管理员权限，正在请求提升权限..."
    try {
        $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
        if ($Restore) { $argList += '-Restore' }
        if ($CustomAppDir) { $argList += @('-CustomAppDir', "`"$CustomAppDir`"") }
        Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $argList
        exit 0
    } catch {
        Write-Fail "未能获得管理员权限，请右键选择【以管理员身份运行】！"
        Read-Host "按回车键退出..."
        exit 1
    }
}

# 2. 安全退出正在运行的 Claude 进程（避免文件占用报错）
$claudeProcs = Get-Process -Name claude -ErrorAction SilentlyContinue
if ($claudeProcs) {
    Write-Info "正在关闭正在运行的 Claude 客户端以解除文件占用..."
    $claudeProcs | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$resSourceDir = Join-Path $scriptDir "resources"
$backupBase = Join-Path $env:LOCALAPPDATA "Claude-zh-CN-Backup"
$configDir = Join-Path $env:APPDATA "Claude-3p"
$configPath = Join-Path $configDir "config.json"

# 3. 智能定位 Claude 最新安装路径
function Get-ClaudeAppDir {
    if (-not [string]::IsNullOrWhiteSpace($CustomAppDir) -and (Test-Path $CustomAppDir)) {
        return $CustomAppDir
    }

    # 优先检测 WindowsApps 商店版
    try {
        $appx = Get-AppxPackage -Name Claude -ErrorAction SilentlyContinue |
                Sort-Object Version -Descending | Select-Object -First 1
        if ($appx -and $appx.InstallLocation) {
            $cand = Join-Path $appx.InstallLocation "app"
            if (Test-Path (Join-Path $cand "resources\en-US.json")) { return $cand }
        }
    } catch {}

    $winApps = "C:\Program Files\WindowsApps"
    if (Test-Path $winApps) {
        $dirs = Get-ChildItem $winApps -Directory -Filter "Claude_*_x64__*" -ErrorAction SilentlyContinue |
                Sort-Object Name -Descending
        foreach ($d in $dirs) {
            $cand = Join-Path $d.FullName "app"
            if (Test-Path (Join-Path $cand "resources\en-US.json")) { return $cand }
        }
    }

    # 检测 AppData 独立版
    $localApp = Join-Path $env:LOCALAPPDATA "AnthropicClaude"
    if (Test-Path $localApp) {
        $cand = Join-Path $localApp "app"
        if (Test-Path (Join-Path $cand "resources\en-US.json")) { return $cand }
        if (Test-Path (Join-Path $localApp "resources\en-US.json")) { return $localApp }
    }

    return $null
}

$appDir = Get-ClaudeAppDir
if (-not $appDir) {
    Write-Fail "未找到 Claude Desktop 安装目录！"
    Write-Info "请确认是否已安装 Claude 官方客户端，或使用 -CustomAppDir 参数指定路径。"
    Read-Host "按回车键退出..."
    exit 1
}

$resourcesDir = Join-Path $appDir "resources"
Write-Succ "已定位最新 Claude 资源目录: $resourcesDir"

# 4. WindowsApps 目录权限放通处理
if ($resourcesDir.ToLower().Contains("windowsapps")) {
    Write-Info "正在放通 WindowsApps 资源目录的管理员完全写入权限..."
    try {
        takeown /f "$resourcesDir" /r /d y | Out-Null
        icacls "$resourcesDir" /grant "Administrators:(OI)(CI)F" /t /c /q | Out-Null
        icacls "$resourcesDir" /grant "${env:USERNAME}:(OI)(CI)F" /t /c /q | Out-Null
        Write-Succ "WindowsApps 目录权限配置成功！"
    } catch {
        Write-Warn "权限放通出现部分警告，继续尝试注入..."
    }
}

# 5. 辅助复制函数（带备份与去除只读）
function Copy-FileWithBackup {
    param(
        [string]$SourceFile,
        [string]$TargetFile,
        [string]$RelativePath
    )
    $backupFile = Join-Path $backupBase $RelativePath
    if (-not (Test-Path $backupFile) -and (Test-Path $TargetFile)) {
        $parent = Split-Path -Parent $backupFile
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -Path $TargetFile -Destination $backupFile -Force
    }

    $tDir = Split-Path -Parent $TargetFile
    if (-not (Test-Path $tDir)) { New-Item -ItemType Directory -Path $tDir -Force | Out-Null }

    if (Test-Path $TargetFile) {
        $attr = [System.IO.File]::GetAttributes($TargetFile)
        if ($attr -band [System.IO.FileAttributes]::ReadOnly) {
            [System.IO.File]::SetAttributes($TargetFile, $attr -bxor [System.IO.FileAttributes]::ReadOnly)
        }
    }

    Copy-Item -Path $SourceFile -Destination $TargetFile -Force
}

# 6. 还原模式处理
if ($Restore) {
    Write-Info "正在恢复官方原版文件..."
    if (Test-Path $backupBase) {
        $backupFiles = Get-ChildItem -Path $backupBase -Recurse -File
        foreach ($bf in $backupFiles) {
            $rel = $bf.FullName.Substring($backupBase.Length).TrimStart('\', '/')
            $dest = Join-Path $resourcesDir $rel
            if (Test-Path (Split-Path -Parent $dest)) {
                Copy-Item -Path $bf.FullName -Destination $dest -Force
                Write-Succ "已恢复: $rel"
            }
        }
    }

    $extraZh = @(
        (Join-Path $resourcesDir "zh-CN.json"),
        (Join-Path $resourcesDir "ion-dist\i18n\zh-CN.json"),
        (Join-Path $resourcesDir "ion-dist\i18n\statsig\zh-CN.json")
    )
    foreach ($f in $extraZh) {
        if (Test-Path $f) { Remove-Item -Path $f -Force -ErrorAction SilentlyContinue }
    }

    if (Test-Path $configPath) {
        try {
            $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($cfg.PSObject.Properties['locale']) {
                $cfg.locale = "en-US"
                [System.IO.File]::WriteAllText($configPath, ($cfg | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8)
            }
        } catch {}
    }

    Write-Succ "官方语言还原完成！重新启动 Claude 即可看到原版界面。"
    Read-Host "按回车键退出..."
    exit 0
}

# 7. 开始汉化注入
Write-Info "开始注入中文语言资源包..."

$desktopZh  = Join-Path $resSourceDir "desktop-zh-CN.json"
$frontendZh = Join-Path $resSourceDir "frontend-zh-CN.json"
$statsigZh  = Join-Path $resSourceDir "statsig-zh-CN.json"

if (-not (Test-Path $desktopZh) -or -not (Test-Path $frontendZh)) {
    Write-Fail "汉化源资源文件缺失，请检查 resources 目录！"
    Read-Host "按回车键退出..."
    exit 1
}

# 复制 3 个核心中文 JSON
Copy-FileWithBackup -SourceFile $desktopZh  -TargetFile (Join-Path $resourcesDir "zh-CN.json") -RelativePath "zh-CN.json"
Copy-FileWithBackup -SourceFile $frontendZh -TargetFile (Join-Path $resourcesDir "ion-dist\i18n\zh-CN.json") -RelativePath "ion-dist\i18n\zh-CN.json"
if (Test-Path $statsigZh) {
    Copy-FileWithBackup -SourceFile $statsigZh -TargetFile (Join-Path $resourcesDir "ion-dist\i18n\statsig\zh-CN.json") -RelativePath "ion-dist\i18n\statsig\zh-CN.json"
}
Write-Succ "中文语言 JSON 注入成功！"

# 8. 语言白名单修补 (index-*.js)
$assetsRoot = Join-Path $resourcesDir "ion-dist\assets"
if (Test-Path $assetsRoot) {
    $jsFiles = Get-ChildItem -Path $assetsRoot -Recurse -Filter "*.js" -File
    $patchedCount = 0
    foreach ($js in $jsFiles) {
        $content = [System.IO.File]::ReadAllText($js.FullName, [System.Text.Encoding]::UTF8)
        $needPatch = $false

        # 匹配包含语言代码数组并注入 "zh-CN"
        if ($content -match '(\["en-US"[^\]]*?)(\])' -and -not $content.Contains('"zh-CN"')) {
            $content = $content -replace '(\["en-US"[^\]]*?)(\])', '$1,"zh-CN"$2'
            $needPatch = $true
        }

        if ($needPatch) {
            $rel = $js.FullName.Substring($resourcesDir.Length).TrimStart('\', '/')
            $backupFile = Join-Path $backupBase $rel
            if (-not (Test-Path $backupFile)) {
                $p = Split-Path -Parent $backupFile
                if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
                Copy-Item -Path $js.FullName -Destination $backupFile -Force
            }
            [System.IO.File]::WriteAllText($js.FullName, $content, [System.Text.Encoding]::UTF8)
            $patchedCount++
        }
    }
    Write-Succ "已成功更新 $patchedCount 个模块语言白名单！"
}

# 9. 托盘与启动英文回退标签修补 (resources/en-US.json)
$enUsJson = Join-Path $resourcesDir "en-US.json"
if ((Test-Path $enUsJson) -and (Test-Path $desktopZh)) {
    try {
        $enData = Get-Content $enUsJson -Raw -Encoding UTF8 | ConvertFrom-Json
        $zhData = Get-Content $desktopZh -Raw -Encoding UTF8 | ConvertFrom-Json
        $fallbackKeys = @("7fdcqxofEs", "DQTgg21B7g", "dKX0bpR+a2", "oQuOiX24pp")
        $changed = $false
        foreach ($k in $fallbackKeys) {
            if ($enData.PSObject.Properties[$k] -and $zhData.PSObject.Properties[$k]) {
                $enData.$k = $zhData.$k
                $changed = $true
            }
        }
        if ($changed) {
            [System.IO.File]::WriteAllText($enUsJson, ($enData | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8)
            Write-Succ "托盘与外壳回退文案修补完成！"
        }
    } catch {}
}

# 10. 配置用户语言环境为 zh-CN
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}
$cfgObj = [PSCustomObject]@{}
if (Test-Path $configPath) {
    try {
        $cfgObj = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {}
}
$cfgObj | Add-Member -MemberType NoteProperty -Name "locale" -Value "zh-CN" -Force
[System.IO.File]::WriteAllText($configPath, ($cfgObj | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8)
Write-Succ "已将客户端默认语言配置为: zh-CN"

Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Host "      恭喜！Claude Desktop 中文汉化已成功安装！    " -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""
Write-Info "提示："
Write-Info "  - 现在可以直接启动 Claude 客户端查看中文效果。"
Write-Info "  - 如果界面未刷新，请在 Claude 窗口中按 Ctrl + R。"
Write-Info "  - 原始官方文件已自动安全备份至: $backupBase"
Write-Host ""

Read-Host "按回车键完成并退出..."
