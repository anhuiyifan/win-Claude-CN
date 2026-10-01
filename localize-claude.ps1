<#
.SYNOPSIS
    Claude Desktop Windows 一键完全中文汉化与还原脚本
.DESCRIPTION
    自动探测 Claude 桌面端路径（支持 WindowsApps 商店版及 AppData 本地版）
    执行管理员自动提权、资源注入、语言白名单修补、硬编码文本替换与配置更新。
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

# 1. 检查管理员权限并自动提权
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {
    Write-Warn "检测到需要管理员权限以修改 WindowsApps 资源，正在申请管理员权限..."
    try {
        $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
        if ($Restore) { $argList += '-Restore' }
        if ($CustomAppDir) { $argList += @('-CustomAppDir', "`"$CustomAppDir`"") }
        Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $argList
        exit 0
    } catch {
        Write-Fail "未能获得管理员权限，请右键选择【以管理员身份运行】后重试！"
        Read-Host "按回车键退出..."
        exit 1
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$resSourceDir = Join-Path $scriptDir "resources"
$backupBase = Join-Path $env:LOCALAPPDATA "Claude-zh-CN-Backup"
$configDir = Join-Path $env:APPDATA "Claude-3p"
$configPath = Join-Path $configDir "config.json"

# 2. 定位 Claude 安装路径
function Get-ClaudeAppDir {
    if (-not [string]::IsNullOrWhiteSpace($CustomAppDir) -and (Test-Path $CustomAppDir)) {
        return $CustomAppDir
    }

    # 尝试读取运行中的进程
    $proc = Get-Process -Name claude -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($proc -and $proc.Path) {
        $pDir = Split-Path -Parent $proc.Path
        $cand = Join-Path $pDir "app"
        if (Test-Path (Join-Path $cand "resources\en-US.json")) { return $cand }
        if (Test-Path (Join-Path $pDir "resources\en-US.json")) { return $pDir }
    }

    # 探测 WindowsApps 商店版
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

    # 探测 AppData 独立版
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
    Write-Info "请确认是否已安装 Claude 官方客户端，或传入 -CustomAppDir 参数指定路径。"
    Read-Host "按回车键退出..."
    exit 1
}

$resourcesDir = Join-Path $appDir "resources"
Write-Succ "已定位 Claude 资源目录: $resourcesDir"

# 3. 辅助安全写文件（处理 WindowsApps 只读和权限问题）
function Save-FileWithBackup {
    param(
        [string]$TargetFile,
        [string]$Content,
        [string]$RelativePath
    )
    $backupFile = Join-Path $backupBase $RelativePath
    if (-not (Test-Path $backupFile) -and (Test-Path $TargetFile)) {
        $parent = Split-Path -Parent $backupFile
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -Path $TargetFile -Destination $backupFile -Force
    }

    # 去除只读属性
    if (Test-Path $TargetFile) {
        $attr = [System.IO.File]::GetAttributes($TargetFile)
        if ($attr -band [System.IO.FileAttributes]::ReadOnly) {
            [System.IO.File]::SetAttributes($TargetFile, $attr -bxor [System.IO.FileAttributes]::ReadOnly)
        }
    }

    [System.IO.File]::WriteAllText($TargetFile, $Content, [System.Text.Encoding]::UTF8)
}

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

# 4. 执行还原流程
if ($Restore) {
    Write-Info "正在关闭 Claude 进程..."
    Get-Process -Name claude -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    Write-Info "正在从备份恢复原始文件..."
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

    # 删除生成的 zh-CN 文件
    $extraZh = @(
        (Join-Path $resourcesDir "zh-CN.json"),
        (Join-Path $resourcesDir "ion-dist\i18n\zh-CN.json"),
        (Join-Path $resourcesDir "ion-dist\i18n\statsig\zh-CN.json")
    )
    foreach ($f in $extraZh) {
        if (Test-Path $f) { Remove-Item -Path $f -Force -ErrorAction SilentlyContinue }
    }

    # 重置 config.json 中的 locale
    if (Test-Path $configPath) {
        try {
            $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($cfg.PSObject.Properties['locale']) {
                $cfg.locale = "en-US"
                [System.IO.File]::WriteAllText($configPath, ($cfg | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8)
            }
        } catch {}
    }

    Write-Succ "Claude 官方原版文件还原完成！"
    Read-Host "按回车键退出..."
    exit 0
}

# 5. 执行汉化安装流程
Write-Host "=================================================" -ForegroundColor Magenta
Write-Host "         Claude 桌面端一键完全汉化开始           " -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Magenta

Write-Info "1. 正在关闭运行中的 Claude 客户端..."
Get-Process -Name claude -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# 写入多语言 JSON
Write-Info "2. 正在写入中文语言包 (zh-CN.json)..."
$desktopZh = Join-Path $resSourceDir "desktop-zh-CN.json"
$frontendZh = Join-Path $resSourceDir "frontend-zh-CN.json"
$statsigZh = Join-Path $resSourceDir "statsig-zh-CN.json"

if (-not (Test-Path $desktopZh) -or -not (Test-Path $frontendZh)) {
    Write-Fail "缺少 resources 目录或汉化 JSON 文件！请确保脚本同级目录下存在 resources 目录。"
    Read-Host "按回车键退出..."
    exit 1
}

Copy-FileWithBackup -SourceFile $desktopZh -TargetFile (Join-Path $resourcesDir "zh-CN.json") -RelativePath "zh-CN.json"
Copy-FileWithBackup -SourceFile $frontendZh -TargetFile (Join-Path $resourcesDir "ion-dist\i18n\zh-CN.json") -RelativePath "ion-dist\i18n\zh-CN.json"
if (Test-Path $statsigZh) {
    Copy-FileWithBackup -SourceFile $statsigZh -TargetFile (Join-Path $resourcesDir "ion-dist\i18n\statsig\zh-CN.json") -RelativePath "ion-dist\i18n\statsig\zh-CN.json"
}
Write-Succ "语言包 JSON 写入成功！"

# 修补 JS 语言白名单与 Chunk
Write-Info "3. 正在修补前端 JS Chunk 中的语言白名单及硬编码..."
$assetsRoot = Join-Path $resourcesDir "ion-dist\assets"
if (Test-Path $assetsRoot) {
    $jsFiles = Get-ChildItem -Path $assetsRoot -Filter "*.js" -Recurse -File

    foreach ($js in $jsFiles) {
        $content = [System.IO.File]::ReadAllText($js.FullName, [System.Text.Encoding]::UTF8)
        $modified = $false
        $rel = $js.FullName.Substring($resourcesDir.Length).TrimStart('\', '/')

        # (a) 修补语言白名单：如果包含 ["en-US", ...] 则向数组末尾增加 ,"zh-CN"
        $regexWhitelist = '\[\s*"en-US"\s*,\s*"[a-zA-Z]{2,3}(?:-[a-zA-Z0-9]{2,4})*"(?:\s*,\s*"[a-zA-Z]{2,3}(?:-[a-zA-Z0-9]{2,4})*")+\s*\]'
        $matches = [regex]::Matches($content, $regexWhitelist)
        foreach ($match in $matches) {
            $arrStr = $match.Value
            if ($arrStr -notmatch '"zh-CN"') {
                $lastBracket = $arrStr.LastIndexOf(']')
                $newArrStr = $arrStr.Substring(0, $lastBracket) + ',"zh-CN"' + $arrStr.Substring($lastBracket)
                $content = $content.Replace($arrStr, $newArrStr)
                $modified = $true
                Write-Succ "已在 $($js.Name) 中激活 zh-CN 语言白名单"
            }
        }

        # (b) 替换调试工具及硬编码菜单
        $hardcodedMap = @{
            '"Enable Main Process Debugger"'     = '"启用主进程调试器"'
            '"Record Performance Trace"'          = '"记录性能跟踪"'
            '"Write Main Process Heap Snapshot"' = '"写入主进程堆快照"'
            '"Record Memory Trace (auto-stop)"'  = '"记录内存跟踪（自动停止）"'
        }
        foreach ($k in $hardcodedMap.Keys) {
            if ($content.Contains($k)) {
                $content = $content.Replace($k, $hardcodedMap[$k])
                $modified = $true
            }
        }

        if ($modified) {
            Save-FileWithBackup -TargetFile $js.FullName -Content $content -RelativePath $rel
        }
    }
}

# 注入中文字体及 CSS 优化
Write-Info "4. 注入 Windows 优化中文字体支持..."
$indexHtml = Join-Path $resourcesDir "ion-dist\index.html"
if (Test-Path $indexHtml) {
    $htmlContent = [System.IO.File]::ReadAllText($indexHtml, [System.Text.Encoding]::UTF8)
    $fontStyle = '<style id="claude-zh-cn-font-style">body, button, input, select, textarea, [class*="font-"] { font-family: "Microsoft YaHei UI", "Microsoft YaHei", "Segoe UI", -apple-system, sans-serif !important; }</style>'
    if ($htmlContent -notmatch 'claude-zh-cn-font-style') {
        $htmlContent = $htmlContent.Replace('</head>', "$fontStyle</head>")
        Save-FileWithBackup -TargetFile $indexHtml -Content $htmlContent -RelativePath "ion-dist\index.html"
        Write-Succ "已为 index.html 注入中文字体样式！"
    }
}

# 5. 配置用户配置 locale
Write-Info "5. 正在配置本地语言配置文件为 zh-CN..."
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}
$cfgObj = [PSCustomObject]@{}
if (Test-Path $configPath) {
    try {
        $cfgObj = Get-Content $configPath -Raw | ConvertFrom-Json
    } catch {}
}
$cfgObj | Add-Member -MemberType NoteProperty -Name "locale" -Value "zh-CN" -Force
[System.IO.File]::WriteAllText($configPath, ($cfgObj | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8)
Write-Succ "已更新本地配置文件: $configPath"

Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Host "      恭喜！Claude 桌面端已完全修改为中文！      " -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""
Write-Info "提示："
Write-Info "  - 现在您可以直接重新启动 Claude 客户端查看中文效果。"
Write-Info "  - 原始官方文件已自动备份至: $backupBase"
Write-Info "  - 若后续需还原官方原版，只需以 -Restore 参数运行此脚本即可。"
Write-Host ""

Read-Host "按回车键完成并退出..."
