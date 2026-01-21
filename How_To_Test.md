# 🚀 Chatwoot Integration Testing Guide

## Current Configuration

- **Server Address**: `http://43.132.120.194:3000`
- **Website Token**: `mYm3V3bEheaSb6GpSHvKKLUn`

---

## 📝 Testing Steps

### Step 1: Test Chatwoot Server Connection

#### Method A: Use Provided Diagnostic Tool (Recommended)

1. Open `test_chatwoot.html` file in the project root directory with a browser
2. Check the results of three tests:
   - ✓ Test 1: Server reachability
   - ✓ Test 2: SDK script loading  
   - ✓ Test 3: SDK initialization
3. If all tests pass, chat window should appear in the bottom right corner of the page
4. If any test fails, check `CHATWOOT_TROUBLESHOOTING.md` document

#### Method B: Manual Server Testing

Visit in browser:
```
http://43.132.120.194:3000
```

If you can see Chatwoot login page, the server is running normally.

---

### Step 2: Check Chatwoot Backend Configuration

1. **Login to Chatwoot Backend**:
   ```
   http://43.132.120.194:3000
   ```

2. **Verify Website Token**:
   - Go to `Settings` → `Inboxes`
   - Select your Website Inbox
   - Go to `Configuration` → `Widget Configuration`
   - Confirm Website Token is: `mYm3V3bEheaSb6GpSHvKKLUn`

3. **Check Inbox Status**:
   - Ensure Inbox is enabled
   - Ensure customer service agents are online

---

### Step 3: Test Flutter Application

#### Web Platform Testing

```bash
cd G:\HBuilderProjects\testcrm_flutter
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

**Note**: `--disable-web-security` is to temporarily disable CORS restrictions for convenient testing.

#### Android Platform Testing

```bash
flutter run -d android
```

#### Testing Steps:

1. Start application
2. Navigate to "Customer Service" page
3. Observe if you can see chat interface
4. Check if displaying "Offline" or "Online"

---

## 🐛 Common Issues and Quick Fixes

### Issue 1: Displaying "Offline"

**Possible Causes**:
- Chatwoot server cannot be accessed
- CORS cross-origin issue
- WebSocket connection failed
- No customer service agents online

**Quick Check**:
1. Open `test_chatwoot.html` to see which test failed
2. Check browser console (F12) for error messages
3. Confirm customer service agents are online in Chatwoot backend

**Detailed Solution**: Check `CHATWOOT_TROUBLESHOOTING.md`

---

### Issue 2: Web Platform Loading Failed

**Solution**: Run with security disabled mode

```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

This is because HTTP server loading in HTTPS pages will be blocked by browser.

**Long-term Solution**: Configure HTTPS for Chatwoot server (see troubleshooting document)

---

### Issue 3: Android Cannot Load

**Checklist**:
1. ✅ `android:usesCleartextTraffic="true"` configured (already done)
2. ✅ Device connected to internet
3. ✅ Can ping `43.132.120.194`

---

### Issue 4: WebSocket Connection Failed

**Symptoms**: SDK loads successfully but keeps showing "Connecting" or "Offline"

**Check**:
1. Is there WebSocket error in browser console
2. Chatwoot server's ActionCable configuration
3. Is firewall blocking WebSocket

---

## 📋 Debugging Checklist

Before reporting issues, please complete the following checks:

- [ ] ✅ Server pingable: `ping 43.132.120.194`
- [ ] ✅ Browser can access: `http://43.132.120.194:3000`
- [ ] ✅ Diagnostic tool test passed: Open `test_chatwoot.html`
- [ ] ✅ Website Token correct: `mYm3V3bEheaSb6GpSHvKKLUn`
- [ ] ✅ Customer service agents online in Chatwoot backend
- [ ] ✅ No CORS errors in browser console
- [ ] ✅ WebSocket connection successful

---

## 🔗 Related Files

- `test_chatwoot.html` - Chatwoot connection diagnostic tool
- `CHATWOOT_TROUBLESHOOTING.md` - Detailed troubleshooting guide
- `CHATWOOT_WEBVIEW_GUIDE.md` - WebView integration complete documentation
- `CHATWOOT_SETUP_GUIDE.md` - Chatwoot setup guide
- `WEB_DEPLOYMENT_GUIDE.md` - Web deployment guide

---

## 🆘 Getting Help

If problem still not resolved, please provide:

1. Screenshot of `test_chatwoot.html` test results
2. Complete error messages from browser console (F12)
3. Detailed problem description (which platform, what operation, what phenomenon)

---

## 📚 Next Steps

Once connection successful, you can:

1. **Customize chat window appearance** - Modify HTML/CSS in `customer_service_page.dart`
2. **Set up automatic user info recognition** - Save userId, userName, userEmail after user login
3. **Configure HTTPS** - Configure SSL certificate according to troubleshooting document
4. **Deploy to production environment** - Check `WEB_DEPLOYMENT_GUIDE.md`

---

**Enjoy using!** 🎉
