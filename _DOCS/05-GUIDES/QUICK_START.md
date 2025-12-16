# 🚀 SABO Arena - Quick Start Guide

*Hướng dẫn nhanh để bắt đầu development SABO Arena*

---

## 📋 Prerequisites

- **Flutter SDK**: ^3.29.2
- **Dart SDK**: Latest stable
- **IDE**: VS Code / Android Studio
- **Platform Tools**: 
  - Android SDK (for Android)
  - Xcode (for iOS/macOS)

---

## ⚡ Quick Setup

### 1. Clone & Install

```bash
# Navigate to project
cd D:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-arena\app

# Get dependencies
flutter pub get
```

### 2. Environment Setup

Project đã có file `env.json` với config production. Để dev/test:

```bash
# Copy example env
cp .env.example .env

# Edit with your values (optional)
```

### 3. Run App

```bash
# Run with environment
flutter run --dart-define-from-file=env.json

# Or run on specific device
flutter run -d chrome              # Web
flutter run -d emulator-5554       # Android Emulator
flutter run -d "iPhone 15"         # iOS Simulator
```

---

## 🎯 VS Code Tasks (Recommended)

Sử dụng tasks đã config sẵn:

1. Press `Ctrl+Shift+P`
2. Type "Tasks: Run Task"
3. Choose:
   - `Run Flutter App with Supabase`
   - `Run Flutter App on Chrome`
   - `Run Flutter App on Android Emulator`

---

## 🏗️ Build Commands

### Android APK
```bash
flutter build apk --release --dart-define-from-file=env.json
# Output: build/app/outputs/apk/release/app-release.apk
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release --dart-define-from-file=env.json
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release --dart-define-from-file=env.json
# Then archive in Xcode
```

---

## 📁 Key Directories

| Directory | Purpose |
|-----------|---------|
| `lib/` | Main Flutter code |
| `lib/services/` | Business logic |
| `lib/screens/` | UI screens |
| `lib/widgets/` | Reusable widgets |
| `lib/models/` | Data models |
| `scripts/` | Automation scripts |
| `_DOCS/` | Documentation |
| `supabase/` | Database migrations |

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/test_production_bracket_system.dart

# Run with coverage
flutter test --coverage
```

---

## 🔧 Common Commands

```bash
# Clean build
flutter clean && flutter pub get

# Analyze code
flutter analyze

# Format code
dart format .

# Generate icons
flutter pub run flutter_launcher_icons

# Check outdated packages
flutter pub outdated
```

---

## 📊 Database Scripts

```bash
# Check tournament structure
python scripts/test_scripts/check_tournament_structure.py

# Check matches
python scripts/database_utils/check_database_matches.py

# Tournament analyzer
python scripts/tournament_utils/tournament_analyzer.py
```

---

## 🆘 Troubleshooting

### Pod install fails (iOS)
```bash
cd ios && pod install --repo-update && cd ..
```

### Gradle sync issues (Android)
```bash
cd android && ./gradlew clean && cd ..
flutter clean && flutter pub get
```

### Supabase connection issues
- Check `env.json` has correct URL and key
- Verify network connectivity
- Check Supabase dashboard for API status

---

## 📚 Documentation

| Doc | Description |
|-----|-------------|
| [INDEX.md](./_DOCS/INDEX.md) | Full documentation index |
| [Architecture](./_DOCS/01-ARCHITECTURE/) | System design |
| [Features](./_DOCS/02-FEATURES/) | Feature docs |
| [Deployment](./_DOCS/04-DEPLOYMENT/) | Release guides |

---

## 🔗 Important Links

- **Supabase Dashboard**: https://supabase.com/dashboard
- **Firebase Console**: https://console.firebase.google.com
- **Play Console**: https://play.google.com/console
- **App Store Connect**: https://appstoreconnect.apple.com

---

*Happy Coding! 🏆*
