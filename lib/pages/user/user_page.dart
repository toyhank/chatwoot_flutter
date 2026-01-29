import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../log_viewer_page.dart';

/// 用户中心页面
class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  bool _isLoggedIn = false;
  String _username = 'Guest';
  String _email = '';
  String _userId = '';
  final String _avatar = '';
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  
  /// 加载用户信息
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;  // AppConfig.keyIsLoggedIn
      _username = prefs.getString('userName') ?? 'Guest';  // 'userName' not 'name'
      _email = prefs.getString('userEmail') ?? '';  // 'userEmail' not 'email'
      _userId = prefs.getString('userId') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // Settings icon removed (not implemented)
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.settings),
        //     onPressed: () {
        //       // TODO: 跳转到设置页面
        //     },
        //   ),
        // ],
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          _buildUserInfoCard(),
          const SizedBox(height: 10),
          
          // Assets card - Hidden (not implemented)
          // _buildAssetsCard(),
          // const SizedBox(height: 10),
          
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
        // Only enable tap when logged out (to navigate to login)
        onTap: !_isLoggedIn ? () {
          Navigator.pushNamed(context, '/login');
        } : null,
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
                      _isLoggedIn ? _username : 'Tap to Login',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoggedIn 
                        ? (_email.isNotEmpty ? _email : 'ID: $_userId') 
                        : 'Login for more services',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 箭头 - only show when logged out to indicate it's tappable
              if (!_isLoggedIn)
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
              child: _buildAssetItem('Balance', '¥${_balance.toStringAsFixed(2)}'),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[800],
            ),
            Expanded(
              child: _buildAssetItem('Points', '0'),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[800],
            ),
            Expanded(
              child: _buildAssetItem('Coupons', '0'),
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
    // All menu items hidden - only showing Logout when logged in
    final menuItems = [
      // Hidden items (not implemented or not needed):
      // {'icon': Icons.bug_report, 'title': 'App Logs', 'route': '/logs'},
      // {'icon': Icons.account_balance_wallet, 'title': 'My Wallet', 'route': '/wallet'},
      // {'icon': Icons.history, 'title': 'Withdrawal History', 'route': '/record'},
      // {'icon': Icons.card_giftcard, 'title': 'Daily Check-in', 'route': '/signin'},
      // {'icon': Icons.person_add, 'title': 'Invite Friends', 'route': '/invite'},
      // {'icon': Icons.notifications, 'title': 'Notifications', 'route': '/notifications'},
      // {'icon': Icons.help, 'title': 'Help Center', 'route': '/help'},
      // {'icon': Icons.info, 'title': 'About Us', 'route': '/about'},
    ];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ...menuItems.map((item) => _buildMenuItem(
            icon: item['icon'] as IconData,
            title: item['title'] as String,
            onTap: () {
              final route = item['route'] as String;
              if (route == '/logs') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogViewerPage(),
                  ),
                );
              }
              // TODO: 其他页面跳转
            },
          )),
          
          // 退出登录
          if (_isLoggedIn)
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Logout',
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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLoggedIn = false;
                _username = 'Guest';
                _balance = 0.0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}







