import 'package:flutter/material.dart';
import '../main_page.dart';
import '../../services/exchange_rate_service.dart';
import '../../utils/storage_util.dart';
import '../../config/app_config.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isBalanceVisible = true;
  
  // Exchange rate state
  double? _exchangeRate;
  bool _isLoadingRate = true;
  bool _isLoggedIn = false;

  // 模拟数据
  final List<Map<String, dynamic>> _cardList = [
    {
      'icon': Icons.phone_iphone,
      'title': 'iTunes/Apple (Slow loading)',
      'subtitle': 'Rates up to ₦ 0',
      'type': 'iTunes',
    },
    {
      'icon': Icons.card_giftcard,
      'title': 'iTunes/Apple (Physical)',
      'subtitle': 'Rates up to ₦ 1,377',
      'type': 'iTunes',
    },
    {
      'icon': Icons.qr_code,
      'title': 'iTunes/Apple (Ecode)',
      'subtitle': 'Rates up to ₦ 1,165',
      'type': 'iTunes',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchExchangeRate();
    _loadUserInfo();
  }
  
  /// 加载用户信息 (不再需要手动加载余额，UserProvider 会处理)
  Future<void> _loadUserInfo() async {
    final isLoggedIn = await StorageUtil.getBool(AppConfig.keyIsLoggedIn) ?? false;
    
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
    }
  }
  
  /// 获取汇率
  Future<void> _fetchExchangeRate() async {
    final rate = await ExchangeRateService.getUsdToNgnRateWithFallback();
    if (mounted) {
      setState(() {
        _exchangeRate = rate;
        _isLoadingRate = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 整体黑色背景
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<UserProvider>().refreshUserInfo();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // 绿色资产卡片
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  return _buildAssetCard(userProvider);
                },
              ),
              const SizedBox(height: 16),

              // Feature cards (Weekly Bonus / Daily Check-in)
              if (_isLoggedIn) _buildFeatureRow(),
              if (_isLoggedIn) const SizedBox(height: 24),

              // 列表标题
              const Text(
                'Cards List',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 卡片列表
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _cardList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildListItem(_cardList[index]);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 1. 顶部通知栏
  Widget _buildNotificationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // 深灰色背景
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Get the best rate! Submit your order and get paid instantly!',
              style: TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  // 2. 绿色资产卡片
  Widget _buildAssetCard(UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFB4E666), // 亮绿色
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exchange rate display (simplified)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 8), // Spacer
              
              // Exchange rate info block
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                     const Text(
                       'Exchange Rate',
                       style: TextStyle(color: Colors.black54, fontSize: 10),
                     ),
                     const SizedBox(height: 4),
                      Text(
                        _isLoadingRate 
                          ? '1USD ≈ ₦...' 
                          : '1USD ≈ ₦${ExchangeRateService.formatRate(userProvider.exchangeRate)}',
                        style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 金额显示
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                !_isLoggedIn ? '0.00' : (_isBalanceVisible ? userProvider.balance.toStringAsFixed(2) : '****'),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '₦', // Changed from USD to ₦
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                !_isLoggedIn 
                  ? '≈ \$ 0.00' 
                  : (_isBalanceVisible 
                      ? '≈ \$ ${userProvider.usdBalance.toStringAsFixed(2)}' 
                      : '≈ \$ ****'),
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                },
                child: Icon(
                  _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.black54,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bottom action buttons - Hidden (not implemented)
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     _buildActionButton(Icons.arrow_upward, 'Withdraw', Colors.blue),
          //     _buildActionButton(Icons.account_balance, 'Add Bank', Colors.grey[700]!),
          //     _buildActionButton(Icons.description, 'Record', Colors.grey[700]!),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color iconBgColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. 功能卡片行
  Widget _buildFeatureRow() {
    return Row(
      children: [
        // Weekly Trade Bonus
        Expanded(
          child: Container(
            height: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Trade Bonus',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.phone_android, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFB4E666)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '0 ₦',
                        style: TextStyle(color: Color(0xFFB4E666), fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Daily Check-in
        Expanded(
          child: InkWell(
            onTap: () {
              // 直接触发签到
              context.read<UserProvider>().checkIn(context);
            },
            child: Container(
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Check-in',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.edit_note, color: const Color(AppConfig.primaryColor), size: 32),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 4. 列表项
  Widget _buildListItem(Map<String, dynamic> item) {
    return InkWell(
      onTap: () {
        // Navigate to chat tab (index 2, after Withdraw tab removed)
        mainPageKey.currentState?.switchToTab(2);
      },
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(item['icon'], color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['subtitle'],
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
      ),
    );
  }
}


