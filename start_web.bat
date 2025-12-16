@echo off
chcp 65001 > nul
echo ================================================
echo    Chatwoot Flutter Web 测试启动器
echo ================================================
echo.
echo 配置信息：
echo   服务器: http://43.132.120.194:3000
echo   Token: mYm3V3bEheaSb6GpSHvKKLUn
echo.
echo 正在启动 Flutter Web（禁用安全模式以避免 CORS 问题）...
echo.

cd /d %~dp0
flutter run -d chrome --web-browser-flag "--disable-web-security"

pause

