import 'package:flutter/material.dart';
import '../main_page.dart';

/// 交易页面
class TradePage extends StatefulWidget {
  const TradePage({super.key});

  @override
  State<TradePage> createState() => _TradePageState();
}

class _TradePageState extends State<TradePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Trading'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('In Progress'),
          _buildOrderList('Completed'),
          _buildOrderList('Cancelled'),
        ],
      ),
    );
  }
  
  /// 订单列表
  Widget _buildOrderList(String status) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              // Navigate to chat tab when order card is tapped (index 2)
              mainPageKey.currentState?.switchToTab(2);
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 订单头部
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #: ${DateTime.now().millisecondsSinceEpoch + index}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  // 订单内容
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.style),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              () {
                                final cardNames = [
                                  'iTunes Gift Card \$100',
                                  'Apple Store Gift Card \$50', 
                                  'App Store & iTunes \$25',
                                  'Apple Music Gift Card \$15',
                                  'iTunes Digital Code \$10',
                                ];
                                return cardNames[index % cardNames.length];
                              }(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Quantity: x1',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₦99.99',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateTime.now().toString().substring(0, 16),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Action buttons hidden (not implemented)
                  // if (status == 'In Progress')
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 12),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.end,
                  //       children: [
                  //         OutlinedButton(
                  //           onPressed: () {
                  //             // TODO: 取消订单
                  //           },
                  //           child: const Text('Cancel Order'),
                  //         ),
                  //         const SizedBox(width: 8),
                  //         ElevatedButton(
                  //           onPressed: () {
                  //             // TODO: 查看详情
                  //           },
                  //           child: const Text('View Details'),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}







