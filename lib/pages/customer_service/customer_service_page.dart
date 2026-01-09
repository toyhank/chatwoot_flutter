import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:crypto/crypto.dart' as crypto;
import '../../config/app_config.dart';
import '../../utils/storage_util.dart';
import '../../services/firebase_service.dart';

/// Chatwoot 客服页面 - 使用 InAppWebView 直接加载 widget
class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;

  /// 构建 Chatwoot widget URL
  Future<String> get _webviewURL async {
    // 获取用户信息
    final userId = await AppConfig.getUserId();
    final userName = await AppConfig.getUserName();
    final userEmail = await AppConfig.getUserEmail();
    
    // 构建基础 URL
    String widgetUrl =
        '${AppConfig.chatwootBaseUrl}/widget?website_token=${AppConfig.chatwootWebsiteToken}&locale=zh_CN';

    // 使用服务端支持的URL参数传递HMAC和用户信息
    try {
      final hmacToken = AppConfig.chatwootHmacToken;
      if (hmacToken.isNotEmpty && hmacToken != 'CHATWOOT_HMAC_TOKEN') {
        // 生成 HMAC（基于 email）
        final identifierHash = _generateHMAC(hmacToken, userEmail);
        
        // 服务端新支持的URL参数方式
        widgetUrl += '&identifier=${Uri.encodeComponent(userEmail)}'; // 使用email作为identifier
        widgetUrl += '&identifier_hash=$identifierHash';
        widgetUrl += '&email=${Uri.encodeComponent(userEmail)}';
        widgetUrl += '&name=${Uri.encodeComponent(userName)}';
        
        debugPrint('URL参数方式: identifier=$userEmail, hash=${identifierHash.substring(0, 10)}...');
        debugPrint('用户: $userName <$userEmail>');
      } else {
        debugPrint('[Warning] HMAC token not configured');
      }
    } catch (e) {
      debugPrint('[Error] HMAC generation failed: $e');
    }

    return widgetUrl;
  }

  /// 生成 HMAC-SHA256
  String _generateHMAC(String secret, String message) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(message);
    final hmac = crypto.Hmac(crypto.sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('在线客服'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _webViewController?.reload();
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FutureBuilder<String>(
            future: _webviewURL,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return InAppWebView(
                initialSettings: InAppWebViewSettings(
                  isInspectable: kDebugMode,
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  useHybridComposition: true, // Android 性能优化
                  allowsInlineMediaPlayback: true,
                  mediaPlaybackRequiresUserGesture: false,
                ),
                initialUrlRequest: URLRequest(
                  url: WebUri(snapshot.data!),
                ),
                onWebViewCreated: (controller) async {
                  _webViewController = controller;
                  debugPrint('✅ InAppWebView 已创建');

                  // 仅 Android 平台添加 WebMessageListener
                  if (Platform.isAndroid) {
                    bool isFeatureSupported = true;
                    try {
                      isFeatureSupported = await AndroidWebViewFeature.isFeatureSupported(
                        AndroidWebViewFeature.WEB_MESSAGE_LISTENER,
                      );
                    } catch (e) {
                      debugPrint('⚠️ WebMessageListener 检查失败: $e');
                    }

                    if (isFeatureSupported) {
                      try {
                        await controller.addWebMessageListener(
                          WebMessageListener(
                            jsObjectName: 'ReactNativeWebView',
                            onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) {
                              _handleChatwootMessage(message);
                            },
                          ),
                        );
                        debugPrint('✅ WebMessageListener 已添加');
                      } catch (e) {
                        debugPrint('⚠️ 添加 WebMessageListener 失败: $e');
                      }
                    } else {
                      debugPrint('⚠️ 设备不支持 WebMessageListener');
                    }
                  }
                },
                onLoadStart: (controller, url) {
                  debugPrint('📄 开始加载: $url');
                  if (mounted) {
                    setState(() => _isLoading = true);
                  }
                },
                onLoadStop: (controller, url) async {
                  debugPrint('✅ 加载完成: $url');
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                },
                onLoadError: (controller, url, code, message) {
                  debugPrint('❌ 加载错误: $message');
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                },
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint('📝 Console: ${consoleMessage.message}');
                },
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在加载...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 处理 Chatwoot 消息
  void _handleChatwootMessage(WebMessage? message) {
    if (message == null || message.data == null) return;

    try {
      String content = message.data.toString().replaceFirst('chatwoot-widget:', '');
      dynamic decoded = jsonDecode(content);

      debugPrint('📩 收到 Chatwoot 消息: $decoded');

      // 用户点击关闭按钮
      if (decoded['type'] == 'close-widget') {
        Navigator.of(context).pop();
        return;
      }

      // Widget 加载完成
      if (decoded['event'] == 'loaded') {
        debugPrint('✅ Chatwoot Widget 已加载');
        
        // 保存会话 token
        final authToken = decoded['config']?['authToken'];
        if (authToken != null) {
          StorageUtil.setString('chatwoot_session_token', authToken);
          debugPrint('💾 已保存会话 token');
        }

        // Widget 加载完成后立即设置用户信息和 FCM Token
        // 延迟 500ms 确保 $chatwoot 对象完全初始化
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_webViewController != null) {
            _setUserInfo(_webViewController!);
            _sendFCMTokenToChatwoot(_webViewController!);
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ 处理消息失败: $e');
    }
  }

  /// 设置用户信息
  Future<void> _setUserInfo(InAppWebViewController controller) async {
    try {
      debugPrint('🔧 开始设置用户信息...');
      
      // 获取用户信息
      final userId = await AppConfig.getUserId();
      final userName = await AppConfig.getUserName();
      final userEmail = await AppConfig.getUserEmail();

      debugPrint('👤 用户信息: userId=$userId, name=$userName, email=$userEmail');

      // 等待确保 $chatwoot 对象完全初始化（loaded 事件触发后很快就绪）
      await Future.delayed(const Duration(milliseconds: 100));

      // 转义用户信息中的特殊字符
      final safeUserId = userId.replaceAll("'", "\\'");
      final safeUserName = userName.replaceAll("'", "\\'");
      final safeUserEmail = userEmail.replaceAll("'", "\\'");

      // 通过 JavaScript 设置用户信息
      final jsCode = '''
        (function() {
          try {
            console.log('🔧 尝试设置用户信息...');
            if (window.\$chatwoot) {
              console.log('✅ Chatwoot 对象存在');
              window.\$chatwoot.setUser('$safeUserId', {
                name: '$safeUserName',
                email: '$safeUserEmail'
              });
              console.log('✅ 用户信息已设置: $safeUserName ($safeUserEmail)');
              window.\$chatwoot.setLocale('zh_CN');
            } else {
              console.error('❌ Chatwoot 对象不存在');
            }
          } catch (e) {
            console.error('❌ 设置用户信息失败:', e.toString());
          }
        })();
      ''';

      await controller.evaluateJavascript(source: jsCode);
      debugPrint('✅ JavaScript 已执行');
    } catch (e) {
      debugPrint('⚠️ 设置用户信息失败: $e');
    }
  }

  /// 发送 FCM Token 到 Chatwoot
  Future<void> _sendFCMTokenToChatwoot(InAppWebViewController controller) async {
    try {
      debugPrint('📤 开始发送 FCM Token 到 Chatwoot...');
      
      // 获取 FCM Token
      final firebaseService = FirebaseService();
      final fcmToken = await firebaseService.getCurrentToken();
      
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ FCM Token 不可用，跳过发送');
        return;
      }

      debugPrint('📱 FCM Token: ${fcmToken.substring(0, 20)}...');

      // 等待确保 $chatwoot 对象完全初始化
      await Future.delayed(const Duration(milliseconds: 100));

      // 转义 Token 中的特殊字符
      final safeToken = fcmToken.replaceAll("'", "\\'");

      // 通过 JavaScript 将 Token 发送给 Chatwoot
      final jsCode = '''
        (function() {
          try {
            console.log('📤 尝试发送 FCM Token 到 Chatwoot...');
            if (window.\$chatwoot && window.\$chatwoot.setCustomAttributes) {
              // 使用自定义属性保存 FCM Token
              window.\$chatwoot.setCustomAttributes({
                fcm_token: '$safeToken',
                push_platform: 'android'
              });
              console.log('✅ FCM Token 已发送');
            } else if (window.\$chatwoot) {
              console.warn('⚠️ setCustomAttributes 方法不可用');
            } else {
              console.error('❌ Chatwoot 对象不存在');
            }
          } catch (e) {
            console.error('❌ 发送 FCM Token 失败:', e.toString());
          }
        })();
      ''';

      await controller.evaluateJavascript(source: jsCode);
      debugPrint('✅ FCM Token 已发送到 Chatwoot');
    } catch (e) {
      debugPrint('⚠️ 发送 FCM Token 失败: $e');
    }
  }
}
