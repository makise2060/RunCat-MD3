# RunCat Flutter 环境配置脚本
# 配置国内镜像源以加速依赖下载

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   RunCat Flutter 环境配置脚本" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# 配置环境变量
Write-Host "[1/4] 正在配置 Flutter 国内镜像..." -ForegroundColor Yellow

try {
    # 用户级别环境变量（不需要管理员权限）
    [Environment]::SetEnvironmentVariable('PUB_HOSTED_URL', 'https://pub.flutter-io.cn', 'User')
    [Environment]::SetEnvironmentVariable('FLUTTER_STORAGE_BASE_URL', 'https://storage.flutter-io.cn', 'User')
    Write-Host "       ✓ 用户级环境变量配置完成" -ForegroundColor Green
    
    # 如果拥有管理员权限，同时配置系统级别
    if ($isAdmin) {
        [Environment]::SetEnvironmentVariable('PUB_HOSTED_URL', 'https://pub.flutter-io.cn', 'Machine')
        [Environment]::SetEnvironmentVariable('FLUTTER_STORAGE_BASE_URL', 'https://storage.flutter-io.cn', 'Machine')
        Write-Host "       ✓ 系统级环境变量配置完成" -ForegroundColor Green
    } else {
        Write-Host "       ℹ  未使用管理员权限，仅配置用户级变量" -ForegroundColor DarkYellow
    }
} catch {
    Write-Host "       ✗ 配置失败: $_" -ForegroundColor Red
    exit 1
}

# 配置当前会话
Write-Host ""
Write-Host "[2/4] 正在配置当前 PowerShell 会话..." -ForegroundColor Yellow
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
Write-Host "       ✓ 当前会话环境变量已设置" -ForegroundColor Green

# 验证配置
Write-Host ""
Write-Host "[3/4] 验证配置..." -ForegroundColor Yellow
$userPub = [Environment]::GetEnvironmentVariable('PUB_HOSTED_URL', 'User')
$userStorage = [Environment]::GetEnvironmentVariable('FLUTTER_STORAGE_BASE_URL', 'User')

Write-Host "       用户级 PUB_HOSTED_URL: $userPub" -ForegroundColor Gray
Write-Host "       用户级 FLUTTER_STORAGE_BASE_URL: $userStorage" -ForegroundColor Gray
Write-Host "       ✓ 配置验证完成" -ForegroundColor Green

# 创建便捷启动脚本
Write-Host ""
Write-Host "[4/4] 创建便捷启动脚本..." -ForegroundColor Yellow

$flutterPath = "D:\Files\GitHub\flutter\bin\flutter.bat"
$projectPath = "D:\Files\GitHub\projects\RunCat-MD3\docs\runcat_flutter"

$launchScript = @"
@echo off
chcp 65001 >nul
echo [RunCat Flutter] 正在启动...
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
cd /d "$projectPath"
echo [RunCat Flutter] 环境已配置，正在运行 Flutter 命令...
echo.
"$flutterPath" %*
"@

$launchScript | Out-File -FilePath "$projectPath\flutter_cn.bat" -Encoding UTF8
Write-Host "       ✓ 创建 flutter_cn.bat 启动脚本" -ForegroundColor Green

# 完成
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   环境配置完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "使用方法:" -ForegroundColor White
Write-Host "   1. 双击运行 flutter_cn.bat" -ForegroundColor Gray
Write-Host "   2. 或在 PowerShell 中运行:" -ForegroundColor Gray
Write-Host "      .\setup_flutter_env.ps1" -ForegroundColor DarkCyan
Write-Host "      flutter doctor" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "常用命令:" -ForegroundColor White
Write-Host "   flutter doctor          - 检查环境" -ForegroundColor Gray
Write-Host "   flutter pub get         - 获取依赖" -ForegroundColor Gray
Write-Host "   flutter run -d windows  - 运行应用" -ForegroundColor Gray
Write-Host ""

if (-not $isAdmin) {
    Write-Host "提示: 以管理员身份运行此脚本可配置系统级环境变量" -ForegroundColor DarkYellow
    Write-Host ""
}