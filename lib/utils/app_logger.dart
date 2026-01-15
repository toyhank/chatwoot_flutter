import 'package:talker_flutter/talker_flutter.dart';

/// 全局日志管理器
/// 
/// 使用 Talker 提供统一的日志记录和查看功能
class AppLogger {
  static final Talker _talker = TalkerFlutter.init(
    settings: TalkerSettings(
      useConsoleLogs: false,
    ),
  );

  /// 获取 Talker 实例
  static Talker get instance => _talker;

  /// 调试日志
  static void debug(String message) {
    _talker.debug(message);
  }

  /// 信息日志
  static void info(String message) {
    _talker.info(message);
  }

  /// 警告日志
  static void warning(String message) {
    _talker.warning(message);
  }

  /// 错误日志
  static void error(String message, [Object? exception, StackTrace? stackTrace]) {
    _talker.error(message, exception, stackTrace);
  }

  /// 关键错误日志
  static void critical(String message, [Object? exception, StackTrace? stackTrace]) {
    _talker.critical(message, exception, stackTrace);
  }

  /// 记录HTTP请求
  static void logRequest(String url, String method, {Map<String, dynamic>? data}) {
    _talker.logTyped(TalkerLog('📤 $method $url ${data != null ? '\nData: $data' : ''}'));
  }

  /// 记录HTTP响应
  static void logResponse(String url, int statusCode, {dynamic data}) {
    _talker.logTyped(TalkerLog('📥 $statusCode $url ${data != null ? '\nResponse: $data' : ''}'));
  }
}
