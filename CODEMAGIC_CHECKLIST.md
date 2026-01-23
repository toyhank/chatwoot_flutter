# Codemagic 部署快速检查清单

在开始部署之前，请逐项检查以下清单，确保准备工作完成。

---

## ✅ 准备工作检查清单

### 📁 代码仓库准备

- [ ] **Git 仓库已创建**
  - 在 GitHub/GitLab/Bitbucket 上创建了项目仓库
  - 仓库地址: ___________________________

- [ ] **代码已推送**
  ```bash
  git add .
  git commit -m "feat: Add Patrol screenshot automation"
  git push origin main
  ```

- [ ] **关键文件已提交**
  - [ ] `integration_test/screenshots_test.dart`
  - [ ] `codemagic.yaml`
  - [ ] `patrol.toml`
  - [ ] `pubspec.yaml` (包含 patrol 依赖)

### 🔐 账号准备

- [ ] **Codemagic 账号**
  - 已注册/登录: https://codemagic.io/
  - 使用方式: □ GitHub □ GitLab □ Bitbucket □ Email

- [ ] **Git 授权**
  - Codemagic 已获得访问仓库的权限

### ⚙️ 配置文件验证

- [ ] **codemagic.yaml 语法正确**
  ```bash
  # 本地验证 YAML 语法
  # 访问 https://yaml-online-parser.appspot.com/ 粘贴内容检查
  ```

- [ ] **测试账号可用**
  - 邮箱: `yushuangqi@hotmail.com`
  - 密码: `Tt112211@`
  - 环境: `testing`

### 📧 通知配置

- [ ] **邮件地址正确**
  - 已在 `codemagic.yaml` 中配置邮箱
  - 邮箱地址: `yushuangqi@hotmail.com`

---

## 🚀 部署步骤速查

### 第一次部署（10 分钟）

```plaintext
1. 登录 Codemagic
   ↓
2. 添加应用 → 选择仓库
   ↓
3. 选择 "Use codemagic.yaml"
   ↓
4. 选择工作流: ios-screenshots
   ↓
5. 点击 "Start new build"
   ↓
6. 等待构建完成（约 10 分钟）
   ↓
7. 下载截图（Artifacts 标签页）
```

### 后续更新（推送即可）

```bash
# 更新代码
git add .
git commit -m "Update screenshots"
git push

# Codemagic 自动检测并构建（如果已配置自动触发）
```

---

## 🎯 第一次构建验证清单

构建完成后，请检查：

- [ ] **构建状态: 成功** ✅
- [ ] **构建时长: < 15 分钟**
- [ ] **生成了 6 张截图**
  - [ ] `01_splash_screen.png`
  - [ ] `02_login_page.png`
  - [ ] `03_home_page.png`
  - [ ] `04_order_page.png`
  - [ ] `05_chat_page.png`
  - [ ] `06_settings_page.png`

- [ ] **截图质量良好**
  - [ ] 无模糊
  - [ ] 无加载动画
  - [ ] 无 Debug 横幅
  - [ ] 分辨率正确（1290 x 2796）

- [ ] **收到邮件通知**
  - [ ] 成功邮件已接收

---

## ⚠️ 常见问题快速解决

### 问题 1: 找不到仓库

**检查**:
- Git 授权是否完成
- 仓库是否为 Public（或 Codemagic 已授权访问 Private）

**解决**: 重新授权 Git 提供商

---

### 问题 2: 构建失败 - "YAML 解析错误"

**检查**:
- `codemagic.yaml` 缩进是否正确（使用空格，不要用 Tab）
- YAML 语法是否正确

**解决**: 使用在线 YAML 验证器检查文件

---

### 问题 3: 构建失败 - "Patrol CLI not found"

**检查**:
- `codemagic.yaml` 中是否包含 Patrol CLI 安装步骤

**解决**: 确保有以下代码:
```yaml
- name: Install Patrol CLI
  script: |
    dart pub global activate patrol_cli
    export PATH="$PATH":"$HOME/.pub-cache/bin"
```

---

### 问题 4: 截图为空或不完整

**检查**:
- 等待时间是否足够（`Duration(seconds: 3)`）
- 测试账号登录是否成功

**解决**: 增加等待时间，检查登录日志

---

## 📊 资源使用估算

### 免费计划额度

| 构建类型 | 平均时长 | 每月可运行次数 |
|---------|----------|---------------|
| iOS 截图 | 10 分钟 | ~50 次 |
| Android 截图 | 8 分钟 | ~62 次 |
| 总计 | - | 每月约 112 次构建 |

> **提示**: 合理安排构建，避免浪费免费额度

---

## 🎓 学习资源

### 必读文档
- [ ] [Codemagic 快速入门](https://docs.codemagic.io/yaml/yaml-getting-started/)
- [ ] [Patrol 测试指南](https://patrol.leancode.co/)
- [ ] [本项目部署详细指南](./CODEMAGIC_DEPLOYMENT_GUIDE.md)

### 视频教程
- [ ] [Codemagic Flutter CI/CD (YouTube)](https://www.youtube.com/codemagic)

---

## ✨ 完成后

当你完成第一次成功构建后：

1. ⭐ **收藏 Codemagic 项目** - 方便下次访问
2. 📋 **保存构建日志** - 作为参考
3. 🖼️ **整理截图** - 用于 App Store 提交
4. 📝 **记录问题** - 遇到的问题和解决方案
5. 🎉 **庆祝成功** - 自动化已完成！

---

**开始部署**: [查看详细步骤](./CODEMAGIC_DEPLOYMENT_GUIDE.md)

**需要帮助**: 查看 [PATROL_SCREENSHOTS_README.md](./PATROL_SCREENSHOTS_README.md)
