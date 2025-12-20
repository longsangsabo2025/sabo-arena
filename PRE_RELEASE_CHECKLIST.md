# 📋 PRE-RELEASE CHECKLIST - SABO ARENA
**Kiểm tra toàn diện trước khi phát hành lên Google Play & App Store**

*Last Updated: December 20, 2025*
*Version: 1.2.5+40*

---

## 🎯 OVERVIEW

Checklist này đảm bảo app sẵn sàng production với:
- ✅ Code quality & performance
- ✅ Testing coverage (unit, integration, e2e)
- ✅ Store compliance (Google Play & App Store)
- ✅ Security & privacy
- ✅ UI/UX polish
- ✅ Backend readiness

---

## 📱 PHASE 1: CODE QUALITY & ANALYSIS

### 1.1 Static Analysis
```bash
# Run Flutter analyze
flutter analyze

# Expected: 0 errors, 0 warnings
```

**Checklist:**
- [ ] No analysis errors
- [ ] No critical warnings
- [ ] No deprecated API usage
- [ ] All TODO comments reviewed
- [ ] No debug print statements in production code

### 1.2 Code Formatting
```bash
# Format all Dart files
dart format lib/ test/ integration_test/

# Verify no formatting issues
dart format --output=none --set-exit-if-changed lib/
```

**Checklist:**
- [ ] All files properly formatted
- [ ] Consistent naming conventions
- [ ] Proper documentation comments

### 1.3 Dependency Audit
```bash
# Check for outdated packages
flutter pub outdated

# Verify no security vulnerabilities
flutter pub audit
```

**Checklist:**
- [ ] No deprecated dependencies
- [ ] All dependencies up-to-date (or documented why not)
- [ ] No security vulnerabilities
- [ ] License compliance verified

---

## 🧪 PHASE 2: TESTING

### 2.1 Unit Tests
```bash
# Run all unit tests
flutter test test/unit/

# Run with coverage
flutter test --coverage
```

**Target Coverage:** 70%+

**Critical Tests:**
- [ ] `test/unit/tournament_model_test.dart` - Tournament logic
- [ ] `test/unit/services_test.dart` - Core services
- [ ] `test/unit/services/share_service_test.dart` - Sharing functionality
- [ ] Authentication service tests
- [ ] Payment service tests
- [ ] ELO rating calculation tests

### 2.2 Widget Tests
```bash
# Run widget tests
flutter test test/widget/
```

**Checklist:**
- [ ] All critical widgets tested
- [ ] Golden tests updated (if applicable)
- [ ] Responsive layout verified

### 2.3 Integration Tests
```bash
# Run integration tests
flutter test integration_test/
```

**Critical Flows:**
- [ ] `integration_test/tournament_creation_flow_test.dart` - Tournament creation
- [ ] User registration & login flow
- [ ] Tournament participation flow
- [ ] Payment flow (sandbox)
- [ ] Club creation & management

### 2.4 E2E Tests
```bash
# Run E2E tests
flutter drive --target=test_driver/app.dart
```

**Checklist:**
- [ ] Complete user journey tested
- [ ] Cross-platform compatibility (iOS & Android)
- [ ] Network error handling

### 2.5 Performance Tests
**Critical Tests:**
- [ ] `test/e2e/load_testing_integration_test.dart` - Load handling
- [ ] `test/e2e/scaling_infrastructure_test.dart` - Scalability
- [ ] `test/e2e/realtime_batching_test.dart` - Real-time performance

**Metrics:**
- [ ] App launch time < 3 seconds
- [ ] Screen navigation < 300ms
- [ ] API response time < 1 second
- [ ] Memory usage < 200MB
- [ ] No memory leaks

---

## 🔐 PHASE 3: SECURITY & PRIVACY

### 3.1 Authentication & Authorization
**Checklist:**
- [ ] OAuth flows working (Google, Apple, Facebook)
- [ ] Password reset working
- [ ] Session management secure
- [ ] Token refresh working
- [ ] Biometric authentication working (if implemented)

**Tests:**
- [ ] `test/production_readiness_test.dart`
- [ ] Manual testing on real devices

### 3.2 Data Security
**Checklist:**
- [ ] Sensitive data encrypted
- [ ] API keys not exposed in code
- [ ] Environment variables properly configured
- [ ] HTTPS only connections
- [ ] Certificate pinning (if applicable)

**Verify:**
```bash
# Check for exposed secrets
grep -r "SUPABASE_URL" lib/ --exclude-dir=.git
grep -r "api_key" lib/ --exclude-dir=.git
```

### 3.3 Privacy Compliance
**Checklist:**
- [ ] Privacy policy updated
- [ ] Terms of service updated
- [ ] GDPR compliance verified
- [ ] Data deletion implemented
- [ ] User consent flows working
- [ ] Analytics opt-out available

---

## 🗄️ PHASE 4: DATABASE & BACKEND

### 4.1 Supabase Schema Validation
```bash
# Run schema verification
dart scripts/get_live_table_count.dart
```

**Checklist:**
- [ ] All required tables exist
- [ ] RLS policies configured
- [ ] Indexes optimized
- [ ] Foreign keys correct
- [ ] Triggers working

**Reference:**
- [ ] `_DATABASE_INFO/LIVE_SCHEMA_SNAPSHOT.md` - Current schema
- [ ] `_DATABASE_INFO/00_DATABASE_GUIDE.md` - Schema guide

### 4.2 Database Performance
**Tests:**
- [ ] `test/e2e/read_replicas_test.dart` - Read performance
- [ ] `test/e2e/disaster_recovery_test.dart` - Backup & recovery
- [ ] `test/e2e/edge_functions_caching_test.dart` - Caching

**Checklist:**
- [ ] Query performance < 100ms
- [ ] Real-time subscriptions working
- [ ] Connection pooling optimized
- [ ] Backup strategy in place

### 4.3 API Integration
**Checklist:**
- [ ] All Supabase RPCs working
- [ ] Edge Functions deployed
- [ ] Rate limiting configured
- [ ] Error handling robust
- [ ] Retry logic implemented

---

## 🎨 PHASE 5: UI/UX POLISH

### 5.1 Visual Quality
**Checklist:**
- [ ] All screens responsive (phone, tablet, iPad)
- [ ] Dark mode working (if implemented)
- [ ] Animations smooth (60 FPS)
- [ ] Images optimized
- [ ] Icons consistent
- [ ] Typography consistent
- [ ] Color scheme consistent

### 5.2 User Flows
**Critical Flows to Test:**
- [ ] Onboarding flow
- [ ] Tournament discovery → registration → participation
- [ ] Club browsing → joining
- [ ] Profile editing
- [ ] Payment flow
- [ ] Notifications
- [ ] Chat/messaging

### 5.3 Accessibility
**Checklist:**
- [ ] Text scaling working
- [ ] Color contrast sufficient
- [ ] Screen reader support (basic)
- [ ] Touch targets > 44x44
- [ ] Error messages clear

### 5.4 Localization (if applicable)
**Checklist:**
- [ ] Vietnamese translations complete
- [ ] English translations complete
- [ ] RTL support (if needed)
- [ ] Number/date formats correct

---

## 📦 PHASE 6: BUILD & DEPLOYMENT

### 6.1 Android Build
```bash
# Build release APK
flutter build apk --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Build release AAB (for Play Store)
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

**Checklist:**
- [ ] Build succeeds without errors
- [ ] APK size < 100MB
- [ ] Min SDK version correct (21)
- [ ] Target SDK version correct (34+)
- [ ] App signing configured
- [ ] ProGuard rules working

### 6.2 iOS Build
```bash
# Build iOS archive
flutter build ios --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Build IPA
flutter build ipa --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

**Checklist:**
- [ ] Build succeeds without errors
- [ ] IPA size < 200MB
- [ ] Code signing configured
- [ ] Provisioning profiles valid
- [ ] iOS version support (iOS 13+)
- [ ] Bitcode enabled (if required)

### 6.3 CodeMagic Verification
**File:** `codemagic.yaml`

**Checklist:**
- [ ] iOS workflow configured
- [ ] Android workflow configured
- [ ] Environment variables set in CodeMagic UI
- [ ] Code signing certificates uploaded
- [ ] Build triggers configured
- [ ] Auto-increment build number working
- [ ] Distribution to TestFlight working
- [ ] Distribution to Play Console working

**Test Build:**
```bash
# Trigger CodeMagic build manually
# Verify build logs for errors
```

---

## 🏪 PHASE 7: STORE COMPLIANCE

### 7.1 Google Play Store
**App Listing:**
- [ ] App name finalized
- [ ] Short description (80 chars)
- [ ] Full description (4000 chars)
- [ ] Screenshots (phone: 2-8, tablet: 1-8)
- [ ] Feature graphic (1024x500)
- [ ] App icon (512x512)
- [ ] Privacy policy URL
- [ ] Content rating completed

**Technical:**
- [ ] Target API level 34+
- [ ] 64-bit native libraries
- [ ] App signing by Google Play
- [ ] Android App Bundle (.aab)
- [ ] Release notes prepared

### 7.2 Apple App Store
**App Listing:**
- [ ] App name finalized
- [ ] Subtitle (30 chars)
- [ ] Description (4000 chars)
- [ ] Screenshots (iPhone: 6.7", 5.5"; iPad Pro: 12.9", 11")
- [ ] Preview videos (optional)
- [ ] App icon (1024x1024, no transparency)
- [ ] Privacy policy URL
- [ ] Age rating configured

**Technical:**
- [ ] iOS 13+ support
- [ ] iPhone & iPad support
- [ ] TestFlight testing complete
- [ ] Export compliance information
- [ ] App Review information complete
- [ ] Release notes prepared

### 7.3 Store Policies Compliance
**Checklist:**
- [ ] No gambling mechanics (or proper licensing)
- [ ] Payment flow compliant
- [ ] In-app purchases properly implemented
- [ ] Subscription management (if applicable)
- [ ] User data collection disclosed
- [ ] Third-party SDK disclosures
- [ ] Content guidelines followed

---

## 🔔 PHASE 8: NOTIFICATIONS & MESSAGING

### 8.1 Push Notifications
**Checklist:**
- [ ] FCM configured (Android)
- [ ] APNs configured (iOS)
- [ ] Notification permissions working
- [ ] Notification categories configured
- [ ] Deep linking working
- [ ] Background notifications working

**Test:**
- [ ] `test/notification_hooks_test.dart`

### 8.2 In-App Messaging
**Checklist:**
- [ ] Chat functionality working
- [ ] Real-time message delivery
- [ ] Message history loading
- [ ] Typing indicators working
- [ ] Read receipts working

---

## 💳 PHASE 9: PAYMENT INTEGRATION

### 9.1 VNPAY Integration
**Checklist:**
- [ ] Sandbox testing complete
- [ ] Production credentials configured
- [ ] Payment flow working
- [ ] Payment callbacks handled
- [ ] Receipt verification working
- [ ] Refund flow working (if applicable)

### 9.2 In-App Purchases (if applicable)
**Checklist:**
- [ ] Google Play Billing configured
- [ ] Apple StoreKit configured
- [ ] Product IDs configured
- [ ] Purchase flow working
- [ ] Restore purchases working
- [ ] Subscription management working

---

## 📊 PHASE 10: ANALYTICS & MONITORING

### 10.1 Analytics Setup
**Checklist:**
- [ ] Firebase Analytics configured
- [ ] Key events tracked
- [ ] User properties set
- [ ] Conversion tracking
- [ ] Screen view tracking

### 10.2 Crash Reporting
**Checklist:**
- [ ] Firebase Crashlytics configured
- [ ] Crash reporting working
- [ ] Error logs useful
- [ ] Symbolication working (iOS)
- [ ] ProGuard mapping uploaded (Android)

### 10.3 Performance Monitoring
**Checklist:**
- [ ] Firebase Performance configured
- [ ] Network request tracking
- [ ] Screen rendering tracking
- [ ] Custom traces implemented

---

## 🚀 PHASE 11: DEPLOYMENT STRATEGY

### 11.1 Staged Rollout
**Plan:**
1. Internal testing (TestFlight/Internal Testing)
2. Beta testing (100 users)
3. Staged rollout (10% → 25% → 50% → 100%)

**Checklist:**
- [ ] Beta testers recruited
- [ ] Feedback mechanism in place
- [ ] Rollback plan prepared
- [ ] Support team ready

### 11.2 Release Notes
**Checklist:**
- [ ] What's new in this version
- [ ] Bug fixes highlighted
- [ ] New features highlighted
- [ ] Known issues documented
- [ ] Translated to all supported languages

### 11.3 Post-Release Monitoring
**First 24 Hours:**
- [ ] Monitor crash rate (target: < 1%)
- [ ] Monitor ANR rate (target: < 0.5%)
- [ ] Monitor user reviews
- [ ] Monitor backend performance
- [ ] Monitor payment success rate

**First Week:**
- [ ] Daily active users trend
- [ ] Retention rate
- [ ] Key conversion metrics
- [ ] Support ticket volume

---

## 📋 FINAL CHECKLIST

### Pre-Submission
- [ ] All tests passing
- [ ] No critical bugs
- [ ] Performance benchmarks met
- [ ] Security audit passed
- [ ] Privacy compliance verified
- [ ] Store listings complete
- [ ] Screenshots uploaded
- [ ] Release notes prepared

### Submission
- [ ] Android: Upload AAB to Play Console
- [ ] iOS: Upload IPA to App Store Connect
- [ ] Submit for review
- [ ] Monitor review status

### Post-Submission
- [ ] Review approval notifications
- [ ] Release to production
- [ ] Monitor initial metrics
- [ ] Respond to user feedback
- [ ] Prepare hotfix plan (if needed)

---

## 🔧 TOOLS & SCRIPTS

### Automated Checks
```bash
# Run full test suite
./scripts/run_all_tests.sh

# Run performance benchmarks
./scripts/run_performance_tests.sh

# Verify database schema
dart scripts/get_live_table_count.dart

# Check code quality
flutter analyze && dart format --output=none --set-exit-if-changed lib/
```

### Manual Testing Devices
**Minimum:**
- [ ] Android 8.0 (low-end device)
- [ ] Android 14 (high-end device)
- [ ] iOS 13 (iPhone 8)
- [ ] iOS 17 (iPhone 15 Pro)
- [ ] iPad (any recent model)

---

## 📞 SUPPORT CONTACTS

**Team:**
- Tech Lead: [Contact Info]
- QA Lead: [Contact Info]
- Backend Lead: [Contact Info]

**External:**
- CodeMagic Support: support@codemagic.io
- Google Play Support: [Link]
- Apple Developer Support: [Link]

---

## 📚 REFERENCES

**Documentation:**
- [CodeMagic Docs](https://docs.codemagic.io/)
- [Flutter Release Guide](https://docs.flutter.dev/deployment)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://developer.apple.com/app-store-connect/)

**Internal:**
- `_CORE_DOCS_OPTIMIZED/00_START_HERE.md` - Main documentation
- `_DATABASE_INFO/00_DATABASE_GUIDE.md` - Database guide
- `codemagic.yaml` - CI/CD configuration
- `CHANGELOG.md` - Version history

---

## ✅ APPROVAL SIGN-OFF

**Required Approvals:**
- [ ] Tech Lead
- [ ] QA Lead
- [ ] Product Owner
- [ ] Legal/Compliance (if required)

**Final Authorization:**
- [ ] Authorized to submit to Google Play
- [ ] Authorized to submit to App Store

**Submitted By:** _______________
**Date:** _______________
**Build Number:** 1.2.5+40

---

*This checklist ensures SABO Arena meets production standards for both Google Play and App Store.*
