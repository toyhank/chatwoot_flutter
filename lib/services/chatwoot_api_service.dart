import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chatwoot_message.dart';
import '../config/app_config.dart';

/// Chatwoot API 服务
/// 参考: https://github.com/chatwoot/client-api-demo
class ChatwootApiService {
  final String baseUrl;
  final String inboxIdentifier;

  ChatwootApiService({
    required this.baseUrl,
    required this.inboxIdentifier,
  });

  /// 从配置创建服务实例
  factory ChatwootApiService.fromConfig() {
    return ChatwootApiService(
      baseUrl: AppConfig.chatwootBaseUrl,
      inboxIdentifier: AppConfig.chatwootWebsiteToken,
    );
  }

  /// API 基础 URL
  String get apiBaseUrl => '$baseUrl/public/api/v1';

  /// 创建联系人
  /// POST /public/api/v1/inboxes/{inboxIdentifier}/contacts
  Future<ChatwootContact> createContact({
    String? name,
    String? email,
    String? phoneNumber,
    Map<String, dynamic>? customAttributes,
  }) async {
    try {
      final url = '$apiBaseUrl/inboxes/$inboxIdentifier/contacts';
      debugPrint('📞 创建联系人: $url');

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (customAttributes != null) body['custom_attributes'] = customAttributes;

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ 联系人创建成功: ${data['source_id']}');
        return ChatwootContact.fromJson(data);
      } else {
        debugPrint('❌ 创建联系人失败: ${response.statusCode} ${response.body}');
        throw Exception('Failed to create contact: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 创建联系人异常: $e');
      rethrow;
    }
  }

  /// 创建会话
  /// POST /public/api/v1/inboxes/{inboxIdentifier}/contacts/{contactIdentifier}/conversations
  Future<ChatwootConversation> createConversation({
    required String contactIdentifier,
    Map<String, dynamic>? customAttributes,
  }) async {
    try {
      final url = '$apiBaseUrl/inboxes/$inboxIdentifier/contacts/$contactIdentifier/conversations';
      debugPrint('💬 创建会话: $url');

      final body = <String, dynamic>{};
      if (customAttributes != null) body['custom_attributes'] = customAttributes;

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ 会话创建成功: ${data['id']}');
        return ChatwootConversation.fromJson(data);
      } else {
        debugPrint('❌ 创建会话失败: ${response.statusCode} ${response.body}');
        throw Exception('Failed to create conversation: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 创建会话异常: $e');
      rethrow;
    }
  }

  /// 发送消息
  /// POST /public/api/v1/inboxes/{inboxIdentifier}/contacts/{contactIdentifier}/conversations/{conversationId}/messages
  Future<ChatwootMessage> sendMessage({
    required String contactIdentifier,
    required int conversationId,
    required String content,
  }) async {
    try {
      final url = '$apiBaseUrl/inboxes/$inboxIdentifier/contacts/$contactIdentifier/conversations/$conversationId/messages';
      debugPrint('📤 发送消息: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ 消息发送成功');
        return ChatwootMessage.fromJson(data);
      } else {
        debugPrint('❌ 发送消息失败: ${response.statusCode} ${response.body}');
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 发送消息异常: $e');
      rethrow;
    }
  }

  /// 获取会话消息列表
  /// GET /public/api/v1/inboxes/{inboxIdentifier}/contacts/{contactIdentifier}/conversations/{conversationId}/messages
  Future<List<ChatwootMessage>> getMessages({
    required String contactIdentifier,
    required int conversationId,
  }) async {
    try {
      final url = '$apiBaseUrl/inboxes/$inboxIdentifier/contacts/$contactIdentifier/conversations/$conversationId/messages';
      debugPrint('📥 获取消息列表: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        debugPrint('✅ 获取到 ${data.length} 条消息');
        return data.map((m) => ChatwootMessage.fromJson(m)).toList();
      } else {
        debugPrint('❌ 获取消息失败: ${response.statusCode}');
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 获取消息异常: $e');
      rethrow;
    }
  }

  /// 获取会话详情
  /// GET /public/api/v1/inboxes/{inboxIdentifier}/contacts/{contactIdentifier}/conversations/{conversationId}
  Future<ChatwootConversation> getConversation({
    required String contactIdentifier,
    required int conversationId,
  }) async {
    try {
      final url = '$apiBaseUrl/inboxes/$inboxIdentifier/contacts/$contactIdentifier/conversations/$conversationId';
      debugPrint('📋 获取会话详情: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ 获取会话详情成功');
        return ChatwootConversation.fromJson(data);
      } else {
        debugPrint('❌ 获取会话详情失败: ${response.statusCode}');
        throw Exception('Failed to get conversation: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 获取会话详情异常: $e');
      rethrow;
    }
  }
}







