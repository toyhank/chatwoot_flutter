import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chatwoot_message.dart';

/// Chatwoot WebSocket 服务
/// 参考: https://github.com/chatwoot/client-api-demo
class ChatwootWebSocketService {
  final String baseUrl;
  final String pubsubToken;

  WebSocketChannel? _channel;
  StreamController<ChatwootMessage>? _messageController;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  ChatwootWebSocketService({
    required this.baseUrl,
    required this.pubsubToken,
  });

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 消息流
  Stream<ChatwootMessage>? get messageStream => _messageController?.stream;

  /// WebSocket URL (去掉 http/https 协议,改为 ws/wss)
  String get _webSocketUrl {
    final url = baseUrl.replaceAll('https://', 'wss://').replaceAll('http://', 'ws://');
    return '$url/cable';
  }

  /// 连接 WebSocket
  Future<void> connect() async {
    if (_isConnected) {
      debugPrint('⚠️ WebSocket 已连接');
      return;
    }

    try {
      debugPrint('🔌 正在连接 WebSocket: $_webSocketUrl');

      // 创建消息流控制器
      _messageController ??= StreamController<ChatwootMessage>.broadcast();

      // 连接 WebSocket
      _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));

      // 监听连接状态
      _channel!.ready.then((_) {
        debugPrint('✅ WebSocket 连接成功');
        _isConnected = true;
        _reconnectAttempts = 0;

        // 订阅频道
        _subscribeToChannel();
      }).catchError((error) {
        debugPrint('❌ WebSocket 连接失败: $error');
        _handleConnectionError();
      });

      // 监听消息
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('❌ WebSocket 错误: $error');
          _handleConnectionError();
        },
        onDone: () {
          debugPrint('⚠️ WebSocket 连接关闭');
          _isConnected = false;
          _handleConnectionError();
        },
      );
    } catch (e) {
      debugPrint('❌ WebSocket 连接异常: $e');
      _handleConnectionError();
      rethrow;
    }
  }

  /// 订阅频道
  void _subscribeToChannel() {
    final subscribeMessage = {
      'command': 'subscribe',
      'identifier': jsonEncode({
        'channel': 'RoomChannel',
        'pubsub_token': pubsubToken,
      }),
    };

    debugPrint('📡 订阅频道: $pubsubToken');
    _channel?.sink.add(jsonEncode(subscribeMessage));
  }

  /// 处理收到的消息
  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data.toString());
      final type = json['type'] as String?;

      if (type == 'welcome') {
        debugPrint('👋 收到欢迎消息');
      } else if (type == 'ping') {
        // 忽略 ping 消息
      } else if (type == 'confirm_subscription') {
        debugPrint('✅ 订阅确认');
      } else if (json['message'] != null) {
        final message = json['message'];
        final event = message['event'] as String?;

        if (event == 'message.created') {
          debugPrint('📨 收到新消息');
          final messageData = message['data'];
          final messageType = messageData['message_type'] as int;

          // 只处理客服发送的消息 (message_type = 1)
          if (messageType == 1) {
            final chatMessage = ChatwootMessage.fromJson(messageData);
            _messageController?.add(chatMessage);
          }
        } else if (event == 'conversation.created') {
          debugPrint('💬 会话已创建');
        } else if (event == 'conversation.status_changed') {
          debugPrint('🔄 会话状态变更');
        }
      } else {
        debugPrint('❓ 未知消息类型: $json');
      }
    } catch (e) {
      debugPrint('❌ 消息处理错误: $e');
    }
  }

  /// 处理连接错误（自动重连）
  void _handleConnectionError() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ 达到最大重连次数，停止重连');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    debugPrint('🔄 将在 ${delay.inSeconds} 秒后重连（第 $_reconnectAttempts 次）');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      debugPrint('🔄 开始重连...');
      connect();
    });
  }

  /// 断开连接
  Future<void> disconnect() async {
    debugPrint('🔌 断开 WebSocket 连接');
    _isConnected = false;
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }

  /// 清理资源
  void dispose() {
    disconnect();
    _messageController?.close();
    _messageController = null;
  }
}







