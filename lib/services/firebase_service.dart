import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../utils/storage_util.dart';

/// Firebase 推送通知服务
/// 
/// 负责管理 FCM (Firebase Cloud Messaging) 的初始化、Token 获取、
/// 消息处理和通知权限请求
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  /// Firebase 初始化状态
  bool _initialized = false;
  bool get initialized => _initialized;

  /// 当前 FCM Token
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// 本地存储的 FCM Token Key
  static const String _fcmTokenKey = 'fcm_push_token';

  /// 初始化 Firebase 和推送服务
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ Firebase 已经初始化');
      return;
    }

    try {
      // 初始化 Firebase
      await Firebase.initializeApp();
      debugPrint('✅ Firebase 初始化成功');

      // 设置前台消息处理器
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // 设置后台消息处理器（应用在后台被点击打开时）
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageOpened);
      
      // 获取并保存 FCM Token
      await _setupPushToken();

      _initialized = true;
      debugPrint('✅ 推送服务初始化成功');
    } catch (e) {
      debugPrint('❌ Firebase 初始化失败: $e');
      rethrow;
    }
  }

  /// 设置推送 Token
  Future<void> _setupPushToken() async {
    try {
      // 请求通知权限（iOS 需要，Android 13+ 也需要）
      await _requestPermission();

      // 获取 FCM Token
      _fcmToken = await FirebaseMessaging.instance.getToken();
      
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        debugPrint('📱 FCM Token: $_fcmToken');
        
        // 保存到本地存储
        await StorageUtil.setString(_fcmTokenKey, _fcmToken!);
        debugPrint('💾 FCM Token 已保存到本地存储');
      } else {
        debugPrint('⚠️ FCM Token 为空');
      }

      // 监听 Token 刷新
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token 已刷新: $newToken');
        _fcmToken = newToken;
        StorageUtil.setString(_fcmTokenKey, newToken);
      });
    } catch (e) {
      debugPrint('❌ 设置推送 Token 失败: $e');
    }
  }

  /// 请求通知权限
  Future<void> _requestPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // 请求权限
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ 用户已授予推送权限');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ 用户授予了临时推送权限');
      } else {
        debugPrint('❌ 用户拒绝了推送权限');
      }
    } catch (e) {
      debugPrint('⚠️ 请求推送权限失败: $e');
    }
  }

  /// 处理前台消息（应用在前台时收到推送）
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 收到前台消息:');
    debugPrint('  - 标题: ${message.notification?.title}');
    debugPrint('  - 内容: ${message.notification?.body}');
    debugPrint('  - 数据: ${message.data}');
    
    // 你可以在这里显示应用内通知或执行其他操作
    // 例如：显示 SnackBar、弹窗等
  }

  /// 处理后台消息被点击打开（应用在后台时用户点击通知）
  void _handleBackgroundMessageOpened(RemoteMessage message) {
    debugPrint('📬 后台消息被点击:');
    debugPrint('  - 标题: ${message.notification?.title}');
    debugPrint('  - 内容: ${message.notification?.body}');
    debugPrint('  - 数据: ${message.data}');
    
    // 你可以在这里导航到特定页面
    // 例如：根据 message.data 中的信息跳转到客服页面
  }

  /// 从本地存储获取 FCM Token
  Future<String?> getSavedToken() async {
    return await StorageUtil.getString(_fcmTokenKey);
  }

  /// 获取当前 FCM Token（优先从内存，否则从本地存储）
  Future<String?> getCurrentToken() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      return _fcmToken;
    }
    return await getSavedToken();
  }

  /// 订阅主题（用于组播推送）
  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('✅ 已订阅主题: $topic');
    } catch (e) {
      debugPrint('❌ 订阅主题失败: $e');
    }
  }

  /// 取消订阅主题
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('✅ 已取消订阅主题: $topic');
    } catch (e) {
      debugPrint('❌ 取消订阅主题失败: $e');
    }
  }

  /// 删除 FCM Token（用户登出时调用）
  Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      _fcmToken = null;
      await StorageUtil.remove(_fcmTokenKey);
      debugPrint('✅ FCM Token 已删除');
    } catch (e) {
      debugPrint('❌ 删除 FCM Token 失败: $e');
    }
  }
}

/// 后台消息处理器（必须是顶级函数）
/// 
/// 当应用完全关闭时收到推送消息会调用此函数
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 确保 Firebase 已初始化
  await Firebase.initializeApp();
  
  debugPrint('🌙 后台消息处理:');
  debugPrint('  - 标题: ${message.notification?.title}');
  debugPrint('  - 内容: ${message.notification?.body}');
  debugPrint('  - 数据: ${message.data}');
  
  // 你可以在这里执行一些后台任务
  // 注意：这里不能进行 UI 操作
}
