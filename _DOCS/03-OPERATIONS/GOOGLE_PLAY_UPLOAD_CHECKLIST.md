# Google Play Store Upload Checklist - SABO Arena

**Ngày kiểm tra:** 2025-11-09  
**Version:** 1.2.0+35  
**Build Type:** Release AAB (Android App Bundle)

---

## ✅ CHECKLIST TRƯỚC KHI UPLOAD

### 📱 App Configuration

#### 1. Version Information
- [x] **App Version:** `1.2.0+35` (pubspec.yaml)
- [x] **Version Code:** 35 (tự động từ Flutter)
- [x] **Version Name:** 1.2.0
- [x] **Application ID:** com.sabo_arena.app
- [ ] **Đã tăng version code so với bản trước?** (Cần kiểm tra Google Play Console)

#### 2. Build Configuration (android/app/build.gradle)
- [x] **compileSdk:** 36 ✅
- [x] **targetSdk:** 36 ✅ (Google yêu cầu targetSdk 34+ từ 31/08/2024)
- [x] **minSdk:** 24 ✅
- [x] **multiDexEnabled:** true ✅
- [x] **Release Optimizations:**
  - [x] minifyEnabled: true ✅
  - [x] shrinkResources: true ✅
  - [x] proguard-android-optimize.txt ✅
  - [x] zipAlignEnabled: true ✅
  - [x] debuggable: false ✅

#### 3. Signing Configuration
- [x] **Keystore file exists:** `sabo-arena-release-key.keystore` ✅
- [x] **key.properties configured:**
  - [x] storePassword: Acookingoil123
  - [x] keyPassword: Acookingoil123
  - [x] keyAlias: sabo-arena
  - [x] storeFile: sabo-arena-release-key.keystore
- [ ] **Keystore backup saved securely?** (Rất quan trọng!)

#### 4. Permissions (AndroidManifest.xml)
- [x] INTERNET ✅
- [x] ACCESS_FINE_LOCATION ✅
- [x] ACCESS_COARSE_LOCATION ✅
- [x] CAMERA ✅
- [x] READ_EXTERNAL_STORAGE ✅
- [x] READ_MEDIA_IMAGES ✅ (Android 13+)
- [x] WRITE_EXTERNAL_STORAGE ✅
- [x] READ_MEDIA_VIDEO ✅ (Android 13+)

#### 5. Deep Links Configuration
- [x] **Custom scheme:** saboarena:// ✅
- [x] **HTTPS links:** saboarena.com ✅
- [x] **autoVerify:** true ✅
- [ ] **Digital Asset Links file uploaded?** (https://saboarena.com/.well-known/assetlinks.json)

#### 6. Icons & Branding
- [x] **App Icon:** assets/images/logo.png ✅
- [x] **Adaptive Icon Background:** #1E8A6F ✅
- [x] **App Label:** "SABO Arena" ✅
- [ ] **Feature Graphic (1024x500)** - Cần cho Google Play Store
- [ ] **Screenshots (phone + tablet)** - Tối thiểu 2 ảnh

---

## ⚠️ VẤN ĐỀ CẦN SỬA

### 🔴 CRITICAL (Phải sửa trước khi upload)

1. **Google Maps API Key Missing**
   ```xml
   <!-- File: android/app/src/main/AndroidManifest.xml line 83 -->
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />  ❌ Placeholder
   ```
   **Action Required:** Replace with real API key or remove if not using Google Maps

### 🟡 WARNING (Nên sửa)

2. **usesCleartextTraffic: true**
   ```xml
   <!-- File: android/app/src/main/AndroidManifest.xml line 29 -->
   android:usesCleartextTraffic="true"  ⚠️ Security risk
   ```
   **Recommended:** Change to `false` nếu app chỉ dùng HTTPS

3. **Version Code**
   - Version code 35 có thể conflict nếu bản cũ trên Play Store cao hơn
   - Cần check Google Play Console để biết version code hiện tại

---

## 🔧 BUILD STEPS

### Bước 1: Clean build
```bash
flutter clean
flutter pub get
```

### Bước 2: Build AAB (Production)
```bash
flutter build appbundle --release
```

Hoặc với Supabase credentials:
```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://mogjjvscxjwvhtpkrlqr.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ
```

### Bước 3: Verify AAB file
```bash
# File sẽ được tạo tại:
# build/app/outputs/bundle/release/app-release.aab

# Check file size (nên < 150MB)
ls -lh build/app/outputs/bundle/release/app-release.aab
```

### Bước 4: Test AAB locally (Optional)
```bash
# Install bundletool
# Download: https://github.com/google/bundletool/releases

# Generate APKs from AAB
java -jar bundletool-all-1.15.6.jar build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=app.apks \
  --ks=android/app/sabo-arena-release-key.keystore \
  --ks-pass=pass:Acookingoil123 \
  --ks-key-alias=sabo-arena \
  --key-pass=pass:Acookingoil123

# Install on connected device
java -jar bundletool-all-1.15.6.jar install-apks --apks=app.apks
```

---

## 📤 UPLOAD TO GOOGLE PLAY CONSOLE

### Checklist trước khi upload:

1. **Production Track**
   - [ ] Version code > version hiện tại trên Play Store
   - [ ] Release notes đã chuẩn bị (tiếng Việt + English)
   - [ ] Targeting Android 14 (API 34+) ✅

2. **Store Listing**
   - [ ] App name: "SABO Arena"
   - [ ] Short description (80 chars)
   - [ ] Full description (4000 chars)
   - [ ] Screenshots (2-8 ảnh)
   - [ ] Feature graphic (1024x500)
   - [ ] App icon (512x512)
   - [ ] Privacy policy URL
   - [ ] Category: Games > Sports

3. **Content Rating**
   - [ ] Questionnaire completed
   - [ ] Rating certificate obtained

4. **Pricing & Distribution**
   - [ ] Countries selected
   - [ ] Pricing: Free or Paid
   - [ ] Content guidelines accepted

5. **App Content**
   - [ ] Privacy policy
   - [ ] Data safety section filled
   - [ ] Ads declaration (if applicable)
   - [ ] Target audience set

### Upload process:
1. Go to: https://play.google.com/console
2. Select "SABO Arena" app
3. Production → Create new release
4. Upload `app-release.aab`
5. Fill release notes
6. Review and publish

---

## 🧪 TESTING CHECKLIST

### Before Upload:
- [ ] App launches successfully
- [ ] Login/Register works
- [ ] Deep links work (QR code scan)
- [ ] Push notifications work
- [ ] Payment integration works (if any)
- [ ] No crashes on startup
- [ ] Permissions requested properly
- [ ] Network requests work (Supabase)

### After Upload (Internal Testing):
- [ ] Install from Play Console (Internal testing track)
- [ ] Test all core features
- [ ] Check analytics/crash reporting
- [ ] Verify in-app updates work

---

## 📋 RELEASE NOTES TEMPLATE

### Version 1.2.0 (Build 35)

**Tiếng Việt:**
```
🎉 Cập nhật mới:
• Sửa lỗi QR code không dẫn đến trang profile người dùng
• Tối ưu hiệu suất cho iPad và tablet
• Cải thiện giao diện responsive trên màn hình lớn
• Thêm keyboard shortcuts cho iPad
• Tối ưu tốc độ load hình ảnh (nhanh hơn 60%)
• Sửa lỗi nhỏ và cải thiện hiệu suất

🐛 Bug fixes:
• Deep link navigation đã hoạt động đúng
• Pinch-to-zoom cho tournament brackets
• OptimizedListView cho scrolling mượt hơn
```

**English:**
```
🎉 What's New:
• Fixed QR code not navigating to user profile
• iPad and tablet performance optimization
• Improved responsive UI for larger screens
• Added keyboard shortcuts for iPad
• Optimized image loading (60% faster)
• Minor bug fixes and performance improvements

🐛 Bug Fixes:
• Deep link navigation now works correctly
• Pinch-to-zoom for tournament brackets
• OptimizedListView for smoother scrolling
```

---

## 🚨 TROUBLESHOOTING

### Build fails with "Duplicate class" error:
```bash
# Clean và rebuild
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
flutter build appbundle --release
```

### Keystore password error:
```bash
# Verify key.properties has correct passwords
cat android/key.properties
```

### ProGuard/R8 issues:
```bash
# Check proguard-rules.pro
# Add keep rules for libraries causing issues
```

### Size too large (>150MB):
```bash
# Enable app bundle splitting
# Check build.gradle for split configurations
```

---

## ✅ FINAL CHECKLIST BEFORE SUBMIT

- [ ] ✅ AAB file built successfully
- [ ] ✅ File size < 150MB
- [ ] ✅ Version code incremented
- [ ] ✅ Keystore signed correctly
- [ ] ⚠️  Google Maps API key replaced (or removed)
- [ ] ⚠️  usesCleartextTraffic set to false (if possible)
- [ ] ✅ Release notes prepared
- [ ] ✅ Screenshots uploaded
- [ ] ✅ Store listing complete
- [ ] ✅ Tested on real device
- [ ] ✅ Deep links verified
- [ ] ⚠️  Digital Asset Links file uploaded (for deep links)

---

## 📞 SUPPORT

If build fails:
1. Check error logs: `flutter build appbundle --release --verbose`
2. Check Android Studio logs
3. Check proguard mapping: `android/app/build/outputs/mapping/release/mapping.txt`

**Status:** ⚠️ **NEEDS FIXES BEFORE UPLOAD**
- Fix Google Maps API key
- Consider disabling cleartext traffic
- Verify version code with Play Console

**Next Steps:**
1. Run `flutter clean && flutter build appbundle --release`
2. Fix Google Maps API key issue
3. Upload AAB to Google Play Console Internal Testing track first
4. Test thoroughly before promoting to Production
