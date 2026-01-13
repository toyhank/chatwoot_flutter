import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';
import 'config/app_config.dart';
import 'utils/storage_util.dart';
import 'services/push_notification_service.dart';
import 'services/unread_message_notifier.dart';
import 'pages/main_page.dart';
import 'pages/login/login_page.dart';
import 'pages/register/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地存储
  await StorageUtil.init();

  // 初始化 Firebase（使用平台特定配置）
  try {
    if (Platform.isIOS) {
      // iOS 配置（从 GoogleService-Info.plist 提取）
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCr5gSBLYbarDdjDKshe684tmTSl4elPMQ",
          appId: "1:938639328662:ios:137258b304caff91cf49b7",
          messagingSenderId: "938639328662",
          projectId: "xcard-2b2ea",
          storageBucket: "xcard-2b2ea.firebasestorage.app",
          iosBundleId: "com.toyhank.xcard",
        ),
      );
      debugPrint('✅ Firebase iOS 初始化成功');
    } else {
      // Android 配置（会自动读取 google-services.json）
      await Firebase.initializeApp();
      debugPrint('✅ Firebase Android 初始化成功');
    }
  } catch (e) {
    debugPrint('⚠️ Firebase 初始化失败: $e');
    // 继续运行应用，但推送功能可能不可用
  }

  // 初始化未读消息通知器
  final unreadNotifier = UnreadMessageNotifier();
  await unreadNotifier.initialize();

  // 初始化推送通知服务（包含 Chatwoot 集成）
  try {
    await PushNotificationService.initialize(
      chatwootBaseUrl: AppConfig.chatwootBaseUrl,
      websiteToken: AppConfig.chatwootWebsiteToken,
      unreadNotifier: unreadNotifier, // 传递未读消息通知器
    );
    
    debugPrint('✅ 推送通知服务初始化完成');
  } catch (e) {
    debugPrint('⚠️ 推送服务初始化失败，应用将继续运行: $e');
  }

  runApp(
    ChangeNotifierProvider.value(
      value: unreadNotifier,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    debugPrint('🔍 开始检查登录状态...');
    
    // 检查本地存储中是否有登录信息
    final isLoggedIn = await StorageUtil.getBool('isLoggedIn') ?? false;
    final token = await StorageUtil.getString('token');
    final userId = await StorageUtil.getString('userId');

    debugPrint('  - isLoggedIn标志: $isLoggedIn');
    debugPrint('  - token: ${token != null ? "存在" : "null"}');
    debugPrint('  - userId: ${userId != null ? "存在" : "null"}');

    setState(() {
      _isLoggedIn = isLoggedIn && token != null && token.isNotEmpty && userId != null && userId.isNotEmpty;
      _isLoading = false;
    });
    
    debugPrint('✅ 登录状态检查完成: $_isLoggedIn');
    
    // ⭐ 如果已登录，注册推送 Token（确保推送订阅是最新的）
    if (_isLoggedIn) {
      debugPrint('✅ 用户已登录，准备注册推送订阅...');
      _registerPushIfLoggedIn();
    } else {
      debugPrint('⚠️ 用户未登录，跳过推送注册');
    }
  }
  
  /// 为已登录用户注册推送通知
  /// 
  /// 这确保了即使用户不是通过登录流程进入应用，
  /// 推送订阅也会保持最新状态
  Future<void> _registerPushIfLoggedIn() async {
    debugPrint('📱 开始为已登录用户注册推送...');
    
    try {
      final email = await AppConfig.getUserEmail();
      final name = await AppConfig.getUserName();
      
      debugPrint('  - Email: $email');
      debugPrint('  - Name: $name');
      
      if (email.isEmpty) {
        debugPrint('⚠️ 用户邮箱为空，跳过推送注册');
        return;
      }
      
      debugPrint('🔄 检测到已登录用户，注册推送订阅...');
      
      final success = await PushNotificationService.registerPushToken(
        contactIdentifier: email,
        name: name,
        email: email,
      );
      
      if (success) {
        debugPrint('✅ 应用启动时推送注册成功');
      } else {
        debugPrint('⚠️ 应用启动时推送注册失败');
      }
    } catch (e) {
      debugPrint('❌ 应用启动时推送注册错误: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Game Card Trading Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _isLoggedIn ? const MainPage() : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => const MainPage(),
      },
    );
  }
}
