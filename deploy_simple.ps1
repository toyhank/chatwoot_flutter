# Chatwoot Flutter Web 简单部署脚本
$ErrorActionPreference = "Stop"

$SERVER = "root@43.157.0.135"
$DEPLOY_DIR = "/var/www/chatwoot_flutter"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Chatwoot Flutter Web 部署" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 步骤 1: 构建已完成，打包构建产物
Write-Host "[1/4] 打包构建产物..." -ForegroundColor Yellow

if (Test-Path "deploy_package.tar.gz") {
    Remove-Item "deploy_package.tar.gz"
}

tar -czf deploy_package.tar.gz -C build web

Write-Host "✅ 打包完成！" -ForegroundColor Green
Write-Host ""

# 步骤 2: 上传到服务器
Write-Host "[2/4] 上传文件到服务器..." -ForegroundColor Yellow

scp deploy_package.tar.gz "${SERVER}:/tmp/"

Write-Host "✅ 上传完成！" -ForegroundColor Green
Write-Host ""

# 步骤 3: 在服务器上部署
Write-Host "[3/4] 在服务器上部署..." -ForegroundColor Yellow

ssh $SERVER @"
set -e
echo '正在部署应用...'
mkdir -p $DEPLOY_DIR
cd $DEPLOY_DIR
if [ -d 'web' ]; then
    echo '备份旧版本...'
    rm -rf web_backup
    mv web web_backup
fi
tar -xzf /tmp/deploy_package.tar.gz
chmod -R 755 $DEPLOY_DIR
rm /tmp/deploy_package.tar.gz
echo '✅ 应用文件部署完成！'
"@

Write-Host "✅ 部署完成！" -ForegroundColor Green
Write-Host ""

# 步骤 4: 配置 Nginx
Write-Host "[4/4] 配置 Nginx..." -ForegroundColor Yellow

$nginxConfig = @"
# Flutter Web 应用配置
server {
    listen 80 default_server;
    server_name _;

    root /var/www/chatwoot_flutter/web;
    index index.html;

    # Gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_min_length 1000;

    # Flutter Web 应用
    location / {
        try_files `$uri `$uri/ /index.html;
        add_header Cache-Control 'no-cache, no-store, must-revalidate';
        add_header Pragma 'no-cache';
        add_header Expires '0';
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control 'public, immutable';
    }

    # Chatwoot API 代理
    location /api/v1/ {
        proxy_pass http://127.0.0.1:3000/api/v1/;
        proxy_http_version 1.1;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;

        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        
        if (`$request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Chatwoot WebSocket
    location /cable {
        proxy_pass http://127.0.0.1:3000/cable;
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }

    # Chatwoot 公共资源
    location /public/ {
        proxy_pass http://127.0.0.1:3000/public/;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
    }
}
"@

# 写入配置到服务器
$nginxConfig | ssh $SERVER "cat > /etc/nginx/sites-available/chatwoot_flutter.conf"

# 创建软链接并重启 Nginx
ssh $SERVER @"
set -e
ln -sf /etc/nginx/sites-available/chatwoot_flutter.conf /etc/nginx/sites-enabled/chatwoot_flutter.conf
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
systemctl status nginx --no-pager || true
echo '✅ Nginx 配置完成！'
"@

Write-Host "✅ Nginx 配置完成！" -ForegroundColor Green
Write-Host ""

# 清理
Remove-Item "deploy_package.tar.gz" -ErrorAction SilentlyContinue

# 完成
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   🎉 部署成功！" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "访问地址：http://43.157.0.135" -ForegroundColor Cyan
Write-Host ""









