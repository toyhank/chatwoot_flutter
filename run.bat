@echo off
chcp 65001 >nul
echo ========================================
echo   Flutter 项目运行脚本
echo ========================================
echo.

echo [1/3] 检查 Flutter 环境...
flutter --version
if %errorlevel% neq 0 (
    echo.
    echo ❌ Flutter 未安装或未配置环境变量！
    echo 请先安装 Flutter SDK 并配置环境变量。
    echo.
    pause
    exit /b 1
)

echo.
echo [2/3] 安装依赖...
flutter pub get
if %errorlevel% neq 0 (
    echo.
    echo ❌ 依赖安装失败！
    pause
    exit /b 1
)

echo.
echo [3/3] 选择运行平台:
echo   1. Chrome (Web)
echo   2. Android 模拟器
echo   3. 查看所有设备
echo   4. 仅安装依赖（不运行）
echo.
set /p choice="请选择 (1-4): "

if "%choice%"=="1" (
    echo.
    echo 🚀 在 Chrome 中运行...
    flutter run -d chrome
) else if "%choice%"=="2" (
    echo.
    echo 🚀 在 Android 模拟器中运行...
    flutter run -d android
) else if "%choice%"=="3" (
    echo.
    echo 📱 可用设备列表:
    flutter devices
    echo.
    pause
) else if "%choice%"=="4" (
    echo.
    echo ✅ 依赖安装完成！
) else (
    echo.
    echo ❌ 无效选择！
)

echo.
pause







