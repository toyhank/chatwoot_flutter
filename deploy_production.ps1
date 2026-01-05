# Chatwoot Flutter Web 生产环境部署脚本
# 目标服务器: root@43.157.0.135

$ErrorActionPreference = "Stop"

$SERVER = "root@43.157.0.135"
$DEPLOY_DIR = "/var/www/chatwoot_flutter"
$NGINX_CONFIG_DIR = "/etc/nginx/sites-available"
$NGINX_ENABLED_DIR = "/etc/nginx/sites-enabled"
$APP_NAME = "chatwoot_flutter"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Chatwoot Flutter Web 生产环境部署" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 确认生产环境配置
Write-Host "⚠️  生产环境部署确认" -ForegroundColor Yellow
Write-Host ""
Write-Host "请确认以下配置已正确设置：" -ForegroundColor Yellow
Write-Host "  1. lib/config/app_config.dart 中的生产环境 API 地址" -ForegroundColor White
Write-Host "  2. lib/config/app_config.dart 中的生产环境 Chatwoot Token" -ForegroundColor White
Write-Host "  3. 生产服务器地址和 SSH 连接配置" -ForegroundColor White
Write-Host ""
$confirm = Read-Host "确认已配置完成？(y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "❌ 部署已取消，请先配置生产环境参数！" -ForegroundColor Red
    exit 1
}

# 步骤 1: 构建 Flutter Web（生产环境）
Write-Host ""
Write-Host "[1/5] 构建 Flutter Web 应用（生产环境）..." -ForegroundColor Yellow
Write-Host ""

if (Test-Path "build\web") {
    Remove-Item -Recurse -Force "build\web"
}

flutter build web --release --web-renderer html --dart-define=ENV=production

if (-not $?) {
    Write-Host "❌ Flutter 构建失败！" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 构建完成！" -ForegroundColor Green
Write-Host ""

# 步骤 2: 打包构建产物
Write-Host "[2/5] 打包构建产物..." -ForegroundColor Yellow

if (Test-Path "deploy_package.tar.gz") {
    Remove-Item "deploy_package.tar.gz"
}

# 使用 tar 打包（Windows 10/11 自带）
tar -czf deploy_package.tar.gz -C build web

Write-Host "✅ 打包完成！" -ForegroundColor Green
Write-Host ""

# 步骤 3: 上传到服务器
Write-Host "[3/5] 上传文件到服务器..." -ForegroundColor Yellow

# 创建临时目录
ssh $SERVER "mkdir -p /tmp/chatwoot_flutter_deploy"

# 上传打包文件
scp deploy_package.tar.gz "${SERVER}:/tmp/chatwoot_flutter_deploy/"

# 上传 nginx 配置
if (Test-Path "nginx_chatwoot.conf") {
    scp nginx_chatwoot.conf "${SERVER}:/tmp/chatwoot_flutter_deploy/"
}

Write-Host "✅ 上传完成！" -ForegroundColor Green
Write-Host ""

# 步骤 4: 在服务器上部署
Write-Host "[4/5] 配置服务器..." -ForegroundColor Yellow

$REMOTE_SCRIPT = @"
#!/bin/bash
set -e

echo '正在部署应用...'

# 创建部署目录
mkdir -p $DEPLOY_DIR
cd $DEPLOY_DIR

# 备份旧版本
if [ -d 'web' ]; then
    echo '备份旧版本...'
    rm -rf web_backup
    mv web web_backup
    echo '✅ 旧版本已备份到 web_backup'
fi

# 解压新版本
tar -xzf /tmp/chatwoot_flutter_deploy/deploy_package.tar.gz

# 设置权限
chmod -R 755 $DEPLOY_DIR

# 配置 Nginx
echo '配置 Nginx...'

# 创建 Flutter Web 应用的 Nginx 配置
cat > /tmp/chatwoot_flutter.conf << 'NGINX_EOF'
# Flutter Web 应用配置（生产环境）
server {
    listen 80;
    server_name _;  # 或者您的域名

    root $DEPLOY_DIR/web;
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
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)`$ {
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

        # CORS
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
NGINX_EOF

# 安装配置
cp /tmp/chatwoot_flutter.conf $NGINX_CONFIG_DIR/chatwoot_flutter.conf

# 创建软链接（如果不存在）
if [ ! -L "$NGINX_ENABLED_DIR/chatwoot_flutter.conf" ]; then
    ln -s $NGINX_CONFIG_DIR/chatwoot_flutter.conf $NGINX_ENABLED_DIR/chatwoot_flutter.conf
fi

# 删除默认配置（如果存在）
if [ -L "$NGINX_ENABLED_DIR/default" ]; then
    rm $NGINX_ENABLED_DIR/default
fi

# 测试 Nginx 配置
nginx -t

# 重启 Nginx
systemctl restart nginx

# 检查 Nginx 状态
systemctl status nginx --no-pager

# 清理
rm -rf /tmp/chatwoot_flutter_deploy

echo '✅ 部署完成！'
echo ''
echo '访问地址：'
echo '  http://43.157.0.135'
echo ''
"@

# 将脚本上传并执行
$REMOTE_SCRIPT | ssh $SERVER "cat > /tmp/deploy.sh && chmod +x /tmp/deploy.sh && bash /tmp/deploy.sh"

Write-Host "✅ 服务器配置完成！" -ForegroundColor Green
Write-Host ""

# 步骤 5: 清理本地临时文件
Write-Host "[5/5] 清理临时文件..." -ForegroundColor Yellow
Remove-Item "deploy_package.tar.gz" -ErrorAction SilentlyContinue
Write-Host "✅ 清理完成！" -ForegroundColor Green
Write-Host ""

# 完成
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   🎉 生产环境部署成功！" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "访问地址：" -ForegroundColor Yellow
Write-Host "  http://43.157.0.135" -ForegroundColor Cyan
Write-Host ""
Write-Host "查看日志：" -ForegroundColor Yellow
Write-Host "  ssh $SERVER 'tail -f /var/log/nginx/error.log'" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  生产环境部署注意事项：" -ForegroundColor Yellow
Write-Host "  1. 确保已配置 HTTPS（推荐使用 Let's Encrypt）" -ForegroundColor White
Write-Host "  2. 检查防火墙规则" -ForegroundColor White
Write-Host "  3. 配置域名解析" -ForegroundColor White
Write-Host "  4. 定期备份数据" -ForegroundColor White
Write-Host ""




