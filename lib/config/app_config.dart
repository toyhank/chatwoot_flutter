import 'dart:convert';
import '../utils/storage_util.dart';

/// 应用全局配置
class AppConfig {
  // API 服务器配置
  static const String baseUrl = 'http://127.0.0.1:8080';
  
  // ==================== Chatwoot 客服系统配置 ====================
  
  // 📝 如何获取这些配置：
  // 1. 登录 Chatwoot 管理后台（https://app.chatwoot.com 或您的自建服务器）
  // 2. 进入 Settings → Inboxes → 选择或创建一个 Website Inbox
  // 3. 在 Configuration → Widget Configuration 中找到并复制 Website Token
  
  // Chatwoot 实例地址
  // - 官方云服务: https://app.chatwoot.com
  // - 自建服务器: https://your-domain.com
  //static const String chatwootBaseUrl = 'http://43.157.0.135:8080';
  static const String chatwootBaseUrl = 'http://127.0.0.1:8080';
  // Website Token（必填）
  // 在 Chatwoot Inbox 设置中获取，格式类似: 'AbCdEf123456'
  //static const String chatwootWebsiteToken = 'mYm3V3bEheaSb6GpSHvKKLUn';
  //static const String chatwootWebsiteToken = 'MDfuT28CS8iMYLdJNXmE95vA';
  static const String chatwootWebsiteToken = 'GJFzMx6qnv9DFpaspRpFDRDt';
  // HMAC Token（开启聊天身份验证时使用，仅测试可放这里，生产请改后端生成 hash）
  //static const String chatwootHmacToken = 'PxjbshoWpZGwV8hMdchUW84R';
  static const String chatwootHmacToken = 'oZB2ozJPetWF9diBkbrraXxK';
  
  // 默认用户信息（仅在没有登录时使用）
  static const String _defaultUserId = 'user_1001';
  static const String _defaultUserName = '游客';
  static const String _defaultUserEmail = 'guest@example.com';
  
  // 获取用户ID（从登录接口返回的信息中获取）
  static Future<String> getUserId() async {
    final userInfoStr = await StorageUtil.getString(keyUserInfo);
    if (userInfoStr != null && userInfoStr.isNotEmpty) {
      try {
        final userInfo = jsonDecode(userInfoStr) as Map<String, dynamic>;
        // 支持 uid 和 id 两种字段名
        if (userInfo['uid'] != null) {
          return userInfo['uid'].toString();
        }
        if (userInfo['id'] != null) {
          return userInfo['id'].toString();
        }
      } catch (e) {
        // 解析失败，使用默认值
      }
    }
    // 兼容旧版本的键
    final userId = await StorageUtil.getString('userId');
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    return _defaultUserId;
  }
  
  // 获取用户名（从登录接口返回的信息中获取）
  static Future<String> getUserName() async {
    final userInfoStr = await StorageUtil.getString(keyUserInfo);
    if (userInfoStr != null && userInfoStr.isNotEmpty) {
      try {
        final userInfo = jsonDecode(userInfoStr) as Map<String, dynamic>;
        // 支持 nickname 和 username 两种字段名
        if (userInfo['nickname'] != null) {
          return userInfo['nickname'].toString();
        }
        if (userInfo['username'] != null) {
          return userInfo['username'].toString();
        }
      } catch (e) {
        // 解析失败，使用默认值
      }
    }
    // 兼容旧版本的键
    final userName = await StorageUtil.getString('userName');
    if (userName != null && userName.isNotEmpty) {
      return userName;
    }
    return _defaultUserName;
  }
  
  // 获取用户邮箱（从登录接口返回的信息中获取）
  static Future<String> getUserEmail() async {
    final userInfoStr = await StorageUtil.getString(keyUserInfo);
    if (userInfoStr != null && userInfoStr.isNotEmpty) {
      try {
        final userInfo = jsonDecode(userInfoStr) as Map<String, dynamic>;
        if (userInfo['email'] != null) {
          return userInfo['email'].toString();
        }
      } catch (e) {
        // 解析失败，使用默认值
      }
    }
    // 兼容旧版本的键
    final userEmail = await StorageUtil.getString('userEmail');
    if (userEmail != null && userEmail.isNotEmpty) {
      return userEmail;
    }
    return _defaultUserEmail;
  }
  
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







