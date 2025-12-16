import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/app_config.dart';
import '../../utils/storage_util.dart';

// Web平台专用导入
import 'dart:html' as html show document, ScriptElement;
import 'dart:js' as js;

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

  /// 生成 Chatwoot HTML（核心方法，来自 Medium 文章）
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
      background: #f5f5f5;
    }
    
    #loading {
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      text-align: center;
      font-family: system-ui, -apple-system, sans-serif;
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
    <p>正在连接客服...</p>
  </div>

  <script>
    // Chatwoot 配置
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
          
          // 设置语言为中文
          window.\$chatwoot.setLocale('zh_CN');
          
          // 自动打开聊天窗口
          setTimeout(function() {
            window.\$chatwoot.toggle('open');
            document.getElementById('loading').classList.add('hide');
          }, 300);
        });
        
        // 错误处理
        window.addEventListener('chatwoot:error', function(error) {
          console.error('❌ Chatwoot 错误:', error);
          alert('客服系统加载失败，请稍后重试');
        });
      };
      
      g.onerror = function() {
        console.error('❌ SDK 加载失败');
        alert('无法连接到客服系统');
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

  /// Web 平台：直接注入 Chatwoot 脚本
  Future<void> _injectChatwootForWeb() async {
    try {
      final userId = await StorageUtil.getString('userId') ?? 
          'guest_${DateTime.now().millisecondsSinceEpoch}';
      final userName = await StorageUtil.getString('userName') ?? 'Guest';
      final userEmail = await StorageUtil.getString('userEmail') ?? 
          'guest@example.com';

      // 检查是否已经注入
      if (html.document.getElementById('chatwoot-sdk') != null) {
        debugPrint('⚠️ Chatwoot SDK 已存在');
        try {
          js.context.callMethod('eval', ["window.\$chatwoot?.toggle('open');"]);
        } catch (e) {
          debugPrint('打开失败: $e');
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 加载 SDK
      final script = html.ScriptElement()
        ..id = 'chatwoot-sdk'
        ..src = '${AppConfig.chatwootBaseUrl}/packs/js/sdk.js'
        ..defer = true
        ..async = true;

      script.onLoad.listen((_) {
        final initScript = html.ScriptElement()
          ..text = '''
            window.chatwootSDK.run({
              websiteToken: '${AppConfig.chatwootWebsiteToken}',
              baseUrl: '${AppConfig.chatwootBaseUrl}'
            });
            
            window.addEventListener('chatwoot:ready', function() {
              window.\$chatwoot.setUser('$userId', {
                name: '$userName',
                email: '$userEmail'
              });
              window.\$chatwoot.setLocale('zh_CN');
              window.\$chatwoot.toggle('open');
            });
          ''';
        html.document.body?.append(initScript);
        if (mounted) setState(() => _isLoading = false);
      });

      script.onError.listen((_) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = '无法加载客服系统';
            _isLoading = false;
          });
        }
      });

      html.document.body?.append(script);
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

    // Web 平台
    if (kIsWeb) {
      return Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    '正在加载客服系统...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              )
            : Text(
                '客服窗口已打开\n请查看页面右下角',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
      );
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
