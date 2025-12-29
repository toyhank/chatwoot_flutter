@echo off
chcp 65001 > nul
echo ================================================
echo    Chatwoot Flutter 快速部署
echo ================================================
echo.

set SERVER=root@43.157.0.135
set DEPLOY_DIR=/var/www/chatwoot_flutter

REM 步骤1: 检查构建文件
if not exist "deploy_package.tar.gz" (
    echo ❌ 未找到 deploy_package.tar.gz
    echo 请先运行: tar -czf deploy_package.tar.gz -C build web
    pause
    exit /b 1
)

echo [1/4] 上传文件到服务器...
scp deploy_package.tar.gz %SERVER%:/tmp/
if errorlevel 1 (
    echo ❌ 上传失败！
    pause
    exit /b 1
)
echo ✓ 上传完成
echo.

echo [2/4] 部署应用文件...
ssh %SERVER% "mkdir -p %DEPLOY_DIR% && cd %DEPLOY_DIR% && ([ -d 'web' ] && (rm -rf web_backup; mv web web_backup) || true) && tar -xzf /tmp/deploy_package.tar.gz && chmod -R 755 %DEPLOY_DIR% && rm /tmp/deploy_package.tar.gz"
if errorlevel 1 (
    echo ❌ 部署失败！
    pause
    exit /b 1
)
echo ✓ 应用文件部署完成
echo.

echo [3/4] 配置 Nginx...

REM 创建Nginx配置文件
(
echo server {
echo     listen 80 default_server;
echo     server_name _;
echo     root %DEPLOY_DIR%/web;
echo     index index.html;
echo.
echo     gzip on;
echo     gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
echo     gzip_min_length 1000;
echo.
echo     location / {
echo         try_files $uri $uri/ /index.html;
echo         add_header Cache-Control 'no-cache';
echo     }
echo.
echo     location ~* \.(js^|css^|png^|jpg^|jpeg^|gif^|ico^|svg^|woff^|woff2^|ttf^|eot^)$ {
echo         expires 1y;
echo         add_header Cache-Control 'public';
echo     }
echo.
echo     location /api/v1/ {
echo         proxy_pass http://127.0.0.1:3000/api/v1/;
echo         proxy_http_version 1.1;
echo         proxy_set_header Host $host;
echo         proxy_set_header X-Real-IP $remote_addr;
echo         add_header 'Access-Control-Allow-Origin' '*' always;
echo         add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
echo     }
echo.
echo     location /cable {
echo         proxy_pass http://127.0.0.1:3000/cable;
echo         proxy_http_version 1.1;
echo         proxy_set_header Upgrade $http_upgrade;
echo         proxy_set_header Connection "upgrade";
echo         proxy_set_header Host $host;
echo         proxy_connect_timeout 7d;
echo         proxy_send_timeout 7d;
echo         proxy_read_timeout 7d;
echo     }
echo.
echo     location /public/ {
echo         proxy_pass http://127.0.0.1:3000/public/;
echo         proxy_set_header Host $host;
echo     }
echo }
) > nginx_temp.conf

scp nginx_temp.conf %SERVER%:/tmp/chatwoot_flutter.conf
del nginx_temp.conf

ssh %SERVER% "cp /tmp/chatwoot_flutter.conf /etc/nginx/sites-available/ && ln -sf /etc/nginx/sites-available/chatwoot_flutter.conf /etc/nginx/sites-enabled/ && rm -f /etc/nginx/sites-enabled/default && nginx -t && systemctl restart nginx"

if errorlevel 1 (
    echo ❌ Nginx配置失败！
    pause
    exit /b 1
)
echo ✓ Nginx配置完成
echo.

echo [4/4] 清理临时文件...
del deploy_package.tar.gz 2>nul

echo.
echo ================================================
echo    🎉 部署成功！
echo ================================================
echo.
echo 访问地址: http://43.157.0.135
echo.
pause









