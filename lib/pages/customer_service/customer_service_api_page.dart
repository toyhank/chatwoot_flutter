import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/chatwoot_message.dart';
import '../../services/chatwoot_api_service.dart';
import '../../services/chatwoot_websocket_service.dart';
import '../../utils/storage_util.dart';

/// 基于 API 的 Chatwoot 客服页面
/// 参考: https://github.com/chatwoot/client-api-demo
class CustomerServiceApiPage extends StatefulWidget {
  const CustomerServiceApiPage({super.key});

  @override
  State<CustomerServiceApiPage> createState() => _CustomerServiceApiPageState();
}

class _CustomerServiceApiPageState extends State<CustomerServiceApiPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatwootMessage> _messages = [];

  late ChatwootApiService _apiService;
  ChatwootWebSocketService? _wsService;

  ChatwootContact? _contact;
  ChatwootConversation? _conversation;

  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeChatwoot();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _wsService?.dispose();
    super.dispose();
  }

  /// 初始化 Chatwoot
  Future<void> _initializeChatwoot() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. 创建 API 服务
      _apiService = ChatwootApiService.fromConfig();

      // 2. 检查是否有缓存的联系人信息
      final cachedContactId = await StorageUtil.getString('chatwoot_contact_id');
      final cachedPubsubToken = await StorageUtil.getString('chatwoot_pubsub_token');
      final cachedConversationId = await StorageUtil.getString('chatwoot_conversation_id');

      if (cachedContactId != null && cachedPubsubToken != null) {
        // 使用缓存的联系人
        debugPrint('📌 使用缓存的联系人: $cachedContactId');
        _contact = ChatwootContact(
          sourceId: cachedContactId,
          pubsubToken: cachedPubsubToken,
        );

        // 使用缓存的会话
        if (cachedConversationId != null) {
          debugPrint('📌 使用缓存的会话: $cachedConversationId');
          _conversation = ChatwootConversation(id: int.parse(cachedConversationId));

          // 加载历史消息
          await _loadMessages();
        }
      } else {
        // 创建新联系人
        await _createContact();
      }

      // 3. 创建会话（如果没有）
      if (_conversation == null) {
        await _createConversation();
      }

      // 4. 连接 WebSocket
      await _connectWebSocket();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ 初始化失败: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '初始化失败: $e';
      });
    }
  }

  /// 创建联系人
  Future<void> _createContact() async {
    debugPrint('👤 创建新联系人...');

    final userName = await StorageUtil.getString('userName') ?? AppConfig.defaultUserName;
    final userEmail = await StorageUtil.getString('userEmail') ?? AppConfig.defaultUserEmail;

    _contact = await _apiService.createContact(
      name: userName,
      email: userEmail,
    );

    // 缓存联系人信息
    await StorageUtil.setString('chatwoot_contact_id', _contact!.sourceId);
    await StorageUtil.setString('chatwoot_pubsub_token', _contact!.pubsubToken);

    debugPrint('✅ 联系人已创建: ${_contact!.sourceId}');
  }

  /// 创建会话
  Future<void> _createConversation() async {
    if (_contact == null) return;

    debugPrint('💬 创建新会话...');

    _conversation = await _apiService.createConversation(
      contactIdentifier: _contact!.sourceId,
    );

    // 缓存会话信息
    await StorageUtil.setString('chatwoot_conversation_id', _conversation!.id.toString());

    debugPrint('✅ 会话已创建: ${_conversation!.id}');
  }

  /// 连接 WebSocket
  Future<void> _connectWebSocket() async {
    if (_contact == null) return;

    _wsService?.dispose();
    _wsService = ChatwootWebSocketService(
      baseUrl: _apiService.baseUrl,
      pubsubToken: _contact!.pubsubToken,
    );

    await _wsService!.connect();

    // 监听新消息
    _wsService!.messageStream?.listen((message) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    });
  }

  /// 加载历史消息
  Future<void> _loadMessages() async {
    if (_contact == null || _conversation == null) return;

    try {
      final messages = await _apiService.getMessages(
        contactIdentifier: _contact!.sourceId,
        conversationId: _conversation!.id,
      );

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ 加载消息失败: $e');
    }
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    if (_contact == null || _conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('会话未就绪，请稍后重试')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // 先添加到本地列表（乐观更新）
      final localMessage = ChatwootMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        content: content,
        messageType: 0, // 用户消息
        createdAt: DateTime.now(),
        senderName: 'me',
      );

      setState(() {
        _messages.add(localMessage);
        _messageController.clear();
      });
      _scrollToBottom();

      // 发送到服务器
      await _apiService.sendMessage(
        contactIdentifier: _contact!.sourceId,
        conversationId: _conversation!.id,
        content: content,
      );

      debugPrint('✅ 消息发送成功');
    } catch (e) {
      debugPrint('❌ 发送消息失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  /// 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('在线客服'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_wsService?.isConnected == true)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    SizedBox(width: 4),
                    Text('在线', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _initializeChatwoot,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 加载中
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在连接客服...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 错误状态
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                '连接失败',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeChatwoot,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // 聊天界面
    return Column(
      children: [
        // 消息列表
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Text(
                    '开始对话吧！',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageItem(_messages[index]);
                  },
                ),
        ),

        // 输入框
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(ChatwootMessage message) {
    final isUserMessage = message.isUserMessage;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.support_agent, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isUserMessage && message.senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUserMessage ? Colors.black : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUserMessage ? Colors.white : Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (isUserMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} 小时前';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}







