import 'package:flutter/material.dart';
import 'dart:convert';
import '../config/app_config.dart';
import '../utils/storage_util.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../services/exchange_rate_service.dart';

/// 用户状态管理
class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoggedIn = false;
  double _exchangeRate = 1453.0; // 默认汇率

  UserModel? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  double get balance => _user?.balance ?? 0.0;
  double get exchangeRate => _exchangeRate;
  double get nairaBalance => balance; // 后端已返回奈拉
  double get usdBalance => _exchangeRate > 0 ? balance / _exchangeRate : 0.0;
  String get username => _user?.username ?? 'Guest';
  String get email => _user?.email ?? '';
  String get userId => _user?.id ?? '';

  UserProvider() {
    _init();
  }

  /// 初始化从本地存储加载
  Future<void> _init() async {
    _isLoggedIn = await StorageUtil.getBool(AppConfig.keyIsLoggedIn) ?? false;
    final userInfoStr = await StorageUtil.getString(AppConfig.keyUserInfo);
    if (userInfoStr != null && userInfoStr.isNotEmpty) {
      try {
        _user = UserModel.fromJson(jsonDecode(userInfoStr));
      } catch (e) {
        debugPrint('Error parsing user info: $e');
      }
    }
    notifyListeners();
    
    // 初始化汇率
    _fetchExchangeRate();
    
    // 如果已登录，尝试刷新一次最新数据
    if (_isLoggedIn) {
      refreshUserInfo();
    }
  }

  /// 获取汇率
  Future<void> _fetchExchangeRate() async {
    final rate = await ExchangeRateService.getUsdToNgnRateWithFallback();
    _exchangeRate = rate;
    notifyListeners();
  }

  /// 刷新用户信息
  Future<void> refreshUserInfo() async {
    if (!_isLoggedIn) return;
    try {
      final response = await ApiService().getUserInfo();
      if (response.isSuccess && response.data != null) {
        _user = response.data;
        // 保存到本地
        await StorageUtil.setString(AppConfig.keyUserInfo, jsonEncode(_user!.toJson()));
        
        // 同时刷新汇率
        await _fetchExchangeRate();
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user info: $e');
    }
  }

  /// 这里的 checkIn 会直接触发 API 并更新状态
  Future<bool> checkIn(BuildContext context) async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return false;
    }

    // 显示加载中
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService().checkIn();
      
      if (context.mounted) Navigator.pop(context); // 隐藏加载中

      if (response.isSuccess) {
        final data = response.data;
        final newBalance = double.tryParse(data?['balance']?.toString() ?? '0') ?? balance;
        
        // 更新内存状态
        if (_user != null) {
          _user = _user!.copyWith(balance: newBalance);
        } else {
           _user = UserModel(balance: newBalance);
        }
        
        // 同步到本地存储
        await StorageUtil.setString(AppConfig.keyUserInfo, jsonEncode(_user!.toJson()));
        notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty ? response.message : 'Check-in successful! Reward added.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        // 如果签到过了（通常 422），接口可能也会返回当前余额
        if (response.code == 422 && response.data != null) {
          final data = response.data;
          final newBalance = double.tryParse(data?['balance']?.toString() ?? '0') ?? balance;
          if (_user != null) {
            _user = _user!.copyWith(balance: newBalance);
            await StorageUtil.setString(AppConfig.keyUserInfo, jsonEncode(_user!.toJson()));
            notifyListeners();
          }
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: response.code == 422 ? Colors.orange : Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  /// 退出登录时清除状态
  void logout() {
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }

  /// 登录成功后设置状态
  void login(UserModel user) {
    _user = user;
    _isLoggedIn = true;
    notifyListeners();
  }
}
