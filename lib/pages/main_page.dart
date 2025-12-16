import 'package:flutter/material.dart';
import 'home/home_page.dart';
import 'trade/trade_page.dart';
import 'withdraw/withdraw_page.dart';
import 'customer_service/customer_service_page.dart';
import 'user/user_page.dart';
import '../config/app_config.dart';

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
  
  // TabBar 配置
  final List<BottomNavigationBarItem> _bottomNavItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_bag_outlined),
      activeIcon: Icon(Icons.shopping_bag),
      label: 'Order',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet_outlined),
      activeIcon: Icon(Icons.account_balance_wallet),
      label: 'Withdraw',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_bubble_outline),
      activeIcon: Icon(Icons.chat_bubble),
      label: 'Chat',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConfig.backgroundColor),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _bottomNavItems,
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
        },
      ),
    );
  }
}







