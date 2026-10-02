#Requires -RunAsAdministrator
param(
    [string]$CustomAppDir = ""
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$localizeScript = Join-Path $scriptDir "localize-claude.ps1"

if (Test-Path $localizeScript) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$localizeScript`"", '-Restore')
    if ($CustomAppDir) { $argList += @('-CustomAppDir', "`"$CustomAppDir`"") }
    & powershell.exe @argList
} else {
    Write-Host "未找到主恢复脚本: $localizeScript" -ForegroundColor Red
    Read-Host "按回车键退出..."
}
