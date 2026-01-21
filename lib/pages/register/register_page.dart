import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:async';

/// 注册页面
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 20),
              
              // 标题
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please fill in the following information to complete registration',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              // 邮箱
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  hintText: 'Enter email address',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter valid email format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // 验证码
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        prefixIcon: Icon(Icons.verified_user),
                        hintText: 'Enter 6-digit code',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter verification code';
                        }
                        if (value.length != 6) {
                          return 'Code must be 6 digits';
                        }
                        if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                          return 'Code must contain only numbers';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: _countdown > 0 || _isSendingCode ? null : _sendVerificationCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSendingCode
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_countdown > 0 ? '${_countdown}s' : 'Send Code'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // 昵称（可选）
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname (Optional)',
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Leave empty to use email prefix',
                ),
              ),
              const SizedBox(height: 20),
              
              // 手机号（可选）
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (Optional)',
                  prefixIcon: Icon(Icons.phone),
                  hintText: 'Enter phone number',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                      return 'Please enter valid phone number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // 密码
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  hintText: 'Enter password (6-20 characters)',
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
                  if (value.length < 6 || value.length > 20) {
                    return 'Password must be 6-20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // 确认密码
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: 'Enter password again',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password again';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // 用户协议
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Wrap(
                      children: [
                        const Text('I have read and agree to '),
                        GestureDetector(
                          onTap() {
                            // TODO: 显示用户协议
                          },
                          child: Text(
                            'Terms of Service',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const Text(' and '),
                        GestureDetector(
                          onTap: () {
                            // TODO: 显示隐私政策
                          },
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // 注册按钮
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || !_agreedToTerms ? null : _onRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              
              // 登录
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 发送验证码
  Future<void> _sendVerificationCode() async {
    // 先验证邮箱格式
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email address first')),
      );
      return;
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid email format')),
      );
      return;
    }
    
    setState(() {
      _isSendingCode = true;
    });
    
    try {
      final apiService = ApiService();
      final response = await apiService.sendEmailCode(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
        
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent to your email, please check'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 开始倒计时（60秒）
          _startCountdown(60);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty 
                  ? response.message 
                  : 'Failed to send verification code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send verification code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// 开始倒计时
  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _countdown = seconds;
    });
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  /// 注册
  Future<void> _onRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to Terms of Service and Privacy Policy first')),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final apiService = ApiService();
        final response = await apiService.register(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
          password: _passwordController.text,
          nickname: _nicknameController.text.trim().isNotEmpty 
              ? _nicknameController.text.trim() 
              : null,
          phone: _phoneController.text.trim().isNotEmpty 
              ? _phoneController.text.trim() 
              : null,
        );
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          if (response.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful, please login'),
                backgroundColor: Colors.green,
              ),
            );
            
            // 延迟一下再返回，让用户看到成功提示
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (mounted) {
              Navigator.pop(context);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message.isNotEmpty 
                    ? response.message 
                    : 'Registration failed, please check input'),
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
              content: Text('Registration failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
