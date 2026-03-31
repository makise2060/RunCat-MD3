# Flutter 完全卸载脚本
# 以管理员权限运行

Write-Host "=== Flutter 完全卸载脚本 ===" -ForegroundColor Yellow
Write-Host ""

# 1. 删除 Flutter SDK
$flutterSdkPath = $env:FLUTTER_HOME
if (-not $flutterSdkPath) {
    # 尝试常见路径
    $possiblePaths = @(
        "C:\flutter",
        "C:\Users\$env:USERNAME\flutter",
        "C:\Users\$env:USERNAME\Documents\flutter",
        "C:\Users\$env:USERNAME\Downloads\flutter",
        "C:\src\flutter",
        "D:\flutter"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path "$path\bin\flutter.bat") {
            $flutterSdkPath = $path
            break
        }
    }
}

if ($flutterSdkPath -and (Test-Path $flutterSdkPath)) {
    Write-Host "找到 Flutter SDK: $flutterSdkPath" -ForegroundColor Cyan
    Write-Host "正在删除 Flutter SDK..." -ForegroundColor Yellow
    Remove-Item -Path $flutterSdkPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Flutter SDK 已删除" -ForegroundColor Green
} else {
    Write-Host "未找到 Flutter SDK 安装目录" -ForegroundColor Gray
}

# 2. 删除 Dart SDK (如果单独安装)
$dartSdkPath = $env:DART_HOME
if (-not $dartSdkPath) {
    $possibleDartPaths = @(
        "C:\dart-sdk",
        "C:\Program Files\Dart",
        "C:\Users\$env:USERNAME\AppData\Local\Pub\Cache\bin"
    )
    
    foreach ($path in $possibleDartPaths) {
        if (Test-Path $path) {
            $dartSdkPath = $path
            break
        }
    }
}

if ($dartSdkPath -and (Test-Path $dartSdkPath)) {
    Write-Host "找到 Dart SDK: $dartSdkPath" -ForegroundColor Cyan
    Write-Host "正在删除 Dart SDK..." -ForegroundColor Yellow
    Remove-Item -Path $dartSdkPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Dart SDK 已删除" -ForegroundColor Green
}

# 3. 删除 Flutter 缓存目录
$flutterCachePaths = @(
    "$env:LOCALAPPDATA\Pub\Cache",
    "$env:APPDATA\Pub\Cache",
    "$env:USERPROFILE\.pub-cache",
    "$env:USERPROFILE\.flutter",
    "$env:TEMP\flutter*",
    "$env:LOCALAPPDATA\flutter"
)

Write-Host ""
Write-Host "正在删除 Flutter 缓存..." -ForegroundColor Yellow
foreach ($path in $flutterCachePaths) {
    if (Test-Path $path) {
        Write-Host "  删除: $path" -ForegroundColor Gray
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "✓ Flutter 缓存已清理" -ForegroundColor Green

# 4. 删除 Android Studio / IntelliJ 的 Flutter 相关缓存
$ideCachePaths = @(
    "$env:USERPROFILE\.AndroidStudio*\system\caches",
    "$env:USERPROFILE\.AndroidStudio*\system\log",
    "$env:USERPROFILE\.AndroidStudio*\system\tmp",
    "$env:USERPROFILE\.IntelliJIdea*\system\caches",
    "$env:USERPROFILE\.AndroidStudio*\config\options\flutter*"
)

Write-Host ""
Write-Host "正在清理 IDE 缓存..." -ForegroundColor Yellow
foreach ($path in $ideCachePaths) {
    $expandedPath = [Environment]::ExpandEnvironmentVariables($path)
    $matchingPaths = Get-Item -Path $expandedPath -ErrorAction SilentlyContinue
    foreach ($matched in $matchingPaths) {
        if (Test-Path $matched) {
            Write-Host "  删除: $matched" -ForegroundColor Gray
            Remove-Item -Path $matched -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
Write-Host "✓ IDE 缓存已清理" -ForegroundColor Green

# 5. 删除项目构建缓存
Write-Host ""
Write-Host "正在删除项目构建缓存..." -ForegroundColor Yellow
$projectPaths = @(
    "d:\Files\GitHub\projects\RunCat-MD3\docs\runcat_flutter\build",
    "d:\Files\GitHub\projects\RunCat-MD3\docs\runcat_flutter\.dart_tool",
    "d:\Files\GitHub\projects\RunCat-MD3\docs\runcat_flutter\.flutter-plugins*"
)

foreach ($path in $projectPaths) {
    if (Test-Path $path) {
        Write-Host "  删除: $path" -ForegroundColor Gray
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "✓ 项目构建缓存已清理" -ForegroundColor Green

# 6. 从环境变量中移除 Flutter
Write-Host ""
Write-Host "正在清理环境变量..." -ForegroundColor Yellow

# 获取当前用户 PATH
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$originalUserPath = $userPath

# 移除 Flutter 相关路径
$pathsToRemove = @(
    "flutter\bin",
    "flutter\bin\cache\dart-sdk\bin",
    "dart-sdk\bin",
    "Pub\Cache\bin"
)

foreach ($remove in $pathsToRemove) {
    $userPath = $userPath -replace [regex]::Escape($remove) + ";?", ""
    $userPath = $userPath -replace ";;", ";"
}

if ($userPath -ne $originalUserPath) {
    [Environment]::SetEnvironmentVariable("PATH", $userPath, "User")
    Write-Host "✓ 用户 PATH 已更新" -ForegroundColor Green
}

# 删除 FLUTTER_HOME 环境变量
[Environment]::SetEnvironmentVariable("FLUTTER_HOME", $null, "User")
[Environment]::SetEnvironmentVariable("FLUTTER_ROOT", $null, "User")
[Environment]::SetEnvironmentVariable("DART_HOME", $null, "User")
Write-Host "✓ Flutter 环境变量已删除" -ForegroundColor Green

# 7. 删除 VS Code 的 Flutter 扩展缓存（如果使用 VS Code）
$vscodeFlutterPath = "$env:USERPROFILE\.vscode\extensions\dart-code.flutter-*"
if (Test-Path $vscodeFlutterPath) {
    Write-Host ""
    Write-Host "找到 VS Code Flutter 扩展" -ForegroundColor Cyan
    # 保留扩展但清理缓存
    $vscodeCache = "$env:APPDATA\Code\Cache"
    if (Test-Path $vscodeCache) {
        Remove-Item -Path "$vscodeCache\*flutter*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✓ VS Code 缓存已清理" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== 卸载完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "以下操作需要手动完成:" -ForegroundColor Yellow
Write-Host "1. 从系统环境变量 PATH 中手动检查并删除 Flutter 路径（如果还有）" -ForegroundColor White
Write-Host "2. 重启终端或 IDE 以应用环境变量更改" -ForegroundColor White
Write-Host "3. 如需完全重新安装，请从 https://flutter.dev 下载最新版本" -ForegroundColor White
Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
