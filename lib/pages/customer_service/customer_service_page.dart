import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/app_config.dart';
import '../../utils/storage_util.dart';

// Web平台专用导入
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

/// Chatwoot 客服页面
/// 参考: https://medium.com/@mehulcs/chatwoot-integration-in-flutter-without-a-third-party-package-e8a5d114dec3
class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _webViewId = 'chatwoot-iframe-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// 初始化 WebView（参考 Medium 文章方法）
  Future<void> _initializeWebView() async {
    if (kIsWeb) {
      // Web 平台直接注入脚本
      await _injectChatwootForWeb();
      return;
    }

    try {
      // 获取用户信息
      final userId = await StorageUtil.getString('userId') ?? 
          'guest_${DateTime.now().millisecondsSinceEpoch}';
      final userName = await StorageUtil.getString('userName') ?? 'Guest';
      final userEmail = await StorageUtil.getString('userEmail') ?? 
          'guest@example.com';

      // 创建 WebView 控制器
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              debugPrint('📄 页面开始加载: $url');
            },
            onPageFinished: (String url) {
              debugPrint('✅ 页面加载完成');
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('❌ 资源加载错误: ${error.description}');
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = '加载失败: ${error.description}';
                  _isLoading = false;
                });
              }
            },
          ),
        );

      // 生成 HTML 内容
      final html = _generateChatwootHTML(
        baseUrl: AppConfig.chatwootBaseUrl,
        websiteToken: AppConfig.chatwootWebsiteToken,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
      );

      // 加载 HTML
      await _controller.loadHtmlString(html);
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ 初始化失败: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 生成 Chatwoot HTML（使用 SDK 强制保持展开状态）
  String _generateChatwootHTML({
    required String baseUrl,
    required String websiteToken,
    required String userId,
    required String userName,
    required String userEmail,
  }) {
    // 转义字符串以防止 XSS
    final safeUserName = _escapeHtml(userName);
    final safeUserEmail = _escapeHtml(userEmail);
    final safeUserId = _escapeHtml(userId);

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>客服支持</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    html, body {
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: #fff;
    }
    
    /* 隐藏 Chatwoot 的浮动按钮，只显示聊天窗口 */
    .woot-widget-bubble {
      display: none !important;
    }
    
    /* 让聊天窗口占满整个屏幕 */
    .woot--bubble-holder {
      bottom: 0 !important;
      right: 0 !important;
      width: 100% !important;
      height: 100% !important;
      max-height: 100% !important;
    }
    
    .woot-widget-holder {
      width: 100% !important;
      height: 100% !important;
      max-height: 100% !important;
      box-shadow: none !important;
      border-radius: 0 !important;
    }
    
    iframe.woot-widget {
      width: 100% !important;
      height: 100% !important;
      max-height: 100% !important;
    }
    
    #loading {
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      text-align: center;
      font-family: system-ui, -apple-system, sans-serif;
      z-index: 99999;
      background: #fff;
      padding: 20px;
      border-radius: 8px;
    }
    
    .spinner {
      width: 40px;
      height: 40px;
      border: 4px solid #e0e0e0;
      border-top-color: #1f93ff;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
      margin: 0 auto 16px;
    }
    
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
    
    #loading.hide {
      display: none;
    }
  </style>
</head>
<body>
  <div id="loading">
    <div class="spinner"></div>
    <p style="color: #666;">正在连接客服...</p>
  </div>

  <script>
    (function(d,t) {
      var BASE_URL = "$baseUrl";
      var g = d.createElement(t), s = d.getElementsByTagName(t)[0];
      g.src = BASE_URL + "/packs/js/sdk.js";
      g.defer = true;
      g.async = true;
      
      g.onload = function() {
        console.log('✅ Chatwoot SDK 加载成功');
        
        // 初始化 Chatwoot
        window.chatwootSDK.run({
          websiteToken: '$websiteToken',
          baseUrl: BASE_URL
        });
        
        // 等待 Chatwoot 就绪
        window.addEventListener('chatwoot:ready', function() {
          console.log('✅ Chatwoot 就绪');
          
          // 设置用户信息
          window.\$chatwoot.setUser('$safeUserId', {
            name: '$safeUserName',
            email: '$safeUserEmail'
          });
          
          // 设置语言
          window.\$chatwoot.setLocale('zh_CN');
          
          // 强制打开并保持展开状态
          window.\$chatwoot.toggle('open');
          
          // 隐藏加载动画
          setTimeout(function() {
            document.getElementById('loading').classList.add('hide');
          }, 500);
          
          console.log('💬 聊天窗口已强制展开');
        });
        
        // 监听所有 Chatwoot 事件，防止窗口关闭
        window.addEventListener('chatwoot:on-message', function() {
          // 确保窗口始终打开
          if (window.\$chatwoot && window.\$chatwoot.isOpen && !window.\$chatwoot.isOpen()) {
            window.\$chatwoot.toggle('open');
            console.log('🔄 检测到窗口关闭，重新打开');
          }
        });
        
        // 定期检查并保持窗口打开（每2秒检查一次）
        setInterval(function() {
          if (window.\$chatwoot && window.\$chatwoot.isOpen && !window.\$chatwoot.isOpen()) {
            window.\$chatwoot.toggle('open');
            console.log('🔄 定期检查：重新打开聊天窗口');
          }
        }, 2000);
      };
      
      g.onerror = function() {
        console.error('❌ SDK 加载失败');
        document.getElementById('loading').innerHTML = 
          '<p style="color: #f44336;">无法连接到客服系统<br>请检查网络连接</p>';
      };
      
      s.parentNode.insertBefore(g, s);
    })(document, "script");
  </script>
</body>
</html>
    ''';
  }

  /// HTML 转义，防止 XSS 攻击
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Web 平台：注册 iframe 视图（使用 SDK 方式）
  Future<void> _injectChatwootForWeb() async {
    try {
      final userId = await StorageUtil.getString('userId') ?? 
          'guest_${DateTime.now().millisecondsSinceEpoch}';
      final userName = await StorageUtil.getString('userName') ?? 'Guest';
      final userEmail = await StorageUtil.getString('userEmail') ?? 
          'guest@example.com';

      // 生成完整的HTML内容
      final htmlContent = _generateChatwootHTML(
        baseUrl: AppConfig.chatwootBaseUrl,
        websiteToken: AppConfig.chatwootWebsiteToken,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
      );

      // 注册平台视图
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _webViewId,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..srcdoc = htmlContent
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allow = 'microphone; camera; clipboard-write;';
          
          return iframe;
        },
      );

      debugPrint('✅ Chatwoot SDK 视图已注册');
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Web平台初始化失败: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('在线客服'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: !kIsWeb ? [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _initializeWebView();
            },
          ),
        ] : null,
      ),
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 错误状态
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                '无法连接到客服系统',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isLoading = true;
                  });
                  _initializeWebView();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConfig.primaryColor),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Web 平台：使用 HtmlElementView 显示 iframe
    if (kIsWeb) {
      if (_isLoading) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在加载客服系统...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }
      
      return HtmlElementView(viewType: _webViewId);
    }

    // 移动端：WebView
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
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
    );
  }
}
