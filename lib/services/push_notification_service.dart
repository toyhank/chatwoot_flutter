import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'unread_message_notifier.dart';

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
  static UnreadMessageNotifier? _unreadNotifier;

  /// 初始化推送服务
  static Future<void> initialize({
    required String chatwootBaseUrl,
    required String websiteToken,
    UnreadMessageNotifier? unreadNotifier,
  }) async {
    _chatwootBaseUrl = chatwootBaseUrl;
    _websiteToken = websiteToken;
    _unreadNotifier = unreadNotifier;

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

    // Token 刷新监听 ⭐ 自动更新到服务器
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 Token 刷新: $newToken');
      _fcmToken = newToken;
      
      // ⭐ 自动上传新 token 到 Chatwoot 服务器
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastRegisteredUser = prefs.getString('registered_contact_identifier');
        
        if (lastRegisteredUser != null && lastRegisteredUser.isNotEmpty) {
          debugPrint('📤 自动上传新 Token 到服务器...');
          
          // 重新注册推送（会自动使用新 token）
          final success = await registerPushToken(
            contactIdentifier: lastRegisteredUser,
            // 从本地存储获取用户信息
            email: lastRegisteredUser,
          );
          
          if (success) {
            debugPrint('✅ Token 刷新后自动重新注册成功');
          } else {
            debugPrint('⚠️ Token 刷新后自动重新注册失败');
          }
        } else {
          debugPrint('ℹ️ 未找到已注册用户，跳过自动上传');
        }
      } catch (e) {
        debugPrint('❌ 自动上传新 Token 失败: $e');
      }
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
    
    // 增加未读消息计数
    _unreadNotifier?.incrementUnread();
    
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
  /// 
  /// ⭐ 传递 email 参数可以让 Chatwoot 自动合并相同邮箱的 Contacts
  static Future<String?> _initializeWidget({String? email, String? name}) async {
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
          
          // 如果提供了 email，更新 contact 信息以启用自动合并
          if (email != null) {
            final updateSuccess = await _updateContact(
              authToken: authToken.toString(),
              email: email,
              name: name,
            );
            if (updateSuccess) {
              debugPrint('✅ Contact 信息已更新，email 合并已启用');
            }
          }
          
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

  /// 更新 Contact 信息（用于启用 email 合并）
  static Future<bool> _updateContact({
    required String authToken,
    String? email,
    String? name,
  }) async {
    if (_chatwootBaseUrl == null || _websiteToken == null) {
      return false;
    }

    try {
      debugPrint('📤 正在更新 Contact 信息...');
      if (email != null) debugPrint('  - Email: $email');
      if (name != null) debugPrint('  - Name: $name');

      final response = await http.patch(
        Uri.parse('$_chatwootBaseUrl/api/v1/widget/contact'),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': authToken,
        },
        body: json.encode({
          'website_token': _websiteToken,
          if (email != null) 'email': email,
          if (name != null) 'name': name,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Contact 更新成功');
        return true;
      } else {
        debugPrint('⚠️ Contact 更新失败: ${response.statusCode}');
        debugPrint('  - 响应: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ 更新 Contact 错误: $e');
      return false;
    }
  }

  /// 步骤2: 注册推送 Token 到 Chatwoot 服务器
  /// 
  /// [contactIdentifier] 可以是 email 或其他唯一标识
  /// [name] 用户名称
  /// [email] 用户邮箱（推荐传递，可启用跨设备会话合并）
  /// [deviceId] 设备唯一标识（可选）
  static Future<bool> registerPushToken({
    required String contactIdentifier,
    String? name,
    String? email,
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
      
      // 检查是否是同一个用户
      final lastRegisteredUser = prefs.getString('registered_contact_identifier');
      final isUserChanged = lastRegisteredUser != null && lastRegisteredUser != contactIdentifier;
      
      // 先尝试从本地存储获取 auth token
      String? authToken = prefs.getString('chatwoot_auth_token');
      
      // ⭐ 如果用户切换了，先删除旧用户的推送订阅
      if (isUserChanged && authToken != null && authToken.isNotEmpty) {
        debugPrint('🔄 检测到用户切换: $lastRegisteredUser → $contactIdentifier');
        debugPrint('  - 正在删除旧用户的推送订阅...');
        
        // 使用旧的 auth token 删除旧订阅
        await _deleteOldPushSubscription(authToken);
        
        // 清除旧的 auth token
        debugPrint('  - 清除旧的 auth token，准备重新初始化');
        await prefs.remove('chatwoot_auth_token');
        authToken = null;
      }
      
      // 如果没有 auth token，先初始化 Widget（并可选更新 email/name）
      if (authToken == null || authToken.isEmpty) {
        debugPrint('📝 开始初始化 Widget 获取新的 auth token...');
        authToken = await _initializeWidget(
          email: email ?? contactIdentifier,
          name: name,
        );
        
        if (authToken == null) {
          debugPrint('❌ 无法获取 Auth Token');
          return false;
        }
      } else {
        debugPrint('ℹ️ 使用已保存的 auth token');
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
          
          // 重新获取 auth token（传递完整参数）
          authToken = await _initializeWidget(
            email: email ?? contactIdentifier,
            name: name,
          );
          
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

      // ⭐ 获取设备 ID（删除时必须传递）
      final deviceId = await _getDeviceId();
      
      debugPrint('📤 正在取消推送订阅...');
      debugPrint('  - Device ID: $deviceId');

      final response = await http.delete(
        Uri.parse('$_chatwootBaseUrl/api/v1/widget/push_subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': authToken,
        },
        body: json.encode({
          'push_subscription': {
            'device_id': deviceId,  // ⭐ 必须传递 device_id
          }
        }),
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

  /// 删除旧用户的推送订阅（内部方法）
  /// 
  /// 在用户切换时使用旧的 auth token 删除旧订阅
  static Future<void> _deleteOldPushSubscription(String oldAuthToken) async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      debugPrint('  ⚠️ 无 FCM Token，跳过删除');
      return;
    }

    if (_chatwootBaseUrl == null) {
      debugPrint('  ⚠️ Chatwoot 配置未初始化，跳过删除');
      return;
    }

    try {
      // ⭐ 获取设备 ID
      final deviceId = await _getDeviceId();
      
      final response = await http.delete(
        Uri.parse('$_chatwootBaseUrl/api/v1/widget/push_subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': oldAuthToken,
        },
        body: json.encode({
          'push_subscription': {
            'device_id': deviceId,  // ⭐ 必须传递 device_id
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('  ✅ 旧用户的推送订阅已删除');
      } else {
        debugPrint('  ⚠️ 删除旧订阅失败: ${response.statusCode}');
        debugPrint('  ℹ️ 这是正常的（旧订阅可能已不存在）');
      }
    } catch (e) {
      debugPrint('  ⚠️ 删除旧订阅异常: $e');
      debugPrint('  ℹ️ 将继续注册新用户');
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

  /// 清理 Chatwoot 相关数据
  /// 
  /// 在用户登出或切换账号时调用此方法，清除所有 Chatwoot 相关的本地数据
  /// 这样可以确保下次登录时使用新账号的身份注册推送
  static Future<void> clearChatwootData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chatwoot_auth_token');
      await prefs.remove('registered_push_token');
      await prefs.remove('registered_contact_identifier');
      debugPrint('🧹 Chatwoot 数据已清除');
    } catch (e) {
      debugPrint('❌ 清除 Chatwoot 数据失败: $e');
    }
  }
}
