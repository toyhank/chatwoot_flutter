# App Store Rejection Fixes - Summary

This document summarizes the **three** App Store rejection issues that were identified and fixed.

## Issue 1: Profile Settings Tap Not Working on iPad

### Apple's Feedback
> **Guideline**: Bug Description  
> The app exhibited one or more bugs that would negatively impact users.  
> Bug description: no action occurred when we tapped on profile settings.  
> Review device: iPad Air (5th generation), iPadOS 26.2

### Root Cause
In [`user_page.dart`](lib/pages/user/user_page.dart), the user info card displayed interactive visual affordances (right arrow icon and tap ripple effect) regardless of login state, but only performed an action when logged out (navigating to login). When logged in, tapping had no effect, creating a confusing user experience.

### Fix Applied
Modified `_buildUserInfoCard()` to:
- Set `onTap: null` when user is logged in (disables tap feedback)
- Show arrow icon **only** when logged out using conditional rendering: `if (!_isLoggedIn)`

### Result
- **When logged out**: Card shows arrow, taps navigate to login ✅
- **When logged in**: No arrow, no tap feedback (clear non-interactive state) ✅

---

## Issue 2: Permission Language Mismatch

### Apple's Feedback
> **Guideline 4.0 - Design**  
> There is an issue in the app that contributes to a lower-quality user experience than App Store users expect:  
> The app's permissions requests are not written in the same language as the app's primary localization.

### Root Cause
The app's UI is in **English**, but all permission descriptions in [`ios/Runner/Info.plist`](ios/Runner/Info.plist) were written in **Chinese**.

### Fix Applied
Translated all four permission descriptions from Chinese to English:

| Permission | Chinese (Before) | English (After) |
|------------|-----------------|-----------------|
| NSCameraUsageDescription | 需要访问您的相机以拍摄照片发送给客服 | Allow camera access to take and send photos to support |
| NSMicrophoneUsageDescription | 需要访问您的麦克风以发送语音消息 | Allow microphone access to record and send voice messages |
| NSPhotoLibraryUsageDescription | 需要访问您的相册以发送图片给客服 | Allow access to photos to select and send images to support |
| NSPhotoLibraryAddUsageDescription | 需要保存图片到您的相册 | Allow permission to save photos to your library |

### Result
All permission dialogs now display in English, matching the app's primary language ✅

---

## Issue 3: App Name Mismatch

### Apple's Feedback
> The app name displayed on app marketplaces and the app name displayed on the device do not sufficiently match, which makes it difficult for users to find apps they have downloaded.
> 
> - **Marketplace app name**: xxcard
> - **Name displayed on the device**: Testcrm Flutter

### Root Cause
The app's display name was configured as "Testcrm Flutter" in iOS (`CFBundleDisplayName`) and "testcrm_flutter" in Android (`android:label`), but the App Store listing uses "xxcard".

### Fix Applied
Updated app display name to "xxcard" in both platforms:

**iOS** - [`ios/Runner/Info.plist`](ios/Runner/Info.plist):
```xml
<!-- Before -->
<key>CFBundleDisplayName</key>
<string>Testcrm Flutter</string>

<!-- After -->
<key>CFBundleDisplayName</key>
<string>xxcard</string>
```

**Android** - [`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml):
```xml
<!-- Before -->
android:label="testcrm_flutter"

<!-- After -->
android:label="xxcard"
```

### Result
- iOS home screen shows "xxcard" ✅
- Android app drawer shows "xxcard" ✅
- Matches App Store listing ✅
- Bundle Identifier unchanged (as required) ✅

---

## Files Modified

1. [`lib/pages/user/user_page.dart`](lib/pages/user/user_page.dart) - Fixed profile settings tap issue
2. [`ios/Runner/Info.plist`](ios/Runner/Info.plist) - Translated permission strings to English + Changed display name to "xxcard"
3. [`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml) - Changed app label to "xxcard"

## Testing Checklist Before Resubmission

### 1. Profile Settings Fix (iPad Testing Required)
- [ ] Test on iPad simulator (iPad Air 5th gen if available)
- [ ] When **logged out**: Tap profile card → navigates to login
- [ ] When **logged in**: Tap profile card → no action, no arrow icon visible
- [ ] Test on physical iPad device if possible

### 2. Permission Language Fix
- [ ] Build app with updated Info.plist
- [ ] Trigger camera permission → Verify dialog is in English
- [ ] Trigger microphone permission → Verify dialog is in English
- [ ] Trigger photo library permission → Verify dialog is in English
- [ ] Check iOS Settings → [Your App] → Permissions show English descriptions

### 3. App Name Fix
- [ ] Build iOS app → Verify home screen shows "xxcard" (not "Testcrm Flutter")
- [ ] Build Android app → Verify app drawer shows "xxcard" (not "testcrm_flutter")
- [ ] Check iOS Settings → Apps shows "xxcard"
- [ ] Check Android Settings → Apps shows "xxcard"

### 4. General Testing
- [ ] Test core features (login, customer service, etc.)
- [ ] Verify no regressions introduced
- [ ] Test on both iPhone and iPad

## Resubmission Steps

1. **Update version number** in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # Increment build number
   ```

2. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter build ios --release
   ```

3. **Archive and upload** via Xcode or your CI/CD pipeline

4. **Release notes** for App Store submission:
   ```
   Version 1.0.1 - Bug Fixes & Improvements
   
   - Fixed profile settings interaction issue on iPad devices
   - Updated permission descriptions to English to match app language
   - Changed app display name to match App Store listing (xxcard)
   - Enhanced overall user experience and consistency
   ```

5. **Submit for review** and monitor feedback

## Additional Notes

### Future Enhancements (Optional)
If you want to make the logged-in profile card interactive in the future:
- Create a dedicated profile/account page
- Allow users to edit profile information
- Add profile picture upload

### Multi-language Support (Future)
If you plan to support both English and Chinese:
- Create `en.lproj/InfoPlist.strings` and `zh-Hans.lproj/InfoPlist.strings`
- Implement proper app localization using Flutter's internationalization
- Localize all UI strings, not just permissions

---

## Summary

✅ **All three App Store rejection issues have been fixed**  
✅ **Profile settings no longer shows false affordance on iPad**  
✅ **All permission dialogs now display in English**  
✅ **App display name now matches App Store listing ("xxcard")**  
✅ **App is ready for resubmission**

**Files changed**: 3  
**Lines changed**: ~16  
**Testing required**: Manual (iPad + Permission dialogs + App name display)

