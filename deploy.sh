#!/bin/bash
# Chatwoot Flutter Web 部署脚本
# 目标服务器: root@43.157.0.135

set -e

SERVER="root@43.157.0.135"
DEPLOY_DIR="/var/www/chatwoot_flutter"
NGINX_CONFIG_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
APP_NAME="chatwoot_flutter"

echo "================================================"
echo "   Chatwoot Flutter Web 自动部署"
echo "================================================"
echo ""

# 步骤 1: 选择部署环境
echo "[1/6] 选择部署环境..."
echo "  1. 测试环境 (testing)"
echo "  2. 生产环境 (production)"
echo ""
read -p "请选择环境 (1-2，默认1): " env_choice
env_choice=${env_choice:-1}

env_param=""
env_name=""
if [ "$env_choice" = "2" ]; then
    env_param="--dart-define=ENV=production"
    env_name="生产环境"
    echo "  已选择: 生产环境"
    echo "  ⚠️  请确保已配置生产环境的 API 地址和 Token！"
else
    env_param="--dart-define=ENV=testing"
    env_name="测试环境"
    echo "  已选择: 测试环境"
fi
echo ""

# 步骤 2: 构建 Flutter Web
echo "[2/6] 构建 Flutter Web 应用 ($env_name)..."
echo ""

if [ -d "build/web" ]; then
    rm -rf build/web
fi

flutter build web --release --web-renderer html $env_param

if [ $? -ne 0 ]; then
    echo "❌ Flutter 构建失败！"
    exit 1
fi

echo "✅ 构建完成！"
echo ""

# 步骤 3: 打包构建产物
echo "[3/6] 打包构建产物..."

if [ -f "deploy_package.tar.gz" ]; then
    rm deploy_package.tar.gz
fi

tar -czf deploy_package.tar.gz -C build web

echo "✅ 打包完成！"
echo ""

# 步骤 4: 上传到服务器
echo "[4/6] 上传文件到服务器..."

# 创建临时目录
ssh $SERVER "mkdir -p /tmp/chatwoot_flutter_deploy"

# 上传打包文件
scp deploy_package.tar.gz ${SERVER}:/tmp/chatwoot_flutter_deploy/

# 上传 nginx 配置
scp nginx_chatwoot.conf ${SERVER}:/tmp/chatwoot_flutter_deploy/

echo "✅ 上传完成！"
echo ""

# 步骤 5: 在服务器上部署
echo "[5/6] 配置服务器..."

ssh $SERVER bash << 'REMOTE_SCRIPT'
#!/bin/bash
set -e

DEPLOY_DIR="/var/www/chatwoot_flutter"
NGINX_CONFIG_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"

echo '正在部署应用...'

# 创建部署目录
mkdir -p $DEPLOY_DIR
cd $DEPLOY_DIR

# 备份旧版本
if [ -d 'web' ]; then
    echo '备份旧版本...'
    rm -rf web_backup
    mv web web_backup
fi

# 解压新版本
tar -xzf /tmp/chatwoot_flutter_deploy/deploy_package.tar.gz

# 设置权限
chmod -R 755 $DEPLOY_DIR

# 配置 Nginx
echo '配置 Nginx...'

# 创建 Flutter Web 应用的 Nginx 配置
cat > /tmp/chatwoot_flutter.conf << 'NGINX_EOF'
# Flutter Web 应用配置
server {
    listen 80 default_server;
    server_name _;  # 或者您的域名

    root /var/www/chatwoot_flutter/web;
    index index.html;

    # Gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_min_length 1000;

    # Flutter Web 应用
    location / {
        try_files $uri $uri/ /index.html;
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
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # CORS
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Chatwoot WebSocket
    location /cable {
        proxy_pass http://127.0.0.1:3000/cable;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }

    # Chatwoot 公共资源
    location /public/ {
        proxy_pass http://127.0.0.1:3000/public/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
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
systemctl status nginx --no-pager || true

# 清理
rm -rf /tmp/chatwoot_flutter_deploy

echo '✅ 部署完成！'
echo ''
echo '访问地址：'
echo '  http://43.157.0.135'
echo ''
REMOTE_SCRIPT

echo "✅ 服务器配置完成！"
echo ""

# 步骤 6: 清理本地临时文件
echo "[6/6] 清理临时文件..."
rm -f deploy_package.tar.gz
echo "✅ 清理完成！"
echo ""

# 完成
echo "================================================"
echo "   🎉 部署成功！"
echo "================================================"
echo ""
echo "访问地址："
echo "  http://43.157.0.135"
echo ""
echo "查看日志："
echo "  ssh $SERVER 'tail -f /var/log/nginx/error.log'"
echo ""









