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
echo [3/4] 选择运行环境:
echo   1. 开发环境 (development) - 默认
echo   2. 测试环境 (testing)
echo   3. 生产环境 (production)
echo.
set /p env_choice="请选择环境 (1-3，默认1): "
if "%env_choice%"=="" set env_choice=1

set env_param=
if "%env_choice%"=="2" (
    set env_param=--dart-define=ENV=testing
    echo   已选择: 测试环境
) else if "%env_choice%"=="3" (
    set env_param=--dart-define=ENV=production
    echo   已选择: 生产环境
) else (
    set env_param=--dart-define=ENV=development
    echo   已选择: 开发环境
)

echo.
echo [4/4] 选择运行平台:
echo   1. Chrome (Web)
echo   2. Android 模拟器
echo   3. 查看所有设备
echo   4. 仅安装依赖（不运行）
echo.
set /p choice="请选择 (1-4): "

if "%choice%"=="1" (
    echo.
    echo 🚀 在 Chrome 中运行...
    flutter run -d chrome %env_param%
) else if "%choice%"=="2" (
    echo.
    echo 🚀 在 Android 模拟器中运行...
    flutter run -d android %env_param%
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







