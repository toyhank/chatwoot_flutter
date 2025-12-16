import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储工具类
class StorageUtil {
  static SharedPreferences? _prefs;
  
  /// 初始化
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// 保存字符串
  static Future<bool> setString(String key, String value) async {
    return await _prefs!.setString(key, value);
  }
  
  /// 获取字符串
  static Future<String?> getString(String key) async {
    return _prefs!.getString(key);
  }
  
  /// 保存整数
  static Future<bool> setInt(String key, int value) async {
    return await _prefs!.setInt(key, value);
  }
  
  /// 获取整数
  static Future<int?> getInt(String key) async {
    return _prefs!.getInt(key);
  }
  
  /// 保存布尔值
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs!.setBool(key, value);
  }
  
  /// 获取布尔值
  static Future<bool?> getBool(String key) async {
    return _prefs!.getBool(key);
  }
  
  /// 保存对象（JSON）
  static Future<bool> setObject(String key, Map<String, dynamic> value) async {
    return await setString(key, jsonEncode(value));
  }
  
  /// 获取对象（JSON）
  static Future<Map<String, dynamic>?> getObject(String key) async {
    final String? value = await getString(key);
    if (value == null) return null;
    return jsonDecode(value) as Map<String, dynamic>;
  }
  
  /// 删除
  static Future<bool> remove(String key) async {
    return await _prefs!.remove(key);
  }
  
  /// 清空所有
  static Future<bool> clear() async {
    return await _prefs!.clear();
  }
}







