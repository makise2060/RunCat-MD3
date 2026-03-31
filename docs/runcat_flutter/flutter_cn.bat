@echo off
chcp 65001 >nul
echo [RunCat Flutter] 正在启动...
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
cd /d "D:\Files\GitHub\projects\RunCat-MD3\docs\runcat_flutter"
echo [RunCat Flutter] 环境已配置，正在运行 Flutter 命令...
echo.
"D:\Files\GitHub\flutter\bin\flutter.bat" %*
