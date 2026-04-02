import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';
import 'config/app_config.dart';
import 'utils/storage_util.dart';
import 'utils/app_logger.dart';
import 'services/push_notification_service.dart';
import 'services/unread_message_notifier.dart';
import 'pages/main_page.dart';
import 'pages/login/login_page.dart';
import 'pages/register/register_page.dart';
import 'providers/user_provider.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 重定向 debugPrint 到 AppLogger
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          // 1. 记录到 Talker (应用内日志)
          AppLogger.debug(message);
          
          // 2. 打印到控制台 (Console)
          // 注意：必须使用 print() 而不是 debugPrint()，因为 debugPrint 已被重定向。
          // 如果 Talker 开启了 console logs，它可能会调用 debugPrint 导致无限循环。
          // 所以这里我们手动输出到控制台，并在 AppLogger 中关闭 Talker 的 console logs。
          print(message);
        }
      };

      // 捕获 Flutter 框架错误
      FlutterError.onError = (FlutterErrorDetails details) {
        AppLogger.error(
          'Flutter Error',
          details.exception,
          details.stack,
        );
      };

      // 初始化本地存储（必须同步完成）
      await StorageUtil.init();

      // 初始化未读消息通知器（轻量级，快速完成）
      final unreadNotifier = UnreadMessageNotifier();
      await unreadNotifier.initialize();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: unreadNotifier),
            ChangeNotifierProvider(create: (_) => UserProvider()),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      AppLogger.critical('Uncaught Error', error, stack);
    },
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
    
    // 检查本地存储中是否有登录信息（使用 AppConfig 中定义的键）
    final isLoggedIn = await StorageUtil.getBool(AppConfig.keyIsLoggedIn) ?? false;
    final token = await StorageUtil.getString(AppConfig.keyToken);
    final userId = await StorageUtil.getString('userId');

    debugPrint('  - isLoggedIn标志: $isLoggedIn');
    debugPrint('  - token: ${token != null ? "存在(长度${token.length})" : "null"}');
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
    // 注意：推送注册现在在 _initializeBackgroundServices 中调用
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
        home: Scaffold(
          backgroundColor: Colors.black, // Match app theme
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo/icon area
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB4E666), // App primary green
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    size: 60,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                
                // App name
                const Text(
                  'Game Card Trading',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Tagline
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Loading indicator
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB4E666)),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Game Card Trading Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _isLoggedIn ? MainPage(key: mainPageKey) : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => MainPage(key: mainPageKey),
      },
    );
  }
}
