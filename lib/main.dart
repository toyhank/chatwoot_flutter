import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'utils/storage_util.dart';
import 'pages/main_page.dart';
import 'pages/login/login_page.dart';
import 'pages/register/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地存储
  await StorageUtil.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 检查本地存储中是否有登录信息
    final isLoggedIn = await StorageUtil.getBool('isLoggedIn') ?? false;
    final token = await StorageUtil.getString('token');
    final userId = await StorageUtil.getString('userId');

    setState(() {
      _isLoggedIn = isLoggedIn && token != null && token.isNotEmpty && userId != null && userId.isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Game Card Trading Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _isLoggedIn ? const MainPage() : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => const MainPage(),
      },
    );
  }
}
