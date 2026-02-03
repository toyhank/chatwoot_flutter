import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../log_viewer_page.dart';
import '../../services/api_service.dart';
import '../../services/push_notification_service.dart';
import '../../config/app_config.dart';

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
  bool _isDeleting = false;

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
          
          // 删除账户
          if (_isLoggedIn)
            _buildMenuItem(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              onTap: _onDeleteAccount,
              showDivider: true,
              iconColor: Colors.red,
              textColor: Colors.red,
            ),
          
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
    Color? iconColor,
    Color? textColor,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(title, style: TextStyle(color: textColor)),
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
  
  /// 删除账户
  void _onDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is permanent and cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('The following data will be permanently deleted:'),
            const SizedBox(height: 8),
            const Text('• Your account and profile'),
            const Text('• All your messages and conversations'),
            const Text('• All app preferences and settings'),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to continue?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
  
  /// 二次确认删除账户
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'This is your last chance to cancel. Your account will be permanently deleted and cannot be recovered.\n\nDo you really want to delete your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Delete My Account'),
          ),
        ],
      ),
    );
  }
  
  /// 执行账户删除
  Future<void> _performDeleteAccount() async {
    setState(() {
      _isDeleting = true;
    });
    
    try {
      // 调用删除账户 API
      final apiService = ApiService();
      final response = await apiService.deleteAccount();
      
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        
        if (response.isSuccess) {
          // 删除成功，清理本地数据
          await _clearAllData();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your account has been permanently deleted'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            
            // 跳转到登录页面
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        } else {
          // 删除失败，显示错误信息
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Deletion Failed'),
                content: Text(
                  response.message.isNotEmpty
                      ? response.message
                      : 'Failed to delete account. Please try again later or contact support.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _performDeleteAccount();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('An error occurred: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
  
  /// 清理所有本地数据
  Future<void> _clearAllData() async {
    try {
      // 清除推送订阅
      await PushNotificationService.unregisterPushToken();
      await PushNotificationService.clearChatwootData();
    } catch (e) {
      debugPrint('清除推送订阅失败: $e');
    }
    
    // 清除所有 SharedPreferences 数据
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // 更新本地状态
    setState(() {
      _isLoggedIn = false;
      _username = 'Guest';
      _email = '';
      _userId = '';
      _balance = 0.0;
    });
  }
}
