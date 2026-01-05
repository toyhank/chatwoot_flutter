import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:crypto/crypto.dart' as crypto;
import '../../config/app_config.dart';
import '../../utils/storage_util.dart';

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

    // 生成 HMAC 并构建用户数据
    try {
      final hmacToken = AppConfig.chatwootHmacToken;
      if (hmacToken.isNotEmpty && hmacToken != 'CHATWOOT_HMAC_TOKEN') {
        // 生成 HMAC（基于 email，与 Chatwoot 后台设置一致）
        final identifierHash = _generateHMAC(hmacToken, userEmail);
        
        // 构建包含用户信息和 HMAC 的 JSON 对象（按照官方格式）
        final userData = {
          'identifier_hash': identifierHash,  // HMAC 签名
          'user_id': userId,                   // 用户 ID
          'email': userEmail,                  // 邮箱
          'name': userName,                    // 姓名
          // 'avatar_url': '...',              // 可选：头像 URL
        };
        
        // 转换为 JSON 字符串
        final jsonString = jsonEncode(userData);
        
        // Base64 编码
        final base64Encoded = base64Encode(utf8.encode(jsonString));
        
        // 添加到 URL
        widgetUrl = '$widgetUrl&cw_conversation=$base64Encoded';
        
        debugPrint('🔐 已添加 HMAC 用户信息 (基于email): $userName <$userEmail>');
        debugPrint('📦 Base64: ${base64Encoded.substring(0, 50)}...');
      } else {
        debugPrint('⚠️ HMAC token 未配置，使用无鉴权模式');
      }
    } catch (e) {
      debugPrint('⚠️ 生成用户数据失败: $e');
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

        // Widget 加载完成后立即设置用户信息
        // 延迟 500ms 确保 $chatwoot 对象完全初始化
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_webViewController != null) {
            _setUserInfo(_webViewController!);
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
}
