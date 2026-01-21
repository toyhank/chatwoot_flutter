import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/push_notification_service.dart';
import '../config/app_config.dart';

/// 推送通知测试页面
/// 
/// 用于手动测试和验证推送通知功能
class PushTestPage extends StatefulWidget {
  const PushTestPage({super.key});

  @override
  State<PushTestPage> createState() => _PushTestPageState();
}

class _PushTestPageState extends State<PushTestPage> {
  String _status = '准备就绪';
  String? _fcmToken;
  bool? _isRegistered;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final token = PushNotificationService.fcmToken;
    final registered = await PushNotificationService.isRegistered();
    
    setState(() {
      _fcmToken = token;
      _isRegistered = registered;
      _status = registered 
          ? '✅ Token 已注册到 Chatwoot' 
          : '⚠️ Token 未注册';
    });
  }

  Future<void> _copyToken() async {
    if (_fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Token 已复制到剪贴板')),
      );
      debugPrint('📋 FCM Token: $_fcmToken');
    }
  }

  Future<void> _registerPush() async {
    setState(() => _status = '正在注册...');

    try {
      final email = await AppConfig.getUserEmail();
      final name = await AppConfig.getUserName();

      if (email.isEmpty) {
        setState(() => _status = '❌ 未获取到用户邮箱');
        return;
      }

      final success = await PushNotificationService.registerPushToken(
        contactIdentifier: email,
        name: name,
        email: email,
      );

      setState(() {
        _status = success ? '✅ 注册成功' : '❌ 注册失败';
        _isRegistered = success;
      });
    } catch (e) {
      setState(() => _status = '❌ 错误: $e');
    }
  }

  Future<void> _unregisterPush() async {
    setState(() => _status = '正在取消注册...');

    final success = await PushNotificationService.unregisterPushToken();
    
    setState(() {
      _status = success ? '✅ 已取消注册' : '❌ 取消失败';
      _isRegistered = !success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('推送测试'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态显示
            Card(
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 状态',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(_status, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    if (_isRegistered != null)
                      Text(
                        _isRegistered! 
                            ? '✅ 已注册到 Chatwoot' 
                            : '❌ 未注册到 Chatwoot',
                        style: TextStyle(
                          color: _isRegistered! ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // FCM Token 显示
            if (_fcmToken != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '🔑 FCM Token',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: _copyToken,
                            tooltip: '复制 Token',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _fcmToken!.substring(0, 50) + '...',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 操作按钮
            ElevatedButton.icon(
              onPressed: _loadInfo,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新状态'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _fcmToken != null ? _copyToken : null,
              icon: const Icon(Icons.copy),
              label: const Text('复制 FCM Token'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _registerPush,
              icon: const Icon(Icons.send),
              label: const Text('手动注册推送'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _unregisterPush,
              icon: const Icon(Icons.cancel),
              label: const Text('取消推送注册'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // 说明文字
            const Divider(),
            const SizedBox(height: 12),
            Text(
              '💡 使用说明',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. 点击"复制 FCM Token"将 Token 复制到剪贴板\n'
              '2. 前往 Firebase Console → Messaging\n'
              '3. 选择 "Send test message"\n'
              '4. 粘贴 Token 并发送测试推送\n\n'
              '如果收到测试推送，说明配置成功！',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
