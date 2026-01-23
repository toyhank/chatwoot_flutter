# Codemagic 部署详细指南

本指南将详细说明如何将 Chatwoot Flutter 项目部署到 Codemagic 并运行自动化截图测试。

## 📊 部署流程概览

下图展示了完整的 Codemagic 自动化流程：

![Codemagic 部署流程](C:/Users/11010778/.gemini/antigravity/brain/79bfe2df-6572-42be-8894-c179a54da3b6/codemagic_deployment_flow_1769159638008.png)

**流程说明**:
1. **Git Push** - 推送代码到仓库
2. **Codemagic Detects Changes** - 自动检测代码变更
3. **Install Dependencies** - 安装 Flutter 和 Patrol 依赖
4. **Start Simulator** - 启动 iOS/Android 模拟器
5. **Run Patrol Tests** - 执行自动化测试脚本
6. **Generate Screenshots** - 生成应用截图
7. **Upload Artifacts** - 上传截图到构建产物
8. **Send Notification** - 发送邮件通知构建结果

---

## 📋 前提条件

在开始之前，请确保：

- ✅ 项目代码已推送到 Git 仓库（GitHub/GitLab/Bitbucket）
- ✅ `codemagic.yaml` 文件已存在于项目根目录
- ✅ 有可用的 Codemagic 账号（免费或付费均可）

---

## 🚀 部署步骤

### 步骤 1: 提交代码到 Git 仓库

首先，确保所有新创建的文件已提交到 Git 仓库。

```bash
# 查看当前状态
git status

# 添加新文件
git add integration_test/screenshots_test.dart
git add codemagic.yaml
git add patrol.toml
git add PATROL_SCREENSHOTS_README.md
git add pubspec.yaml

# 提交更改
git commit -m "feat: Add Patrol automated screenshot testing

- Add Patrol test script for automated screenshots
- Configure Codemagic CI/CD for multi-device testing
- Add comprehensive documentation"

# 推送到远程仓库
git push origin main
# 或者推送到你的主分支: git push origin master
```

> **💡 提示**: 如果你还没有创建 Git 仓库，请先在 GitHub/GitLab/Bitbucket 上创建。

---

### 步骤 2: 注册/登录 Codemagic

#### 2.1 访问 Codemagic 官网

打开浏览器访问：**https://codemagic.io/**

#### 2.2 注册账号

点击右上角 **"Sign up"** 按钮，有以下几种方式：

- **GitHub 登录**（推荐 - 最简单）
- **GitLab 登录**
- **Bitbucket 登录**
- **Email 注册**

![Codemagic 登录页面](https://docs.codemagic.io/uploads/2023/11/signup.png)

> **推荐**: 使用 GitHub 登录，可以直接授权访问你的代码仓库。

#### 2.3 选择计划

Codemagic 提供以下计划：

| 计划 | 价格 | macOS 构建时长 | Linux 构建时长 | 特性 |
|------|------|----------------|----------------|------|
| **Free** | $0 | 500 分钟/月 | 500 分钟/月 | 适合个人项目 |
| **Professional** | $79/月 | 无限 | 无限 | 适合团队 |

对于自动化截图，**免费计划通常足够**（每次构建约 5-10 分钟）。

---

### 步骤 3: 连接 Git 仓库

#### 3.1 添加应用

登录后，在 Codemagic 控制台：

1. 点击 **"Add application"**（添加应用）按钮
2. 选择你的 Git 提供商（GitHub/GitLab/Bitbucket）

![添加应用](https://docs.codemagic.io/uploads/2023/11/add-application.png)

#### 3.2 授权访问

首次连接时，Codemagic 会请求访问你的仓库：

- **GitHub**: 点击 "Authorize Codemagic"
- **GitLab**: 点击 "Authorize"
- **Bitbucket**: 点击 "Grant access"

> **安全提示**: Codemagic 只会读取你的代码和提交历史，不会进行未授权的更改。

#### 3.3 选择仓库

在仓库列表中找到并选择 **`chatwoot_flutter1`**（或你的项目名称）

![选择仓库](https://docs.codemagic.io/uploads/2023/11/select-repository.png)

---

### 步骤 4: 配置项目

#### 4.1 选择配置方式

Codemagic 会自动检测到你的 `codemagic.yaml` 文件，显示两个选项：

- **Workflow Editor**（图形化界面）
- **codemagic.yaml**（YAML 配置文件）✅ **选择此项**

点击 **"Set up build"** → 选择 **"Use codemagic.yaml"**

![选择配置方式](https://docs.codemagic.io/uploads/2023/11/yaml-config.png)

#### 4.2 验证 YAML 配置

Codemagic 会读取你的 `codemagic.yaml` 并显示工作流列表：

- ✅ `ios-screenshots` - iOS 截图生成
- ✅ `android-screenshots` - Android 截图生成

![工作流列表](https://docs.codemagic.io/uploads/2023/11/workflows.png)

#### 4.3 选择初始工作流

首次配置时，选择 **`ios-screenshots`** 作为默认工作流。

---

### 步骤 5: 配置环境变量（可选）

如果你的项目需要密钥或敏感信息：

#### 5.1 进入环境变量设置

1. 点击工作流右侧的 **"..."** 菜单
2. 选择 **"Environment variables"**

#### 5.2 添加变量

常见的环境变量：

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `ENV` | 运行环境 | `testing` 或 `production` |
| `API_KEY` | API 密钥 | （如果需要） |
| `TEST_EMAIL` | 测试账号邮箱 | `yushuangqi@hotmail.com` |
| `TEST_PASSWORD` | 测试账号密码 | `Tt112211@` |

> **安全提示**: 敏感信息应存储在环境变量中，而不是硬编码在代码里。

#### 5.3 使用环境变量

在 `codemagic.yaml` 中引用：

```yaml
environment:
  vars:
    ENV: $ENV  # 从环境变量读取
```

在测试脚本中使用：

```dart
final email = const String.fromEnvironment('TEST_EMAIL', 
  defaultValue: 'yushuangqi@hotmail.com');
```

---

### 步骤 6: 触发构建

#### 6.1 手动触发（首次测试推荐）

1. 在工作流列表中找到 **`ios-screenshots`**
2. 点击右侧的 **"Start new build"**（开始新构建）按钮
3. 选择分支（通常是 `main` 或 `master`）
4. 点击 **"Start build"** 确认

![手动触发构建](https://docs.codemagic.io/uploads/2023/11/start-build.png)

#### 6.2 查看构建进度

构建开始后，你会看到实时日志输出：

```
✓ Cloning repository...
✓ Installing Flutter dependencies...
✓ Installing Patrol CLI...
✓ Preparing iOS simulator...
▶ Running Patrol screenshot tests...
```

![构建日志](https://docs.codemagic.io/uploads/2023/11/build-logs.png)

构建通常需要 **5-15 分钟**，取决于：
- 测试复杂度
- 模拟器启动速度
- 网络连接质量

#### 6.3 构建状态说明

| 状态 | 图标 | 说明 |
|------|------|------|
| **Building** | ⏳ | 构建进行中 |
| **Success** | ✅ | 构建成功 |
| **Failed** | ❌ | 构建失败 |
| **Canceled** | ⚫ | 手动取消 |

---

### 步骤 7: 下载截图

#### 7.1 查看构建结果

构建成功后，点击构建记录进入详情页面。

#### 7.2 下载产物

1. 切换到 **"Artifacts"**（产物）标签页
2. 你会看到生成的截图文件：

```
screenshots/
  iPhone_14_Pro/
    01_splash_screen.png
    02_login_page.png
    03_home_page.png
    04_order_page.png
    05_chat_page.png
    06_settings_page.png
```

3. 点击 **"Download all"**下载所有截图，或单独下载

![下载产物](https://docs.codemagic.io/uploads/2023/11/artifacts.png)

#### 7.3 查看截图

下载后解压 ZIP 文件，检查每张截图的质量：

- ✅ 图片清晰，无模糊
- ✅ 界面完整，无加载状态
- ✅ 无 Debug 横幅（Release 模式）
- ✅ 符合 App Store 规格（分辨率）

---

### 步骤 8: 配置自动触发（可选）

#### 8.1 设置触发条件

在工作流设置中配置自动触发：

```yaml
# codemagic.yaml 中添加
workflows:
  ios-screenshots:
    triggering:
      events:
        - push  # 每次 push 触发
      branch_patterns:
        - pattern: 'main'  # 仅 main 分支
          include: true
      tag_patterns:
        - pattern: 'v*'  # 或者标签触发，如 v1.0.0
          include: true
```

#### 8.2 常见触发策略

| 策略 | 触发条件 | 适用场景 |
|------|----------|----------|
| **手动触发** | 点击按钮 | 开发测试阶段 |
| **Push 触发** | `git push` | 持续集成 |
| **Tag 触发** | `git tag v1.0.0` | 版本发布 |
| **定时触发** | Cron 表达式 | 夜间构建 |

---

### 步骤 9: 配置通知

#### 9.1 邮件通知

在 `codemagic.yaml` 中已配置：

```yaml
publishing:
  email:
    recipients:
      - yushuangqi@hotmail.com
    notify:
      success: true  # 成功时发送
      failure: true  # 失败时发送
```

#### 9.2 其他通知方式

Codemagic 支持：

- ✅ **Slack** - 发送到 Slack 频道
- ✅ **Discord** - 发送到 Discord 服务器
- ✅ **Webhook** - 自定义 HTTP 回调

配置示例（Slack）：

```yaml
publishing:
  slack:
    channel: '#builds'
    notify_on_build_start: false
    notify:
      success: true
      failure: true
```

---

## 🔧 高级配置

### 多设备截图

#### 添加 iPhone SE 截图

在 `codemagic.yaml` 中取消注释 iPhone SE 部分：

```yaml
- name: Run Patrol tests (iPhone SE)
  script: |
    xcrun simctl shutdown all || true
    DEVICE_ID=$(xcrun simctl create "iPhone SE" "iPhone SE (3rd generation)" "iOS-17-2")
    xcrun simctl boot $DEVICE_ID
    sleep 10
    patrol test --target integration_test/screenshots_test.dart --release
    
    mkdir -p screenshots/iPhone_SE
    cp build/patrol_screenshots/*.png screenshots/iPhone_SE/ || true
```

#### 运行 Android 截图

切换到 `android-screenshots` 工作流：

1. 在 Codemagic 控制台选择工作流
2. 点击 "Start new build"
3. 等待构建完成
4. 下载 Android 截图

---

### 多语言截图

#### 修改测试脚本

在 `screenshots_test.dart` 中添加语言参数：

```dart
void main() {
  // 读取语言参数
  const locale = String.fromEnvironment('LOCALE', defaultValue: 'en');
  
  patrolTest(
    'Screenshots - $locale',
    ($) async {
      // 设置应用语言
      await $.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          // ...
        ),
      );
      // ... 其余代码
    },
  );
}
```

#### 配置多语言构建

```yaml
- name: Generate screenshots for multiple locales
  script: |
    for lang in en zh es; do
      patrol test \
        --target integration_test/screenshots_test.dart \
        --dart-define=LOCALE=$lang \
        --release
      
      mkdir -p screenshots/$lang/iPhone_14_Pro
      cp build/patrol_screenshots/*.png screenshots/$lang/iPhone_14_Pro/
    done
```

---

## ❓ 常见问题

### Q1: 构建失败，提示 "Patrol CLI not found"

**解决方案**:
检查 `codemagic.yaml` 中是否正确安装 Patrol CLI：

```yaml
- name: Install Patrol CLI
  script: |
    dart pub global activate patrol_cli
    export PATH="$PATH":"$HOME/.pub-cache/bin"
    patrol --version  # 验证安装
```

### Q2: 模拟器启动超时

**解决方案**:
增加等待时间：

```yaml
script: |
  xcrun simctl boot $DEVICE_ID
  sleep 15  # 从 10 秒增加到 15 秒
```

### Q3: 截图路径找不到

**解决方案**:
在构建日志中查找实际路径：

```yaml
- name: Debug - List generated files
  script: |
    find build -name "*.png" -type f
```

然后根据实际输出调整复制命令。

### Q4: 登录失败

**可能原因**:
- 测试账号密码错误
- API 服务器不可访问
- 环境变量 `ENV` 配置错误

**解决方案**:
1. 检查测试脚本中的账号密码
2. 确保 `--dart-define=ENV=testing` 正确
3. 在本地先测试登录是否成功

### Q5: 免费额度用完

Codemagic 免费计划提供：
- macOS: 500 分钟/月
- Linux: 500 分钟/月

**建议**:
- 仅在需要时手动触发构建
- 避免频繁提交触发自动构建
- 考虑升级到付费计划

---

## 📊 费用预估

### 免费计划

| 项目 | 配额 |
|------|------|
| macOS 构建 | 500 分钟/月 |
| Linux 构建 | 500 分钟/月 |
| 并发构建 | 1 个 |

**实际使用**:
- 单次 iOS 截图构建: ~10 分钟
- 单次 Android 截图构建: ~8 分钟
- 每月可运行: ~25 次 iOS + 28 次 Android

### 付费计划

从 **$79/月** 起，提供：
- 无限构建时长
- 更快的构建机器
- 3 个并发构建
- 优先支持

---

## ✅ 验证清单

部署完成后，请验证：

- [ ] Git 仓库已包含所有文件（`codemagic.yaml` 等）
- [ ] Codemagic 项目已成功连接仓库
- [ ] 工作流配置正确显示
- [ ] 首次构建成功完成
- [ ] 截图文件成功生成并下载
- [ ] 截图质量符合 App Store 要求
- [ ] 邮件通知正常工作
- [ ] （可选）自动触发配置正确

---

## 📚 相关资源

### 官方文档
- [Codemagic 官网](https://codemagic.io/)
- [Codemagic YAML 配置文档](https://docs.codemagic.io/yaml/yaml-getting-started/)
- [Patrol 文档](https://patrol.leancode.co/)
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)

### 视频教程
- [Codemagic Flutter CI/CD 快速入门](https://www.youtube.com/codemagic)

### 社区支持
- [Codemagic Slack 社区](https://codemagic.slack.com)
- [Patrol GitHub Discussions](https://github.com/leancodepl/patrol/discussions)

---

## 🎯 下一步

1. **立即开始**: 按照本指南步骤在 Codemagic 上配置项目
2. **测试运行**: 手动触发一次构建，验证流程
3. **优化调整**: 根据实际情况调整等待时间、设备配置
4. **生产部署**: 配置自动触发，集成到发布流程

---

**祝你部署顺利！** 🚀

如有问题，请参考 [常见问题](#-常见问题) 部分或查阅官方文档。
