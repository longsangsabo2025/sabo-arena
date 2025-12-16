# 🚀 HƯỚNG DẪN BUILD & DEPLOY - iOS SSL FIX

## 📋 Checklist trước khi deploy

### ✅ Code Changes
- [x] SSL Certificate Handler mới: `lib/services/ssl_certificate_handler.dart`
- [x] Supabase Service updated: `lib/services/supabase_service.dart`
- [x] Loại bỏ `badCertificateCallback` bypass
- [x] Sử dụng system trust store

### ✅ Testing Local
```bash
# 1. Test script
flutter run test_ssl_certificate_fix.dart

# 2. Run app debug mode
flutter run -d chrome --dart-define=SUPABASE_URL=https://mogjjvscxjwvhtpkrlqr.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ
```

---

## 🔨 Build iOS Release

### Bước 1: Clean Build
```bash
flutter clean
flutter pub get
```

### Bước 2: Verify Dependencies
```bash
flutter doctor -v
```

Ensure:
- ✅ Flutter SDK installed
- ✅ Xcode installed
- ✅ CocoaPods installed
- ✅ iOS deployment target matches

### Bước 3: Build iOS Release
```bash
cd ios
pod install --repo-update
cd ..

flutter build ios --release \
  --dart-define=SUPABASE_URL=https://mogjjvscxjwvhtpkrlqr.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ
```

### Bước 4: Open Xcode
```bash
open ios/Runner.xcworkspace
```

---

## 📱 Deploy to TestFlight

### Via Xcode:

1. **Select Device**: 
   - Menu: Product > Destination > Any iOS Device

2. **Archive Build**:
   - Menu: Product > Archive
   - Wait for build to complete

3. **Validate App**:
   - Window > Organizer > Archives
   - Click "Validate App"
   - Check all validations pass

4. **Upload to App Store Connect**:
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Upload binary

5. **Process on App Store Connect**:
   - Wait ~5-10 minutes for processing
   - App will appear in TestFlight

---

## 🧪 Test trên TestFlight

### Bước 1: Add Internal Testers
- App Store Connect > TestFlight
- Add internal testers (team members)

### Bước 2: Test Scenarios

#### ✅ Test 1: Login Flow
```
1. Mở app
2. Login với user
3. Check profile load
4. ✅ Không có lỗi SSL
```

#### ✅ Test 2: Network Switch
```
1. Login với WiFi
2. Switch sang Mobile Data
3. Reload profile
4. ✅ Vẫn hoạt động bình thường
```

#### ✅ Test 3: Cold Start
```
1. Force close app
2. Mở lại app
3. Check auto-login
4. ✅ SSL handshake thành công
```

#### ✅ Test 4: Different iOS Versions
```
Test trên:
- iOS 15.x
- iOS 16.x
- iOS 17.x
- ✅ Tất cả version hoạt động
```

---

## 🔍 Verify Fix Success

### Logs to check:
```
✅ GOOD LOGS:
🔐 SSL: Using production-grade certificate validation
✅ Supabase connection verified
✅ Supabase initialized successfully!

❌ BAD LOGS:
❌ CERTIFICATE_VERIFY_FAILED
❌ Handshake error
❌ SSL handshake failed
```

### User Experience:
```
✅ BEFORE FIX:
- Red error message
- Cannot load profile
- Cannot login
- App crashes

✅ AFTER FIX:
- No error messages
- Profile loads instantly
- Login works smoothly
- App stable
```

---

## 🆘 Troubleshooting

### Issue 1: Build fails in Xcode
```bash
# Solution: Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
cd ios
pod deintegrate
pod install
```

### Issue 2: CocoaPods error
```bash
# Solution: Update CocoaPods
sudo gem install cocoapods
cd ios
pod repo update
pod install
```

### Issue 3: Provisioning profile error
```
Solution:
1. Xcode > Preferences > Accounts
2. Select Apple ID
3. Download Manual Profiles
4. Retry archive
```

### Issue 4: Still getting SSL error on device
```
Check:
1. Device date/time correct?
2. iOS version updated?
3. Network allows HTTPS?
4. Clear app data and reinstall?
```

---

## 📊 Deployment Checklist

### Pre-Deploy:
- [ ] Code reviewed
- [ ] Local testing passed
- [ ] Clean build successful
- [ ] Archive created
- [ ] Validation passed

### Deploy:
- [ ] Upload to TestFlight
- [ ] Internal testing passed
- [ ] No SSL errors in logs
- [ ] All features working

### Post-Deploy:
- [ ] Monitor crash reports
- [ ] Check user feedback
- [ ] Verify analytics
- [ ] Document any issues

---

## 🎯 Success Criteria

### ✅ Fix is successful if:
1. No `CERTIFICATE_VERIFY_FAILED` errors
2. Users can login normally
3. Profile loads without errors
4. App passes all TestFlight tests
5. No increase in crash rate

### 📈 Metrics to monitor:
- Crash-free rate (should remain > 99%)
- Login success rate (should be > 95%)
- API call success rate (should be > 98%)
- User complaints (should decrease)

---

## 🔄 Rollback Plan

### If fix doesn't work:

1. **Immediate**: 
   ```bash
   git revert <commit-hash>
   ```

2. **Rebuild**:
   ```bash
   flutter clean
   flutter build ios --release
   ```

3. **Re-deploy**:
   - Archive in Xcode
   - Upload to TestFlight
   - Mark as emergency fix

4. **Investigate**:
   - Check crash logs
   - Review Supabase logs
   - Test on physical device
   - Add more debugging

---

## 📞 Support Contacts

### If issues persist:

1. **Supabase Support**:
   - support@supabase.com
   - Discord: supabase.com/discord

2. **Flutter Issues**:
   - GitHub: flutter/flutter
   - Stack Overflow: [flutter] [ssl]

3. **iOS Certificates**:
   - Apple Developer Support
   - developer.apple.com

---

## ✅ Final Verification

Before submitting to App Store:

```bash
# Run final tests
flutter test
flutter analyze
flutter build ios --release

# Check file sizes
ls -lh build/ios/iphoneos/*.app

# Verify provisioning
codesign -dv build/ios/iphoneos/Runner.app
```

---

**Status**: Ready for deployment! 🚀
**Next Step**: Build → TestFlight → Production
