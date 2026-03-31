@echo off
chcp 65001 >nul
echo ==========================================
echo   RunCat Flutter 环境配置脚本
echo ==========================================
echo.

:: 设置 Flutter 国内镜像
echo [1/3] 正在配置 Flutter 国内镜像...
setx PUB_HOSTED_URL "https://pub.flutter-io.cn" >nul 2>&1
setx FLUTTER_STORAGE_BASE_URL "https://storage.flutter-io.cn" >nul 2>&1
echo       ✓ 镜像配置完成

echo.
echo [2/3] 正在配置当前会话环境变量...
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
echo       ✓ 会话环境变量已设置

echo.
echo [3/3] 验证配置...
echo       PUB_HOSTED_URL=%PUB_HOSTED_URL%
echo       FLUTTER_STORAGE_BASE_URL=%FLUTTER_STORAGE_BASE_URL%
echo       ✓ 配置验证完成

echo.
echo ==========================================
echo   环境配置完成！
echo ==========================================
echo.
echo 现在可以运行以下命令：
echo   flutter doctor          - 检查 Flutter 环境
echo   flutter pub get         - 获取项目依赖
echo   flutter run -d windows  - 运行 Windows 应用
echo.
pause