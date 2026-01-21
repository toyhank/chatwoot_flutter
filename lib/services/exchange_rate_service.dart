import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 汇率服务 - 获取USD到NGN的实时汇率
class ExchangeRateService {
  // 使用GitHub免费API (无需API key)
  static const String _apiUrl = 
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json';
  
  static const Duration _timeout = Duration(seconds: 5);
  static const double _defaultRate = 1453.0; // 默认汇率（API失败时使用）
  
  /// 获取USD到NGN的汇率
  /// 返回汇率值，失败时返回null
  static Future<double?> getUsdToNgnRate() async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // API返回格式: {"date": "2024-01-21", "usd": {"ngn": 1453.25, ...}}
        if (data.containsKey('usd')) {
          final usdRates = data['usd'] as Map<String, dynamic>;
          if (usdRates.containsKey('ngn')) {
            final rate = usdRates['ngn'];
            if (rate is num) {
              return rate.toDouble();
            }
          }
        }
      }
      
      return null;
    } on TimeoutException {
      // 超时
      return null;
    } catch (e) {
      // 其他错误（网络错误、解析错误等）
      return null;
    }
  }
  
  /// 获取汇率，失败时返回默认值
  static Future<double> getUsdToNgnRateWithFallback() async {
    final rate = await getUsdToNgnRate();
    return rate ?? _defaultRate;
  }
  
  /// 格式化汇率显示
  static String formatRate(double rate) {
    // 格式化为带千位分隔符的字符串
    return rate.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
