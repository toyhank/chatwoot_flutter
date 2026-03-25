/// Chatwoot 客服页面 - 平台自适应
/// 
/// 自动根据平台选择不同的实现：
/// - Web平台：使用 IFrame 加载
/// - 移动平台（iOS/Android）：使用 InAppWebView 加载

library customer_service_page;

// 条件导出：根据平台自动选择实现
export 'customer_service_page_mobile.dart'
    if (dart.library.html) 'customer_service_page_web.dart';

// Re-export CustomerServicePage 别名
import 'customer_service_page_mobile.dart' if (dart.library.html) 'customer_service_page_web.dart';

// 提供统一的类名
class CustomerServicePage extends CustomerServicePageImpl {
  const CustomerServicePage({super.key});
}
