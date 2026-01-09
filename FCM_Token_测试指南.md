# Firebase 推送测试结果

## ✅ Firebase 配置成功

### Firebase 初始化状态
```
✅ Firebase 初始化成功
✅ Firebase 和推送服务初始化完成
```

### FCM Token（完整）
```
e-tf9jlmQDedRC1wOcj4Z5:APA91bGvl1aKqb903-ZDrcCEzK8mbjKuTnl-JqXw7kM4mJjvPlM6zmd7f6vBvWZ-g-TKOQMIQujI_CBY_-3PULWvJWuGMReaMSwQLxUIXPcz37sHsj8bB6Y
```

### 权限状态
- ✅ POST_NOTIFICATIONS: granted=true
- ✅ c2dm.permission.RECEIVE: granted=true
- ✅ Google Play Services: 已安装并运行

---

## 推送测试步骤

### 使用此 Token 在 Firebase Console 测试：

1. **访问** https://console.firebase.google.com/
2. **选择项目**: xcard-2b2ea
3. **进入**: Engage → Messaging
4. **创建活动**: New campaign → Firebase Notification messages
5. **填写通知**:
   - Title: `测试推送`
   - Text: `这是测试消息`
6. **点击**: Send test message
7. **粘贴 Token**:
   ```
   e-tf9jlmQDedRC1wOcj4Z5:APA91bGvl1aKqb903-ZDrcCEzK8mbjKuTnl-JqXw7kM4mJjvPlM6zmd7f6vBvWZ-g-TKOQMIQujI_CBY_-3PULWvJWuGMReaMSwQLxUIXPcz37sHsj8bB6Y
   ```
8. **点击**: Test

---

## 重要提示

### ⚠️ 前台 vs 后台

1. **应用在前台时**（当前正在使用应用）
   - Android **不会显示通知栏通知**（这是正常行为）
   - 推送会触发代码回调（查看日志会显示 `📩 收到前台消息`）

2. **应用在后台时**（按 Home 键后）
   - **会显示通知栏通知** ← 这是您需要的
   - 点击通知会打开应用

### ✅ 正确的测试方法

1. **让应用进入后台**
   - 按设备的 **Home 键**（不是返回键）
   - 或者切换到其他应用

2. **发送测试推送**
   - 使用上面的 Token 在 Firebase Console 发送

3. **查看通知栏**
   - 下拉通知栏
   - 应该看到推送通知

---

## 如果仍然看不到推送

### 检查清单

1. **应用是否在后台？**
   - 必须按 Home 键让应用进入后台
   - 不要完全关闭应用

2. **Firebase Console 是否显示成功？**
   - 应显示 "Successfully sent message"
   - 如果显示错误，检查 Token 是否复制完整

3. **设备通知是否开启？**
   - 设置 → 应用 → com.card → 通知 → 确保开启

4. **网络是否连接？**
   - FCM 需要网络连接才能接收推送

---

## 调试命令

### 实时查看推送日志
```bash
adb logcat | Select-String -Pattern "FirebaseMessaging|flutter"
```

### 查看最近的 Flutter 日志
```bash
adb logcat -d | Select-String -Pattern "I/flutter" | Select-Object -Last 20
```
