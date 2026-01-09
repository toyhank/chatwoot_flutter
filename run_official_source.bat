@echo off
REM 清除 Flutter 中国镜像源环境变量并运行应用
REM 此脚本确保使用 Flutter 官方源

echo ========================================
echo   清除镜像源配置并运行 Flutter 应用
echo ========================================
echo.

REM 清除当前会话的环境变量
set PUB_HOSTED_URL=
set FLUTTER_STORAGE_BASE_URL=

echo ✅ 已清除镜像源环境变量
echo.
echo 开始运行 Flutter 应用...
echo.

REM 运行 Flutter 应用
flutter run --dart-define=ENV=development

pause
