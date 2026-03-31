@echo off
chcp 65001 >nul
echo 正在运行纯托盘版本 RunCat Flutter...
cd /d "%~dp0"
flutter run -d windows --target lib/main_tray_only.dart
pause
