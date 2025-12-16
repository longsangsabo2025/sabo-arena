# 🚀 SABO Arena - Deployment Guide

*Hướng dẫn deploy SABO Arena lên các platform*

---

## 📱 Android - Google Play Store

### Prerequisites
- Google Play Console account
- Keystore file (đã có tại `certificates/`)
- App signing configured

### Build APK/AAB

```bash
# APK for testing
flutter build apk --release --dart-define-from-file=env.json

# App Bundle for Play Store
flutter build appbundle --release --dart-define-from-file=env.json
```

### Upload Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Update `CHANGELOG.md`
- [ ] Build app bundle
- [ ] Create release notes
- [ ] Upload to Play Console
- [ ] Submit for review

### Play Console Steps

1. Go to [Play Console](https://play.google.com/console)
2. Select SABO Arena app
3. Release > Production
4. Create new release
5. Upload `.aab` file
6. Add release notes (Vietnamese + English)
7. Review and rollout

### Keystore Info
```
Location: certificates/upload-keystore.jks
Alias: upload
Password: [stored in env]
SHA-256: [use get_sha256_fingerprint.bat]
```

---

## 🍎 iOS - App Store

### Prerequisites
- Apple Developer account
- Certificates configured in Xcode
- Provisioning profiles set up

### Build iOS

```bash
# Build iOS release
flutter build ios --release --dart-define-from-file=env.json

# Then archive in Xcode
open ios/Runner.xcworkspace
```

### Xcode Steps

1. Open `ios/Runner.xcworkspace`
2. Select "Any iOS Device" as target
3. Product > Archive
4. Distribute App > App Store Connect
5. Upload

### App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select SABO Arena
3. Add new version
4. Fill metadata:
   - What's New
   - Screenshots
   - Description
5. Select build
6. Submit for review

### Certificates
- Distribution certificate
- Provisioning profile: `SABO Arena AppStore`

---

## 🔧 Codemagic CI/CD

Project đã configured với Codemagic cho automated builds.

### Config Files
- `.codemagic.yaml` - Main config
- `codemagic.yaml` - Alternative config
- `codemagic_clean.yaml` - Clean build config

### Trigger Build

1. Push to `main` branch, hoặc
2. Manual trigger tại [Codemagic Dashboard](https://codemagic.io)

### Build Workflows

| Workflow | Trigger | Output |
|----------|---------|--------|
| Android Release | Tag `v*` | Play Store |
| iOS Release | Tag `v*` | TestFlight |
| Development | PR | APK/IPA |

---

## 🌐 Web Deployment

### Build Web

```bash
flutter build web --release --dart-define-from-file=env.json
```

### Deploy to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
cd build/web
vercel --prod
```

Web app được serve tại: https://saboarena.vercel.app

---

## 📦 Version Management

### Versioning Format
```
version: X.Y.Z+BUILD

X = Major version (breaking changes)
Y = Minor version (new features)
Z = Patch version (bug fixes)
BUILD = Build number (auto-increment)
```

### Update Version

1. Edit `pubspec.yaml`:
```yaml
version: 1.2.3+45
```

2. Update `CHANGELOG.md`

3. Create git tag:
```bash
git tag v1.2.3
git push origin v1.2.3
```

---

## 🔐 Environment Variables

### Production (env.json)
```json
{
  "SUPABASE_URL": "https://xxx.supabase.co",
  "SUPABASE_ANON_KEY": "xxx",
  "GOOGLE_CLIENT_ID": "xxx",
  "FACEBOOK_APP_ID": "xxx"
}
```

### Platform-Specific

**Android** (`android/app/src/main/AndroidManifest.xml`):
- Facebook App ID
- Google Maps API Key
- Deep link scheme

**iOS** (`ios/Runner/Info.plist`):
- Facebook App ID
- URL Schemes
- App Transport Security

---

## 🔄 Pre-Deployment Checklist

### Code Quality
- [ ] Run `flutter analyze` - no errors
- [ ] Run `flutter test` - all tests pass
- [ ] Code reviewed and approved

### Build Verification
- [ ] Clean build successful
- [ ] Test on physical device
- [ ] Check all features work
- [ ] Verify deep links

### Store Metadata
- [ ] Screenshots updated
- [ ] Release notes written
- [ ] Version bumped

### Post-Deployment
- [ ] Monitor crash reports
- [ ] Check user feedback
- [ ] Verify analytics

---

## 🆘 Troubleshooting

### Build Fails

```bash
# Clean everything
flutter clean
rm -rf ios/Pods ios/Podfile.lock
rm -rf android/.gradle

# Reinstall
flutter pub get
cd ios && pod install && cd ..

# Try again
flutter build apk --release
```

### Signing Issues (Android)

```bash
# Regenerate debug keystore
keytool -genkey -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000
```

### Certificate Issues (iOS)

1. Xcode > Preferences > Accounts
2. Download certificates
3. Verify provisioning profiles
4. Clean build folder

### Codemagic Fails

1. Check `codemagic.yaml` syntax
2. Verify environment variables
3. Check build logs
4. Contact Codemagic support

---

## 📊 Release History

| Version | Date | Notes |
|---------|------|-------|
| 1.2.1 | Nov 2024 | SSL Fix, iPad optimization |
| 1.2.0 | Oct 2024 | Tournament system update |
| 1.1.0 | Sep 2024 | Voucher system |
| 1.0.0 | Aug 2024 | Initial release |

---

## 📚 Related Documentation

- [Google Play Checklist](./GOOGLE_PLAY_UPLOAD_CHECKLIST.md)
- [iOS Release Notes](./IOS_RELEASE_NOTES.md)
- [SSL Certificate Fix](./SSL_FIX_SUMMARY.md)
- [Build Success Report](./BUILD_SUCCESS_v1.2.1.md)

---

*Last Updated: November 2025*
