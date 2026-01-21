# Chatwoot Flutter Web Deployment Instructions

## 📋 Deployment Requirements

### Local Environment
- Flutter SDK installed
- SSH client (configured for passwordless login to `root@43.157.0.135`)
- Windows PowerShell (using deploy.ps1) or Bash (using deploy.sh)

### Server Environment
- Ubuntu/Debian Linux
- Nginx installed
- Chatwoot running on local port 3000 (optional)

## 🚀 Quick Deployment

### Windows Users

```powershell
# Execute in project root directory
.\deploy.ps1
```

### Linux/Mac Users

```bash
# Add execute permission
chmod +x deploy.sh

# Execute deployment
./deploy.sh
```

## 📦 Deployment Steps Explanation

The deployment script will automatically complete the following steps:

1. **Build Flutter Web Application**
   - Build production version using `flutter build web --release`
   - Output directory: `build/web/`

2. **Package Build Output**
   - Package `build/web/` as `deploy_package.tar.gz`

3. **Upload to Server**
   - Upload package file to `/tmp/chatwoot_flutter_deploy/`
   - Upload Nginx configuration file

4. **Server Configuration**
   - Deployment directory: `/var/www/chatwoot_flutter/`
   - Backup old version (if exists)
   - Extract new version
   - Configure Nginx reverse proxy
   - Restart Nginx service

5. **Clean Temporary Files**
   - Delete temporary files on local and server

## 🌐 Access URL

After deployment completion, access via:

```
http://43.157.0.135
```

## 🔧 Server Configuration Details

### Nginx Configuration Location
- Configuration file: `/etc/nginx/sites-available/chatwoot_flutter.conf`
- Symbolic link: `/etc/nginx/sites-enabled/chatwoot_flutter.conf`

### Application Deployment Location
- Web files: `/var/www/chatwoot_flutter/web/`
- Backup directory: `/var/www/chatwoot_flutter/web_backup/` (if exists)

### Proxy Configuration
- `/` → Flutter Web application
- `/api/v1/` → Chatwoot API (proxy to localhost:3000)
- `/cable` → Chatwoot WebSocket (proxy to localhost:3000)
- `/public/` → Chatwoot public resources (proxy to localhost:3000)

## 🐛 Troubleshooting

### View Nginx Error Log
```bash
ssh root@43.157.0.135 'tail -f /var/log/nginx/error.log'
```

### View Nginx Access Log
```bash
ssh root@43.157.0.135 'tail -f /var/log/nginx/access.log'
```

### Test Nginx Configuration
```bash
ssh root@43.157.0.135 'nginx -t'
```

### Restart Nginx
```bash
ssh root@43.157.0.135 'systemctl restart nginx'
```

### View Nginx Status
```bash
ssh root@43.157.0.135 'systemctl status nginx'
```

### Check Port Usage
```bash
ssh root@43.157.0.135 'netstat -tlnp | grep :80'
```

## 🔄 Redeployment

If you need to update the application, just run the deployment script again:

```powershell
# Windows
.\deploy.ps1
```

```bash
# Linux/Mac
./deploy.sh
```

Old version will be automatically backed up to `web_backup` directory.

## ⚙️ Environment Configuration

### Modify Backend API Address

Edit `lib/config/app_config.dart`:

```dart
// Main API server
static const String baseUrl = 'http://your-api-server.com';

// Chatwoot server
static const String chatwootBaseUrl = 'http://43.157.0.135';
```

After modification, need to rebuild and redeploy.

### Modify Chatwoot Token

Edit `lib/config/app_config.dart`:

```dart
static const String chatwootWebsiteToken = 'your-website-token';
```

## 🔐 Security Recommendations

1. **Enable HTTPS**
   - Use Let's Encrypt to get free SSL certificate
   - Configure Nginx SSL

2. **Configure Firewall**
   ```bash
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw enable
   ```

3. **Restrict SSH Access**
   - Disable root password login
   - Only allow key authentication

## 📝 Notes

1. Make sure Nginx is installed on server:
   ```bash
   ssh root@43.157.0.135 'apt update && apt install -y nginx'
   ```

2. If Chatwoot uses a different port, need to modify proxy address in Nginx configuration

3. First deployment may require configuring server firewall rules

4. Recommend regular backups of `/var/www/chatwoot_flutter/` directory

## 📞 Technical Support

If encountering problems, please check:
1. Is SSH passwordless login working properly
2. Does Flutter SDK version meet requirements
3. Is server Nginx running normally
4. Is network connection smooth

## 🎯 Next Steps

After successful deployment, you can:
1. Configure domain name resolution
2. Enable HTTPS
3. Configure CDN acceleration
4. Set up monitoring and log analysis
