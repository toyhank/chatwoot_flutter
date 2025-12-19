/// Chatwoot 消息模型
class ChatwootMessage {
  final int id;
  final String content;
  final int messageType; // 0: incoming, 1: outgoing, 2: activity
  final DateTime createdAt;
  final String? senderName;
  final int? senderId;
  final Map<String, dynamic>? attachments;

  ChatwootMessage({
    required this.id,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.senderName,
    this.senderId,
    this.attachments,
  });

  /// 从 JSON 创建消息
  factory ChatwootMessage.fromJson(Map<String, dynamic> json) {
    return ChatwootMessage(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      senderName: json['sender']?['name'],
      senderId: json['sender']?['id'],
      attachments: json['attachments'],
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
      'sender_name': senderName,
      'sender_id': senderId,
      'attachments': attachments,
    };
  }

  /// 是否是用户发送的消息
  bool get isUserMessage => messageType == 0;

  /// 是否是客服发送的消息
  bool get isAgentMessage => messageType == 1;

  /// 是否是系统消息
  bool get isActivityMessage => messageType == 2;
}

/// Chatwoot 联系人信息
class ChatwootContact {
  final String sourceId;
  final String pubsubToken;
  final String? name;
  final String? email;

  ChatwootContact({
    required this.sourceId,
    required this.pubsubToken,
    this.name,
    this.email,
  });

  factory ChatwootContact.fromJson(Map<String, dynamic> json) {
    return ChatwootContact(
      sourceId: json['source_id'] ?? json['id']?.toString() ?? '',
      pubsubToken: json['pubsub_token'] ?? '',
      name: json['name'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_id': sourceId,
      'pubsub_token': pubsubToken,
      'name': name,
      'email': email,
    };
  }
}

/// Chatwoot 会话信息
class ChatwootConversation {
  final int id;
  final String? status;
  final List<ChatwootMessage> messages;

  ChatwootConversation({
    required this.id,
    this.status,
    this.messages = const [],
  });

  factory ChatwootConversation.fromJson(Map<String, dynamic> json) {
    return ChatwootConversation(
      id: json['id'] ?? 0,
      status: json['status'],
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatwootMessage.fromJson(m))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }
}







