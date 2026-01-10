import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home_page.dart';
import 'trade/trade_page.dart';
import 'withdraw/withdraw_page.dart';
import 'customer_service/customer_service_page.dart';
import 'user/user_page.dart';
import '../config/app_config.dart';
import '../services/unread_message_notifier.dart';

/// 主页面 - TabBar 导航
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  
  // 页面列表
  final List<Widget> _pages = [
    const HomePage(),
    const TradePage(),
    const WithdrawPage(),
    const CustomerServicePage(),
    const UserPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConfig.backgroundColor),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Consumer<UnreadMessageNotifier>(
        builder: (context, unreadNotifier, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            items: _buildBottomNavItems(unreadNotifier.hasUnread),
            type: BottomNavigationBarType.fixed, // 固定类型，防止图标变大
            backgroundColor: const Color(AppConfig.backgroundColor), // 黑色背景
            selectedItemColor: const Color(AppConfig.primaryColor), // 选中绿色
            unselectedItemColor: Colors.grey, // 未选中灰色
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              
              // 如果点击的是聊天tab（索引3），清除未读
              if (index == 3) {
                unreadNotifier.clearUnread();
              }
            },
          );
        },
      ),
    );
  }
  
  /// 构建底部导航栏项目（带未读标记）
  List<BottomNavigationBarItem> _buildBottomNavItems(bool hasUnread) {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_bag_outlined),
        activeIcon: Icon(Icons.shopping_bag),
        label: 'Order',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet_outlined),
        activeIcon: Icon(Icons.account_balance_wallet),
        label: 'Withdraw',
      ),
      BottomNavigationBarItem(
        icon: _buildChatIcon(Icons.chat_bubble_outline, hasUnread),
        activeIcon: _buildChatIcon(Icons.chat_bubble, hasUnread),
        label: 'Chat',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Settings',
      ),
    ];
  }

  /// 构建带 Badge 的聊天图标
  Widget _buildChatIcon(IconData icon, bool showBadge) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showBadge)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(AppConfig.backgroundColor), width: 1),
              ),
            ),
          ),
      ],
    );
  }
}








