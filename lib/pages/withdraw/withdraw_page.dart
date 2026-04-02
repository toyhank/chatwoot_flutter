import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main_page.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

/// 提现页面
class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  
  String _withdrawType = 'Bank Card';
  
  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw'),
        // Withdrawal History removed (not implemented)
        // actions: [
        //   TextButton(
        //     onPressed: () {
        //       // TODO: 跳转到提现记录
        //     },
        //     child: const Text('Withdrawal History'),
        //   ),
        // ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 提现子项
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                return Column(
                  children: [
                    // 余额卡片
                    _buildBalanceCard(userProvider.nairaBalance),
                    const SizedBox(height: 20),
                    
                    // 提现类型
                    _buildWithdrawType(),
                    const SizedBox(height: 20),
                    
                    // 提现金额
                    _buildAmountInput(userProvider.nairaBalance),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            
            // 账号信息
            _buildAccountInput(),
            const SizedBox(height: 30),
            
            // Withdraw button hidden (not implemented)
            // ElevatedButton(
            //   onPressed: _onWithdraw,
            //   child: const Text('Withdraw Now'),
            // ),
            const SizedBox(height: 16),
            
            // 提现说明
            _buildWithdrawTips(),
          ],
        ),
      ),
    );
  }
  
  /// 余额卡片
  Widget _buildBalanceCard(double balance) {
    return InkWell(
      onTap: () {
        // Navigate to chat tab when balance card is tapped (index 2)
        mainPageKey.currentState?.switchToTab(2);
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Available Balance',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '₦${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 提现类型
  Widget _buildWithdrawType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Withdrawal Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: ['Bank Card', 'Alipay', 'WeChat'].map((type) {
            return ChoiceChip(
              label: Text(type),
              selected: _withdrawType == type,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _withdrawType = type;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  /// 提现金额输入
  Widget _buildAmountInput(double balance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Withdrawal Amount',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: 'Enter withdrawal amount',
            prefixText: '₦ ',
            suffixIcon: TextButton(
              onPressed: () {
                _amountController.text = balance.toStringAsFixed(2);
              },
              child: const Text('All'),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter withdrawal amount';
            }
            double? amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter valid amount';
            }
            if (amount > balance) {
              return 'Insufficient balance';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  /// 账号信息输入
  Widget _buildAccountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_withdrawType账号',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _accountController,
          decoration: InputDecoration(
            hintText: '请输入$_withdrawType账号',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter account';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  /// 提现说明
  Widget _buildWithdrawTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Withdrawal Instructions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Minimum withdrawal amount is ₦5,000\n'
              '2. Maximum 3 withdrawals per day\n'
              '3. Processed within 24 hours on weekdays\n'
              '4. Holidays delayed to next business day',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 提现
  void _onWithdraw() {
    if (_formKey.currentState!.validate()) {
      // TODO: 调用提现 API
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Withdrawal Request'),
          content: Text('Amount: ₦${_amountController.text}\nMethod: $_withdrawType'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Withdrawal request submitted')),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    }
  }
}







