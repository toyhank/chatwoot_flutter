/// 应用全局配置
class AppConfig {
  // API 服务器配置
  static const String baseUrl = 'http://ccvvb.cn';
  
  // ==================== Chatwoot 客服系统配置 ====================
  
  // 📝 如何获取这些配置：
  // 1. 登录 Chatwoot 管理后台（https://app.chatwoot.com 或您的自建服务器）
  // 2. 进入 Settings → Inboxes → 选择或创建一个 Website Inbox
  // 3. 在 Configuration → Widget Configuration 中找到并复制 Website Token
  
  // Chatwoot 实例地址
  // - 官方云服务: https://app.chatwoot.com
  // - 自建服务器: https://your-domain.com
  static const String chatwootBaseUrl = 'http://43.132.120.194:3000';
  
  // Website Token（必填）
  // 在 Chatwoot Inbox 设置中获取，格式类似: 'AbCdEf123456'
  static const String chatwootWebsiteToken = 'mYm3V3bEheaSb6GpSHvKKLUn';
  
  // 实现说明：
  // - Web 平台：直接注入 Chatwoot JavaScript SDK
  // - Android/iOS：使用 WebView 加载包含 Chatwoot SDK 的 HTML
  // - 支持用户信息自动识别（从本地存储读取）

  
  // 应用信息
  static const String appName = 'Game Card Trading Platform';
  static const String appVersion = '1.0.0';
  
  // 主题颜色
  static const int primaryColor = 0xFFB4E666; // 更新为截图中的亮绿色
  static const int backgroundColor = 0xFF000000;
  static const int cardColor = 0xFF1C1C1E;
  static const int textPrimaryColor = 0xFFFFFFFF;
  static const int textSecondaryColor = 0xFF666666;
  
  // 本地存储键
  static const String keyToken = 'user_token';
  static const String keyUserInfo = 'user_info';
  static const String keyIsLoggedIn = 'is_logged_in';
  
  // 获取完整 API URL
  static String getApiUrl(String path) {
    return '$baseUrl$path';
  }
  
  // 获取客服 URL
  static String getCustomerServiceUrl(String path) {
    return '$chatwootBaseUrl$path';
  }
}







