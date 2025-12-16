# 🚀 GitHub Actions CI/CD for SABO ARENA

Hệ thống CI/CD tự động deploy lên cả iOS App Store và Android Play Store.

## 📋 Workflow Files

### 1. `ios-deploy.yml` - iOS App Store Deployment
- ✅ **Tự động build và deploy iOS lên TestFlight**
- 🍎 Chạy trên macOS với Xcode
- 🔐 Code signing tự động
- 📱 Upload lên TestFlight

### 2. `android-deploy.yml` - Android Play Store Deployment  
- ✅ **Tự động build và deploy Android lên Play Store**
- 🤖 Build AAB và APK
- 🔐 Keystore signing tự động
- 📱 Upload lên Play Console Internal Testing

### 3. `deploy-both-platforms.yml` - Combined Deployment
- ✅ **Deploy cả iOS và Android cùng lúc**
- 🎯 Có thể chọn từng platform khi manual trigger
- 📦 Versioning tự động từ Git tags
- 🎉 Thông báo kết quả deployment

## 🚀 Cách sử dụng

### Automatic Deployment (Recommended)
```bash
# Tạo git tag để trigger deployment
git tag v1.0.0
git push origin v1.0.0

# Hoặc push lên main branch (chỉ cho dev testing)
git push origin main
```

### Manual Deployment
1. Vào GitHub → Actions
2. Chọn workflow muốn chạy
3. Click "Run workflow"
4. Chọn branch và options
5. Click "Run workflow"

## 🔧 Setup Requirements

### Bước 1: Setup GitHub Secrets
Xem chi tiết tại: [`docs/GITHUB_SECRETS_SETUP.md`](../docs/GITHUB_SECRETS_SETUP.md)

**iOS Secrets cần thiết:**
- `IOS_DISTRIBUTION_CERTIFICATE_BASE64`
- `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `APP_STORE_CONNECT_API_KEY_BASE64`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`

**Android Secrets cần thiết:**
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `PLAY_STORE_SERVICE_ACCOUNT_JSON`

**Supabase Secrets:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

### Bước 2: Verify iOS Setup
- ✅ Apple Developer Account
- ✅ App Store Connect access
- ✅ Distribution certificate và provisioning profile
- ✅ App Store Connect API key

### Bước 3: Verify Android Setup
- ✅ Google Play Developer Account
- ✅ App uploaded lên Play Console (ít nhất 1 lần manual)
- ✅ Android keystore
- ✅ Google Cloud Service Account với Play Developer API access

## 📱 Deployment Targets

### iOS
- **Target**: TestFlight (App Store Connect)
- **Track**: Production (ready for App Store review)
- **Requirements**: iOS Distribution Certificate + Provisioning Profile

### Android
- **Target**: Play Console Internal Testing
- **Track**: Internal (có thể promote lên alpha/beta/production)
- **Requirements**: Signed AAB + Play Console API access

## 🔍 Monitoring & Debugging

### Check Deployment Status
1. GitHub → Actions tab
2. Click vào workflow run
3. Xem logs từng bước

### Common Issues & Solutions

#### iOS Issues:
```bash
# Certificate không match
❌ Error: No profiles for 'com.sabo_arena.app' were found
✅ Solution: Check provisioning profile bundle ID

# API key không đúng
❌ Error: Invalid API key
✅ Solution: Verify App Store Connect API key và permissions
```

#### Android Issues:
```bash
# Keystore password sai
❌ Error: Keystore was tampered with, or password was incorrect
✅ Solution: Verify keystore password trong GitHub secrets

# Package name không match
❌ Error: Package not found
✅ Solution: Check package name trong Play Console
```

## 📊 Artifacts

Mỗi lần build thành công sẽ tạo artifacts:

### iOS:
- `ios-ipa-{version}` - File .ipa signed cho App Store

### Android:
- `android-aab-{version}` - File .aab cho Play Store
- `android-apk-{version}` - File .apk cho testing
- `android-mapping-{version}` - ProGuard mapping file

## 🎯 Best Practices

### Version Management
```bash
# Semantic versioning
v1.0.0  # Major release
v1.0.1  # Patch/hotfix
v1.1.0  # Minor feature

# Pre-release tags
v1.0.0-beta.1  # Beta version
v1.0.0-rc.1    # Release candidate
```

### Branch Strategy
- `main` - Production-ready code
- `develop` - Development branch
- `feature/*` - Feature branches
- `hotfix/*` - Emergency fixes

### Security
- ❌ **NEVER** commit certificates/keys to repository
- ✅ **ALWAYS** use GitHub Secrets
- ✅ **ROTATE** API keys regularly
- ✅ **LIMIT** permissions to minimum required

## 📞 Support

### Quick Links
- 🍎 [App Store Connect](https://appstoreconnect.apple.com)
- 🤖 [Google Play Console](https://play.google.com/console/)
- 🔧 [GitHub Actions Docs](https://docs.github.com/en/actions)

### Troubleshooting
1. Check GitHub Actions logs
2. Verify all secrets are correctly set
3. Ensure certificates/profiles are not expired
4. Test builds locally first

---

**💡 Pro Tip**: Test với manual deployment trước khi setup automatic deployment với tags!