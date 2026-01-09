import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

/// Chatwoot 推送通知服务
/// 
/// 负责管理 FCM Token、注册到 Chatwoot 服务器、处理推送消息
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static String? _fcmToken;
  static String? _chatwootBaseUrl;
  static String? _websiteToken;

  /// 初始化推送服务
  static Future<void> initialize({
    required String chatwootBaseUrl,
    required String websiteToken,
  }) async {
    _chatwootBaseUrl = chatwootBaseUrl;
    _websiteToken = websiteToken;

    debugPrint('🚀 初始化推送通知服务...');

    // 初始化 Firebase（如果还未初始化）
    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase 初始化成功');
    } catch (e) {
      // Firebase 可能已经初始化，忽略错误
      debugPrint('ℹ️ Firebase 已经初始化或初始化失败: $e');
    }

    // 请求通知权限
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('⚠️ 用户未授予通知权限');
      return;
    }

    debugPrint('✅ 用户已授予通知权限');

    // 初始化本地通知
    await _initLocalNotifications();

    // 获取 FCM Token
    _fcmToken = await _messaging.getToken();
    if (_fcmToken != null) {
      debugPrint('✅ FCM Token: $_fcmToken');
    } else {
      debugPrint('⚠️ FCM Token 为空');
    }

    // Token 刷新监听
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 Token 刷新: $newToken');
      _fcmToken = newToken;
      // TODO: 自动更新到服务器
    });

    // 设置消息处理
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // 检查初始消息（应用被推送通知打开的情况）
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    debugPrint('✅ 推送通知服务初始化完成');
  }

  /// 初始化本地通知
  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          final data = json.decode(response.payload!);
          debugPrint('📱 通知点击数据: $data');
          // TODO: 导航到对话页面
        }
      },
    );

    // 创建 Android 通知渠道
    const channel = AndroidNotificationChannel(
      'chatwoot_messages',
      '客服消息',
      description: '接收客服回复',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('✅ 本地通知渠道已创建');
  }

  /// 处理前台消息
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 收到前台消息:');
    debugPrint('  - 标题: ${message.notification?.title}');
    debugPrint('  - 内容: ${message.notification?.body}');
    debugPrint('  - 数据: ${message.data}');
    
    _showNotification(message);
  }

  /// 显示本地通知
  static Future<void> _showNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'chatwoot_messages',
      '客服消息',
      channelDescription: '接收客服回复',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? '新消息',
      message.notification?.body ?? '',
      details,
      payload: json.encode(message.data),
    );
  }

  /// 处理通知点击
  static void _handleMessageTap(RemoteMessage message) {
    debugPrint('👆 通知被点击:');
    debugPrint('  - 数据: ${message.data}');
    // TODO: 根据数据导航到对话页面
  }

  /// 步骤1: 初始化 Widget 并获取 Auth Token
  static Future<String?> _initializeWidget() async {
    if (_chatwootBaseUrl == null || _websiteToken == null) {
      debugPrint('❌ Chatwoot 配置未初始化');
      return null;
    }

    try {
      debugPrint('📤 正在初始化 Widget...');
      debugPrint('  - URL: $_chatwootBaseUrl/api/v1/widget/config');
      debugPrint('  - Website Token: $_websiteToken');

      final response = await http.post(
        Uri.parse('$_chatwootBaseUrl/api/v1/widget/config'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'website_token': _websiteToken,
        }),
      );

      debugPrint('📥 Widget 响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('📥 响应数据结构: ${data.keys.toList()}');
        
        // 从 JSON 响应中获取 auth_token
        final authToken = data['website_channel_config']?['auth_token'];
        
        if (authToken != null && authToken.toString().isNotEmpty) {
          debugPrint('✅ Widget 初始化成功');
          debugPrint('🔑 获取到 Auth Token: ${authToken.toString().substring(0, 20)}...');
          
          // 保存 auth token 到本地存储
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('chatwoot_auth_token', authToken.toString());
          
          return authToken.toString();
        } else {
          debugPrint('⚠️ 响应中没有 auth_token');
          debugPrint('⚠️ website_channel_config: ${data['website_channel_config']}');
          return null;
        }
      } else {
        debugPrint('❌ Widget 初始化失败: ${response.statusCode}');
        debugPrint('  - 响应: ${response.body}');
        
        if (response.statusCode == 404) {
          debugPrint('⚠️⚠️⚠️ Widget Config API 不存在！');
          debugPrint('⚠️ 请检查 Chatwoot 服务器版本和配置');
        }
        
        return null;
      }
    } catch (e) {
      debugPrint('❌ Widget 初始化错误: $e');
      debugPrint('❌ 错误类型: ${e.runtimeType}');
      return null;
    }
  }

  /// 步骤2: 注册推送 Token 到 Chatwoot 服务器
  static Future<bool> registerPushToken({
    required String contactIdentifier,
    String? name,
    String? deviceId,
  }) async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      debugPrint('❌ FCM Token 未就绪，无法注册');
      return false;
    }

    if (_chatwootBaseUrl == null || _websiteToken == null) {
      debugPrint('❌ Chatwoot 配置未初始化');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 先尝试从本地存储获取 auth token
      String? authToken = prefs.getString('chatwoot_auth_token');
      
      // 如果没有 auth token，先初始化 Widget
      if (authToken == null || authToken.isEmpty) {
        authToken = await _initializeWidget();
        
        if (authToken == null) {
          debugPrint('❌ 无法获取 Auth Token');
          return false;
        }
      }

      final actualDeviceId = deviceId ?? await _getDeviceId();

      debugPrint('📤 正在注册推送 Token 到 Chatwoot...');
      debugPrint('  - Contact: $contactIdentifier');
      debugPrint('  - Device ID: $actualDeviceId');

      final response = await http.post(
        Uri.parse('$_chatwootBaseUrl/api/v1/widget/push_subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': authToken,
        },
        body: json.encode({
          'website_token': _websiteToken,
          'push_subscription': {
            'push_token': _fcmToken,
            'device_id': actualDeviceId,
            'platform': 'android',
          }
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ 推送 Token 注册成功');
        await prefs.setString('registered_push_token', _fcmToken!);
        await prefs.setString('registered_contact_identifier', contactIdentifier);
        return true;
      } else {
        debugPrint('❌ 注册失败: ${response.statusCode}');
        debugPrint('  - 响应: ${response.body}');
        
        // 如果是 401 或 403，可能是 auth token 过期，清除并重试一次
        if (response.statusCode == 401 || response.statusCode == 403) {
          debugPrint('🔄 Auth Token 可能过期，尝试重新获取...');
          await prefs.remove('chatwoot_auth_token');
          
          // 重新获取 auth token
          authToken = await _initializeWidget();
          
          if (authToken != null) {
            // 重试注册
            final retryResponse = await http.post(
              Uri.parse('$_chatwootBaseUrl/api/v1/widget/push_subscriptions'),
              headers: {
                'Content-Type': 'application/json',
                'X-Auth-Token': authToken,
              },
              body: json.encode({
                'website_token': _websiteToken,
                'push_subscription': {
                  'push_token': _fcmToken,
                  'device_id': actualDeviceId,
                  'platform': 'android',
                }
              }),
            );
            
            if (retryResponse.statusCode == 201 || retryResponse.statusCode == 200) {
              debugPrint('✅ 重试成功，推送 Token 注册成功');
              await prefs.setString('registered_push_token', _fcmToken!);
              await prefs.setString('registered_contact_identifier', contactIdentifier);
              return true;
            }
          }
        }
        
        return false;
      }
    } catch (e) {
      debugPrint('❌ 注册错误: $e');
      return false;
    }
  }

  /// 取消推送订阅
  static Future<bool> unregisterPushToken() async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      debugPrint('⚠️ FCM Token 为空，跳过取消注册');
      return false;
    }

    if (_chatwootBaseUrl == null || _websiteToken == null) {
      debugPrint('❌ Chatwoot 配置未初始化');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('chatwoot_auth_token');
      
      if (authToken == null) {
        debugPrint('⚠️ 没有 Auth Token，无法取消订阅');
        return false;
      }

      debugPrint('📤 正在取消推送订阅...');

      final response = await http.delete(
        Uri.parse('$_chatwootBaseUrl/api/v1/widget/push_subscriptions/$_fcmToken'),
        headers: {
          'X-Auth-Token': authToken,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ 取消订阅成功');
        await prefs.remove('registered_push_token');
        await prefs.remove('registered_contact_identifier');
        await prefs.remove('chatwoot_auth_token');
        return true;
      } else {
        debugPrint('❌ 取消订阅失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ 取消订阅错误: $e');
      return false;
    }
  }

  /// 获取或生成设备 ID
  static Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('device_id', deviceId);
      debugPrint('🆔 生成新设备 ID: $deviceId');
    }

    return deviceId;
  }

  /// 获取当前 FCM Token
  static String? get fcmToken => _fcmToken;

  /// 检查是否已注册
  static Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('registered_push_token');
    return savedToken != null && savedToken == _fcmToken;
  }
}
