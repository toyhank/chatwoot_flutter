import 'package:flutter/material.dart';
import '../../utils/storage_util.dart';
import '../../services/api_service.dart';
import '../../services/push_notification_service.dart';
import '../../config/app_config.dart';
import 'dart:convert';

/// 登录页面
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 设置默认测试账号（开发环境）
    _usernameController.text = 'yushuangqi@hotmail.com';
    _passwordController.text = 'Tt112211@';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 40),
              
              // Logo
              Icon(
                Icons.account_circle,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 40),
              
              // 邮箱输入
              TextFormField(
                controller: _usernameController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email address',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email address';
                  }
                  // 简单的邮箱格式验证
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // 密码输入
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Forgot password - Hidden (not implemented)
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: TextButton(
              //     onPressed: () {
              //       // TODO: 跳转到忘记密码页面
              //     },
              //     child: const Text('Forgot Password?'),
              //   ),
              // ),
              const SizedBox(height: 20),
              
              // 登录按钮
              ElevatedButton(
                onPressed: _isLoading ? null : _onLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
              const SizedBox(height: 20),
              
              // 注册
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Social login - Hidden (not implemented)
              // const Divider(),
              // const SizedBox(height: 20),
              // const Text(
              //   'Other Login Methods',
              //   textAlign: TextAlign.center,
              //   style: TextStyle(fontSize: 12),
              // ),
              // const SizedBox(height: 20),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     _buildSocialLoginButton(Icons.wechat, 'WeChat'),
              //     const SizedBox(width: 30),
              //     _buildSocialLoginButton(Icons.phone_android, 'QQ'),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSocialLoginButton(IconData icon, String label) {
    return InkWell(
      onTap: () {
        // TODO: 第三方登录
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
  
  /// 登录
  void _onLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 调用登录 API
        final apiService = ApiService();
        final response = await apiService.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (response.isSuccess && response.data != null) {
            // 登录成功
            final user = response.data!;
            
            // 保存登录状态到本地存储
            await _saveLoginInfo(user);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back, ${user.username ?? "User"}!'),
                  backgroundColor: Colors.green,
                ),
              );

              // 跳转到主页面
              Navigator.pushReplacementNamed(context, '/main');
            }
          } else {
            // 登录失败，显示错误信息
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message.isNotEmpty 
                    ? response.message 
                    : 'Login failed, please check your credentials'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 保存登录信息
  Future<void> _saveLoginInfo(user) async {
    // 保存 token
    if (user.token != null) {
      await StorageUtil.setString(AppConfig.keyToken, user.token!);
    }
    
    // 保存用户信息（完整JSON）
    await StorageUtil.setString(
      AppConfig.keyUserInfo, 
      jsonEncode(user.toJson()),
    );
    
    // 保存登录状态
    await StorageUtil.setBool(AppConfig.keyIsLoggedIn, true);
    
    // 保存单独的字段（兼容旧版本代码）
    if (user.id != null) {
      await StorageUtil.setString('userId', user.id.toString());
    }
    if (user.username != null) {
      await StorageUtil.setString('userName', user.username!);
    }
    if (user.email != null) {
      await StorageUtil.setString('userEmail', user.email!);
    }
    
    // 注册推送 Token 到 Chatwoot（异步执行，不阻塞登录流程）
    _registerPushToken();
  }

  /// 注册推送通知 Token
  Future<void> _registerPushToken() async {
    try {
      final email = await AppConfig.getUserEmail();
      final name = await AppConfig.getUserName();
      
      final success = await PushNotificationService.registerPushToken(
        contactIdentifier: email,
        name: name,
        email: email, // 传递 email 以启用跨设备会话合并
      );
      
      if (success) {
        debugPrint('✅ 推送 Token 注册成功');
      } else {
        debugPrint('⚠️ 推送 Token 注册失败');
      }
    } catch (e) {
      debugPrint('❌ 注册推送 Token 错误: $e');
    }
  }
}



