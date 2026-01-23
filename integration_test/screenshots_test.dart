import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:testcrm_flutter/main.dart' as app;

/// Patrol 自动化截图脚本
/// 
/// 此脚本自动化以下流程：
/// 1. 启动应用并截取启动页
/// 2. 截取登录页面
/// 3. 自动登录
/// 4. 截取主页（Home）
/// 5. 截取订单页（Order）
/// 6. 截取客服页（Chat）
/// 7. 截取设置页（Settings）
void main() {
  patrolTest(
    'App Store Screenshots Generation',
    ($) async {
      // ========================================
      // 1. 启动应用
      // ========================================
      debugPrint('🚀 启动应用...');
      app.main();
      
      // 等待应用初始化
      await $.pumpAndSettle(const Duration(seconds: 3));

      // ========================================
      // 处理 iOS 系统权限弹窗
      // ========================================
      debugPrint('🔔 检查并处理系统权限弹窗...');
      try {
        if (await $.native.isPermissionDialogVisible()) {
          debugPrint('  - 发现权限弹窗，自动允许');
          await $.native.grantPermissionWhenInUse();
          await $.pumpAndSettle(const Duration(seconds: 1));
        }
      } catch (e) {
        debugPrint('  - 权限处理跳过（可能在 Android 或无权限请求）: $e');
      }

      // ========================================
      // 2. 【截图 1】启动页/加载页
      // ========================================
      // 注意：启动页可能已经过去了，如果看到的是登录页则跳过
      debugPrint('📸 准备截取启动页...');
      final isLoadingScreenVisible = $(CircularProgressIndicator).exists;
      if (isLoadingScreenVisible) {
        debugPrint('  - 发现加载页，截图');
        await $.native.takeScreenshot('01_splash_screen');
        await $.pumpAndSettle(const Duration(seconds: 2));
      } else {
        debugPrint('  - 加载页已过，跳过');
      }

      // ========================================
      // 3. 【截图 2】登录页面
      // ========================================
      debugPrint('📸 截取登录页面...');
      
      // 等待登录页面完全加载
      await $.pumpAndSettle(const Duration(seconds: 2));
      
      // 验证是否在登录页（检查关键元素）
      final isLoginPage = $('Welcome Back').exists || 
                          $('Login').exists ||
                          $(TextField).exists;
      
      if (isLoginPage) {
        debugPrint('  - 确认在登录页，截图');
        await $.native.takeScreenshot('02_login_page');
      } else {
        debugPrint('  ⚠️ 未找到登录页，可能已登录');
      }

      // ========================================
      // 4. 自动登录
      // ========================================
      debugPrint('🔐 开始自动登录...');
      
      // 查找邮箱输入框（通过 hintText 或 labelText）
      final emailField = $(TextField).at(0);
      final passwordField = $(TextField).at(1);
      
      if (emailField.exists && passwordField.exists) {
        debugPrint('  - 找到登录表单，填写凭据');
        
        // 填写邮箱（代码中默认已填充，但我们再次确认）
        await emailField.enterText('yushuangqi@hotmail.com');
        await $.pumpAndSettle(const Duration(milliseconds: 500));
        
        // 填写密码
        await passwordField.enterText('Tt112211@');
        await $.pumpAndSettle(const Duration(milliseconds: 500));
        
        // 点击登录按钮
        debugPrint('  - 点击登录按钮');
        await $('Login').tap();
        
        // 等待登录请求完成并跳转到主页
        // 给予足够时间完成网络请求
        debugPrint('  - 等待登录完成...');
        await $.pumpAndSettle(const Duration(seconds: 5));
        
        debugPrint('✅ 登录流程完成');
      } else {
        debugPrint('  ⚠️ 未找到登录表单，可能已经登录');
      }

      // ========================================
      // 5. 【截图 3】主页（Home Tab）
      // ========================================
      debugPrint('📸 截取主页...');
      
      // 确保在主页
      await $.pumpAndSettle(const Duration(seconds: 3));
      
      // 验证主页元素（余额卡片、卡片列表）
      final isHomePage = $('Home').exists || 
                         $('Cards List').exists ||
                         $(Text('0.00')).exists;
      
      if (isHomePage) {
        debugPrint('  - 确认在主页，截图');
        await $.native.takeScreenshot('03_home_page');
      } else {
        debugPrint('  ⚠️ 主页元素未找到，但仍尝试截图');
        await $.native.takeScreenshot('03_home_page');
      }

      // ========================================
      // 6. 【截图 4】订单页（Order Tab）
      // ========================================
      debugPrint('📸 切换到订单页并截图...');
      
      // 点击底部导航栏的 "Order" 按钮（索引 1）
      final orderTab = $(BottomNavigationBar);
      if (orderTab.exists) {
        // Patrol 提供了一种方式来点击特定索引的 tab
        // 但更直接的方式是通过文本查找
        await $('Order').tap();
        await $.pumpAndSettle(const Duration(seconds: 2));
        
        debugPrint('  - 已切换到订单页，截图');
        await $.native.takeScreenshot('04_order_page');
      } else {
        debugPrint('  ⚠️ 未找到底部导航栏');
      }

      // ========================================
      // 7. 【截图 5】客服页（Chat Tab）
      // ========================================
      debugPrint('📸 切换到客服页并截图...');
      
      await $('Chat').tap();
      await $.pumpAndSettle(const Duration(seconds: 3));
      
      debugPrint('  - 已切换到客服页，截图');
      await $.native.takeScreenshot('05_chat_page');

      // ========================================
      // 8. 【截图 6】设置页（Settings Tab）
      // ========================================
      debugPrint('📸 切换到设置页并截图...');
      
      await $('Settings').tap();
      await $.pumpAndSettle(const Duration(seconds: 2));
      
      debugPrint('  - 已切换到设置页，截图');
      await $.native.takeScreenshot('06_settings_page');

      // ========================================
      // 完成
      // ========================================
      debugPrint('✅ 所有截图已完成！');
      debugPrint('📁 截图位置: build/ios_integ/screenshots/ (iOS)');
      debugPrint('📁 截图位置: build/app/outputs/screenshots/ (Android)');
    },
  );
}
