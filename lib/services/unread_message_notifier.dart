import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 未读消息通知管理器
/// 
/// 用于管理聊天未读消息的状态，支持持久化存储
class UnreadMessageNotifier extends ChangeNotifier {
  int _unreadCount = 0;
  
  /// 获取未读消息数量
  int get unreadCount => _unreadCount;
  
  /// 是否有未读消息
  bool get hasUnread => _unreadCount > 0;
  
  /// 初始化 - 从本地存储加载未读数
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _unreadCount = prefs.getInt('unread_message_count') ?? 0;
      notifyListeners();
      debugPrint('📊 未读消息已加载: $_unreadCount');
    } catch (e) {
      debugPrint('❌ 加载未读消息数失败: $e');
    }
  }
  
  /// 增加未读消息数
  Future<void> incrementUnread() async {
    _unreadCount++;
    await _saveToStorage();
    notifyListeners();
    debugPrint('📊 未读消息数: $_unreadCount');
  }
  
  /// 清除未读消息数
  Future<void> clearUnread() async {
    if (_unreadCount == 0) return; // 已经是0，不需要操作
    
    _unreadCount = 0;
    await _saveToStorage();
    notifyListeners();
    debugPrint('🧹 未读消息已清除');
  }
  
  /// 保存到本地存储
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_message_count', _unreadCount);
    } catch (e) {
      debugPrint('❌ 保存未读消息数失败: $e');
    }
  }
}
