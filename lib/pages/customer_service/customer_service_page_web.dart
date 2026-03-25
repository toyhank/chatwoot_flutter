import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart' as crypto;
import '../../config/app_config.dart';

/// Chatwoot 客服页面 - Web端实现（使用 IFrame）
class CustomerServicePageImpl extends StatefulWidget {
  const CustomerServicePageImpl({super.key});

  @override
  State<CustomerServicePageImpl> createState() => _CustomerServicePageImplState();
}

class _CustomerServicePageImplState extends State<CustomerServicePageImpl> {
  late final String _iframeViewType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 生成唯一的视图类型ID
    _iframeViewType = 'chatwoot-iframe-${DateTime.now().millisecondsSinceEpoch}';
    
    // 立即同步注册iframe
    _registerWebIframe();
    
    // 设置一个超时来隐藏loading，防止iframe.onLoad不触发
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        print('⏱️ 超时隐藏loading');
        setState(() => _isLoading = false);
      }
    });
  }

  /// Web平台：注册 iframe (同步执行)
  void _registerWebIframe() {
    print('🌐 开始注册Web iframe');
    
    // 创建 iframe 元素（暂时使用空src，稍后更新）
    final iframe = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'microphone; camera; geolocation';
    
    // 注册视图工厂
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _iframeViewType,
      (int viewId) {
        print('📦 创建iframe视图 ID: $viewId');
        return iframe;
      },
    );

    // 监听iframe加载事件
    iframe.onLoad.listen((event) {
      print('✅ Chatwoot iframe onLoad触发');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });

    iframe.onError.listen((event) {
      print('❌ Chatwoot iframe onError触发');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });

    // 异步加载URL并设置src
    _buildWebviewURL().then((url) {
      print('🔗 设置iframe src: $url');
      iframe.src = url;
    }).catchError((e) {
      print('❌ 构建URL失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  /// 构建 Chatwoot widget URL
  Future<String> _buildWebviewURL() async {
    // 获取用户信息
    final userId = await AppConfig.getUserId();
    final userName = await AppConfig.getUserName();
    final userEmail = await AppConfig.getUserEmail();
    
    // 构建基础 URL
    String widgetUrl =
        '${AppConfig.chatwootBaseUrl}/widget?website_token=${AppConfig.chatwootWebsiteToken}&locale=en';

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
              // Web平台刷新最简单的方式：重新加载整个Flutter app
              html.window.location.reload();
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          HtmlElementView(
            viewType: _iframeViewType,
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
                    Text('Loading Chat...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
