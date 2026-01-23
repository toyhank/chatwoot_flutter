# Patrol 自动化截图使用指南

本项目已集成 Patrol 自动化测试框架，用于生成 App Store 提交所需的应用截图。

## 📋 功能说明

自动化截图脚本 (`integration_test/screenshots_test.dart`) 会自动执行以下流程：

1. **启动应用** - 捕获启动页面（如果可见）
2. **登录页面** - 截取登录界面
3. **自动登录** - 使用测试账号自动填写并登录
4. **主页截图** - 余额卡片 + 卡片列表
5. **订单页截图** - 切换到订单 Tab
6. **客服页截图** - 切换到客服聊天 Tab
7. **设置页截图** - 切换到用户设置 Tab

---

## 🚀 本地运行截图测试

### 前置条件

1. **安装 Patrol CLI**
   ```bash
   dart pub global activate patrol_cli
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **启动模拟器/真机**
   - iOS: 打开 Xcode Simulator
   - Android: 启动 Android 模拟器或连接真机

### 运行测试

#### iOS 截图
```bash
# 方式 1: 使用 Patrol CLI（推荐）
patrol test --target integration_test/screenshots_test.dart --verbose

# 方式 2: 使用 Flutter integration test
flutter test integration_test/screenshots_test.dart
```

#### Android 截图
```bash
# 确保 Android 模拟器已启动
patrol test --target integration_test/screenshots_test.dart --verbose
```

#### 使用 Release 模式（隐藏 Debug 横幅）
```bash
patrol test --target integration_test/screenshots_test.dart --release --verbose
```

### 查看截图

截图默认保存在以下位置：

- **iOS**: 
  - `build/patrol_screenshots/` 或
  - `build/ios_integ/screenshots/`
  
- **Android**: 
  - `build/patrol_screenshots/` 或
  - `build/app/outputs/screenshots/`

> 💡 **提示**: 首次运行后检查日志输出，Patrol 会告诉你截图的确切位置。

---

## ☁️ Codemagic 自动化构建

### 配置说明

项目已包含 `codemagic.yaml` 配置文件，支持：

- ✅ 多设备截图（iPhone 14 Pro、iPhone SE 等）
- ✅ iOS 和 Android 双平台
- ✅ 自动创建和启动模拟器
- ✅ 截图自动归档和下载
- ✅ 构建结果邮件通知

### 启用 Codemagic 构建

1. **访问** [Codemagic](https://codemagic.io/)
2. **连接仓库** - 使用 GitHub/GitLab/Bitbucket 授权
3. **选择工作流** - 选择 `ios-screenshots` 或 `android-screenshots`
4. **触发构建** - 手动触发或配置自动触发（push/tag）

### 查看构建产物

构建完成后，在 Codemagic 的 **Artifacts** 标签页下载：
- `screenshots/iPhone_14_Pro/*.png`
- `screenshots/Pixel_6/*.png`

---

## 🔧 自定义配置

### 修改测试账号

编辑 `integration_test/screenshots_test.dart`，找到以下行：

```dart
await emailField.enterText('yushuangqi@hotmail.com');
await passwordField.enterText('Tt112211@');
```

替换为你的测试账号。

### 调整截图顺序

在 `screenshots_test.dart` 中，可以：
- 添加/删除截图页面
- 修改截图文件名
- 调整等待时间（`Duration` 参数）

### 添加更多设备配置

编辑 `codemagic.yaml`，复制并修改现有的设备配置块：

```yaml
- name: Run tests - iPad Pro
  script: |
    DEVICE_ID=$(xcrun simctl create "iPad Pro" "iPad Pro (12.9-inch)" "iOS-17-2")
    xcrun simctl boot $DEVICE_ID
    sleep 10
    patrol test --target integration_test/screenshots_test.dart --release
    
    mkdir -p screenshots/iPad_Pro
    cp build/patrol_screenshots/*.png screenshots/iPad_Pro/
```

---

## 📱 App Store 截图规格

确保生成的截图符合 Apple 要求：

| 设备 | 尺寸 (像素) | 对应模拟器 |
|------|-------------|------------|
| 6.7" Display | 1290 x 2796 | iPhone 14 Pro Max, iPhone 15 Pro Max |
| 6.5" Display | 1242 x 2688 | iPhone 11 Pro Max, iPhone XS Max |
| 5.5" Display | 1242 x 2208 | iPhone 8 Plus, iPhone 7 Plus |

iPad:
| 设备 | 尺寸 (像素) |
|------|-------------|
| 12.9" iPad Pro | 2048 x 2732 |

---

## ❓ 故障排除

### 问题 1: 找不到 patrol 命令

**解决方案**:
```bash
# 重新安装 Patrol CLI
dart pub global activate patrol_cli

# 确认 Dart global bin 在 PATH 中
export PATH="$PATH":"$HOME/.pub-cache/bin"  # macOS/Linux
# 或 Windows: 添加 %LOCALAPPDATA%\Pub\Cache\bin 到系统 PATH
```

### 问题 2: 测试超时

**解决方案**: 增加等待时间
```dart
await $.pumpAndSettle(const Duration(seconds: 5)); // 从 2 秒增加到 5 秒
```

### 问题 3: 找不到 Widget

**解决方案**: 使用调试工具
```dart
// 打印所有文本 Widget
final allText = find.byType(Text);
debugPrint('Found ${allText.evaluate().length} Text widgets');

// 使用更宽松的查找
await $(Text).containing('Login').tap();
```

### 问题 4: 登录失败

**可能原因**:
1. 测试账号密码错误 → 检查凭据
2. 网络环境配置错误 → 检查 `--dart-define=ENV=testing`
3. API 服务未运行 → 确保后端可访问

---

## 📚 相关文档

- [Patrol 官方文档](https://patrol.leancode.co/)
- [Codemagic Flutter 文档](https://docs.codemagic.io/flutter/)
- [App Store 截图规格](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)

---

## 📧 支持

如有问题，请检查：
1. Patrol 测试日志输出
2. Codemagic 构建日志
3. 应用本身的日志（通过 Talker 日志查看器）

联系邮箱: yushuangqi@hotmail.com
