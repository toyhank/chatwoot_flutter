@echo off
chcp 65001 > nul
echo ================================================
echo    Windows SSH 免密登录配置工具
echo ================================================
echo.
echo 目标服务器: root@43.157.0.135
echo.

REM 检查是否已有SSH密钥
if exist "%USERPROFILE%\.ssh\id_rsa.pub" (
    echo ✓ SSH密钥已存在
) else (
    echo 正在生成SSH密钥...
    ssh-keygen -t rsa -b 4096 -f "%USERPROFILE%\.ssh\id_rsa" -N ""
    echo ✓ SSH密钥生成完成
)

echo.
echo ------------------------------------------------
echo 步骤 1: 复制SSH公钥到服务器
echo ------------------------------------------------
echo.
echo 请输入服务器密码以完成配置...
echo.

REM 复制公钥到服务器
type "%USERPROFILE%\.ssh\id_rsa.pub" | ssh root@43.157.0.135 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo '✓ SSH公钥已添加'"

if errorlevel 1 (
    echo.
    echo ❌ 配置失败！请检查：
    echo    1. 服务器地址是否正确
    echo    2. 密码是否正确
    echo    3. 网络连接是否正常
    echo.
    pause
    exit /b 1
)

echo.
echo ------------------------------------------------
echo 步骤 2: 测试免密登录
echo ------------------------------------------------
echo.

ssh root@43.157.0.135 "echo '✓ 免密登录测试成功！'"

if errorlevel 1 (
    echo ❌ 免密登录测试失败！
) else (
    echo.
    echo ================================================
    echo    🎉 SSH免密登录配置完成！
    echo ================================================
    echo.
    echo 现在可以执行部署了...
)

echo.
pause












