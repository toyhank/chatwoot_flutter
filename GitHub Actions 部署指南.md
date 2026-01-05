# GitHub Actions 自动化部署指南

## 📋 概述

本项目已配置 GitHub Actions 工作流，支持自动化构建和部署到测试环境和生产环境。

## 🔧 配置步骤

### 1. 生成 SSH 密钥对

在本地生成 SSH 密钥对（如果还没有）：

```bash
# 生成 SSH 密钥
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy

# 查看公钥（需要添加到服务器）
cat ~/.ssh/github_actions_deploy.pub
```

### 2. 配置服务器 SSH 访问

将公钥添加到服务器的 `~/.ssh/authorized_keys`：

```bash
# 在服务器上执行
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "你的公钥内容" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

或者使用 `ssh-copy-id`：

```bash
ssh-copy-id -i ~/.ssh/github_actions_deploy.pub root@your-server-ip
```

### 3. 配置 GitHub Secrets

在 GitHub 仓库中配置以下 Secrets：

#### 测试环境 Secrets

1. 进入仓库：`Settings` → `Secrets and variables` → `Actions`
2. 点击 `New repository secret` 添加以下密钥：

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| `SSH_PRIVATE_KEY` | SSH 私钥（完整内容，包括 `-----BEGIN` 和 `-----END`） | 从 `~/.ssh/github_actions_deploy` 复制 |
| `SERVER_HOST` | 测试服务器 IP 或域名 | `43.157.0.135` |
| `SERVER_USER` | SSH 用户名 | `root` |
| `DEPLOY_DIR` | 部署目录（可选，默认 `/var/www/chatwoot_flutter`） | `/var/www/chatwoot_flutter` |

#### 生产环境 Secrets

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| `SSH_PRIVATE_KEY` | SSH 私钥（可以与测试环境共用） | 同上 |
| `PRODUCTION_SERVER_HOST` | 生产服务器 IP 或域名 | `your-production-server.com` |
| `PRODUCTION_SERVER_USER` | SSH 用户名 | `root` |
| `PRODUCTION_DEPLOY_DIR` | 部署目录（可选） | `/var/www/chatwoot_flutter` |

#### 配置 GitHub Environment（生产环境保护）

1. 进入仓库：`Settings` → `Environments`
2. 点击 `New environment`，创建名为 `production` 的环境
3. 可选：配置保护规则和审批者

## 🚀 使用方法

### 自动部署（推荐）

#### 测试环境自动部署

当代码推送到以下分支时，会自动部署到测试环境：
- `develop`
- `testing`

```bash
# 推送到测试分支
git push origin develop
```

#### 生产环境自动部署

当代码推送到以下分支或标签时，会自动部署到生产环境：
- `main` 或 `master`
- `production`
- 版本标签（如 `v1.0.0`）

```bash
# 推送到主分支
git push origin main

# 或创建版本标签
git tag v1.0.0
git push origin v1.0.0
```

### 手动触发部署

#### 测试环境

1. 进入 GitHub 仓库
2. 点击 `Actions` 标签
3. 选择 `部署到测试环境` workflow
4. 点击 `Run workflow`
5. 选择分支，点击 `Run workflow`

#### 生产环境

1. 进入 GitHub 仓库
2. 点击 `Actions` 标签
3. 选择 `部署到生产环境` workflow
4. 点击 `Run workflow`
5. 在 `confirm_production` 输入框中输入 `yes`
6. 选择分支，点击 `Run workflow`

## 📁 Workflow 文件说明

### `.github/workflows/deploy-testing.yml`

测试环境部署工作流：
- **触发条件**：推送到 `develop` 或 `testing` 分支
- **构建环境**：使用 `--dart-define=ENV=testing`
- **部署目标**：测试服务器

### `.github/workflows/deploy-production.yml`

生产环境部署工作流：
- **触发条件**：推送到 `main`/`master`/`production` 分支或版本标签
- **构建环境**：使用 `--dart-define=ENV=production`
- **部署目标**：生产服务器
- **安全保护**：需要手动确认（workflow_dispatch）

### `.github/workflows/ci.yml`

持续集成工作流：
- **触发条件**：Pull Request 和代码推送
- **功能**：代码分析、格式化检查、测试、构建验证

## 🔍 查看部署状态

1. 进入 GitHub 仓库
2. 点击 `Actions` 标签
3. 查看工作流运行状态
4. 点击具体运行查看详细日志

## 🐛 故障排查

### 问题 1: SSH 连接失败

**错误信息**：`Permission denied (publickey)`

**解决方法**：
1. 检查 SSH 私钥是否正确添加到 GitHub Secrets
2. 确保私钥包含完整的 `-----BEGIN` 和 `-----END` 行
3. 验证公钥已添加到服务器的 `authorized_keys`
4. 测试 SSH 连接：`ssh -i ~/.ssh/github_actions_deploy root@your-server`

### 问题 2: 构建失败

**错误信息**：`flutter build` 失败

**解决方法**：
1. 检查 `lib/config/app_config.dart` 中的环境配置
2. 查看 GitHub Actions 日志中的详细错误信息
3. 确保所有依赖都已正确配置

### 问题 3: 部署失败

**错误信息**：服务器部署步骤失败

**解决方法**：
1. 检查服务器 Nginx 是否正常运行
2. 验证部署目录权限
3. 查看服务器日志：`journalctl -u nginx`

### 问题 4: 权限不足

**错误信息**：`Permission denied`

**解决方法**：
1. 确保 SSH 用户有 sudo 权限（如果需要）
2. 检查部署目录的权限设置
3. 验证 Nginx 配置文件的权限

## 🔐 安全建议

1. **SSH 密钥安全**
   - 使用专用的部署密钥，不要使用个人 SSH 密钥
   - 定期轮换 SSH 密钥
   - 限制 SSH 密钥的权限范围

2. **Secrets 管理**
   - 不要将 Secrets 提交到代码仓库
   - 定期检查和更新 Secrets
   - 使用 GitHub Environments 保护生产环境

3. **分支保护**
   - 启用主分支保护规则
   - 要求代码审查
   - 禁止直接推送到主分支

4. **部署审批**
   - 生产环境部署需要审批
   - 使用 GitHub Environments 配置审批流程

## 📝 最佳实践

1. **分支策略**
   - `develop` → 测试环境
   - `main`/`master` → 生产环境
   - 使用 Pull Request 进行代码审查

2. **版本管理**
   - 使用 Git 标签标记版本
   - 遵循语义化版本控制（SemVer）

3. **回滚策略**
   - 保留旧版本备份
   - 准备快速回滚脚本

4. **监控和通知**
   - 配置部署成功/失败通知
   - 监控应用运行状态

## 🎯 工作流示例

### 典型开发流程

```bash
# 1. 创建功能分支
git checkout -b feature/new-feature

# 2. 开发并提交
git add .
git commit -m "feat: 添加新功能"
git push origin feature/new-feature

# 3. 创建 Pull Request
# 在 GitHub 上创建 PR，CI 会自动运行

# 4. 合并到 develop（自动部署到测试环境）
# 在 GitHub 上合并 PR

# 5. 测试通过后，合并到 main（自动部署到生产环境）
# 在 GitHub 上合并 PR
```

### 紧急修复流程

```bash
# 1. 从 main 创建热修复分支
git checkout -b hotfix/critical-bug main

# 2. 修复并提交
git add .
git commit -m "fix: 修复关键bug"
git push origin hotfix/critical-bug

# 3. 创建 Pull Request 并快速合并

# 4. 合并到 main 后自动部署到生产环境
```

## 📞 技术支持

如遇到问题：
1. 查看 GitHub Actions 日志
2. 检查服务器日志
3. 验证 Secrets 配置
4. 参考本文档的故障排查部分

## 🔄 更新 Workflow

如果需要修改工作流配置：
1. 编辑 `.github/workflows/` 目录下的 YAML 文件
2. 提交更改
3. GitHub Actions 会自动使用新的配置

---

**注意**：首次配置后，建议先在测试环境验证工作流是否正常工作，再配置生产环境。




