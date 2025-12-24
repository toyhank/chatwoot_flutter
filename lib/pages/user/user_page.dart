import 'package:flutter/material.dart';

/// 用户中心页面
class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  bool _isLoggedIn = false;
  String _username = '游客';
  final String _avatar = '';
  double _balance = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 跳转到设置页面
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          _buildUserInfoCard(),
          const SizedBox(height: 10),
          
          // 我的资产
          _buildAssetsCard(),
          const SizedBox(height: 10),
          
          // 功能列表
          _buildMenuList(),
        ],
      ),
    );
  }
  
  /// 用户信息卡片
  Widget _buildUserInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          if (!_isLoggedIn) {
            Navigator.pushNamed(context, '/login');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.grey[800],
                child: _avatar.isEmpty
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              
              // 用户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoggedIn ? _username : '点击登录',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoggedIn ? 'ID: 123456' : '登录后享受更多服务',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 箭头
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 我的资产
  Widget _buildAssetsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildAssetItem('余额', '¥${_balance.toStringAsFixed(2)}'),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[800],
            ),
            Expanded(
              child: _buildAssetItem('积分', '0'),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[800],
            ),
            Expanded(
              child: _buildAssetItem('优惠券', '0'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAssetItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  
  /// 功能列表
  Widget _buildMenuList() {
    final menuItems = [
      {'icon': Icons.account_balance_wallet, 'title': '我的钱包', 'route': '/wallet'},
      {'icon': Icons.history, 'title': '提现记录', 'route': '/record'},
      {'icon': Icons.card_giftcard, 'title': '每日签到', 'route': '/signin'},
      {'icon': Icons.person_add, 'title': '邀请好友', 'route': '/invite'},
      {'icon': Icons.notifications, 'title': '消息通知', 'route': '/notifications'},
      {'icon': Icons.help, 'title': '帮助中心', 'route': '/help'},
      {'icon': Icons.info, 'title': '关于我们', 'route': '/about'},
    ];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ...menuItems.map((item) => _buildMenuItem(
            icon: item['icon'] as IconData,
            title: item['title'] as String,
            onTap: () {
              // TODO: 页面跳转
            },
          )),
          
          // 退出登录
          if (_isLoggedIn)
            _buildMenuItem(
              icon: Icons.logout,
              title: '退出登录',
              onTap: _onLogout,
              showDivider: false,
            ),
        ],
      ),
    );
  }
  
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(height: 1, indent: 56, color: Colors.grey[800]),
      ],
    );
  }
  
  /// 退出登录
  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLoggedIn = false;
                _username = '游客';
                _balance = 0.0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已退出登录')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}







