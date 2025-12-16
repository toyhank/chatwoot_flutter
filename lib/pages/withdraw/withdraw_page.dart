import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  
  String _withdrawType = '银行卡';
  double _balance = 1000.00; // 示例余额
  
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
        actions: [
          TextButton(
            onPressed: () {
              // TODO: 跳转到提现记录
            },
            child: const Text('提现记录'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 余额卡片
            _buildBalanceCard(),
            const SizedBox(height: 20),
            
            // 提现类型
            _buildWithdrawType(),
            const SizedBox(height: 20),
            
            // 提现金额
            _buildAmountInput(),
            const SizedBox(height: 20),
            
            // 账号信息
            _buildAccountInput(),
            const SizedBox(height: 30),
            
            // 提现按钮
            ElevatedButton(
              onPressed: _onWithdraw,
              child: const Text('立即提现'),
            ),
            const SizedBox(height: 16),
            
            // 提现说明
            _buildWithdrawTips(),
          ],
        ),
      ),
    );
  }
  
  /// 余额卡片
  Widget _buildBalanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '可提现余额',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '¥${_balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
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
          '提现方式',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: ['银行卡', '支付宝', '微信'].map((type) {
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
  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '提现金额',
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
            hintText: '请输入提现金额',
            prefixText: '¥ ',
            suffixIcon: TextButton(
              onPressed: () {
                _amountController.text = _balance.toString();
              },
              child: const Text('全部'),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入提现金额';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return '请输入有效金额';
            }
            if (amount > _balance) {
              return '余额不足';
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
              return '请输入账号';
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
              '提现说明',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. 提现金额最低10元\n'
              '2. 每日最多提现3次\n'
              '3. 工作日24小时内到账\n'
              '4. 节假日顺延至工作日处理',
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
          title: const Text('提现申请'),
          content: Text('提现金额: ¥${_amountController.text}\n提现方式: $_withdrawType'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('提现申请已提交')),
                );
              },
              child: const Text('确认'),
            ),
          ],
        ),
      );
    }
  }
}







