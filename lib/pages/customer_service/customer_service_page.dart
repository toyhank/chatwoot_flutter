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
        title: const Text('Customer Service'),
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

        // 注意：用户身份已通过 URL 参数（HMAC）传递给 Widget
        // 推送订阅已通过 HTTP API 在 main.dart 中注册
        // 不需要使用 JavaScript 调用 $chatwoot 对象
      }
    } catch (e) {
      debugPrint('⚠️ 处理消息失败: $e');
    }
  }
}
