import 'dart:convert';
import '../utils/storage_util.dart';

/// 环境类型枚举
enum Environment {
  development, // 开发环境
  testing,     // 测试环境
  production,  // 生产环境
}

/// 应用全局配置
class AppConfig {
  // ==================== 环境配置 ====================
  // 切换环境的方法：
  // 方法1（推荐）：使用编译参数 --dart-define=ENV=development/testing/production
  // 方法2：直接修改下面的 _currentEnvironment 常量
  
  // 从编译参数获取环境，如果没有则使用默认值
  static Environment get _envFromDefine {
    const envStr = String.fromEnvironment('ENV', defaultValue: 'development');
    switch (envStr.toLowerCase()) {
      case 'testing':
      case 'test':
        return Environment.testing;
      case 'production':
      case 'prod':
        return Environment.production;
      case 'development':
      case 'dev':
      default:
        return Environment.development;
    }
  }
  
  // 当前环境（优先使用编译参数，否则使用这里设置的默认值）
  static Environment get currentEnvironment => _envFromDefine;
  
  // 是否为开发环境
  static bool get isDevelopment => currentEnvironment == Environment.development;
  // 是否为测试环境
  static bool get isTesting => currentEnvironment == Environment.testing;
  // 是否为生产环境
  static bool get isProduction => currentEnvironment == Environment.production;
  
  // ==================== 环境配置映射 ====================
  
  // API 服务器配置（根据环境返回不同的地址）
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'http://127.0.0.1:8080';
      case Environment.testing:
        return 'http://43.157.0.135:8080'; // 测试服务器地址
      case Environment.production:
        return 'https://api.yourdomain.com'; // 生产服务器地址（请修改为实际地址）
    }
  }
  
  // ==================== Chatwoot 客服系统配置 ====================
  
  // 📝 如何获取这些配置：
  // 1. 登录 Chatwoot 管理后台（https://app.chatwoot.com 或您的自建服务器）
  // 2. 进入 Settings → Inboxes → 选择或创建一个 Website Inbox
  // 3. 在 Configuration → Widget Configuration 中找到并复制 Website Token
  
  // Chatwoot 实例地址（根据环境返回不同的地址）
  static String get chatwootBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'http://127.0.0.1:8080';
      case Environment.testing:
        return 'http://43.157.0.135:8080'; // 测试服务器地址
      case Environment.production:
        return 'https://chatwoot.yourdomain.com'; // 生产服务器地址（请修改为实际地址）
    }
  }
  
  // Website Token（根据环境返回不同的 Token）
  static String get chatwootWebsiteToken {
    switch (currentEnvironment) {
      case Environment.development:
        return 'GJFzMx6qnv9DFpaspRpFDRDt';
      case Environment.testing:
        return 'MDfuT28CS8iMYLdJNXmE95vA'; // 测试环境 Token
      case Environment.production:
        return 'YOUR_PRODUCTION_TOKEN'; // 生产环境 Token（请修改为实际 Token）
    }
  }
  
  // HMAC Token（根据环境返回不同的 Token）
  static String get chatwootHmacToken {
    switch (currentEnvironment) {
      case Environment.development:
        return 'oZB2ozJPetWF9diBkbrraXxK';
      case Environment.testing:
        return 'PxjbshoWpZGwV8hMdchUW84R'; // 测试环境 Token
      case Environment.production:
        return 'YOUR_PRODUCTION_HMAC_TOKEN'; // 生产环境 Token（请修改为实际 Token）
    }
  }
  
  // 默认用户信息（仅在没有登录时使用）
  static const String _defaultUserId = 'user_1001';
  static const String _defaultUserName = 'Guest';
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
  
  // 获取用户余额
  static Future<double> getUserBalance() async {
    final userInfoStr = await StorageUtil.getString(keyUserInfo);
    if (userInfoStr != null && userInfoStr.isNotEmpty) {
      try {
        final userInfo = jsonDecode(userInfoStr) as Map<String, dynamic>;
        if (userInfo['balance'] != null) {
          return double.tryParse(userInfo['balance'].toString()) ?? 0.0;
        }
      } catch (e) {
        // 解析失败
      }
    }
    return 0.0;
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







