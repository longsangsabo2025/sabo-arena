# 🔍 Sentry Integration Guide - SABO Arena

**Status:** ✅ Pattern Created | ⏳ Integration Pending

---

## 📋 Overview

Sentry is already in `pubspec.yaml` but needs to be initialized in `main.dart`.

---

## 🔧 Integration Steps

### 1. Initialize Sentry in main.dart

Wrap the app initialization with `SentryFlutter.init()`:

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  LongSangErrorReporter.init(() async {
    await SentryFlutter.init(
      (options) {
        options.dsn = const String.fromEnvironment('SENTRY_DSN');
        options.environment = const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
        options.tracesSampleRate = 1.0; // 100% in development
        options.enableAutoPerformanceTracing = true;
        options.attachScreenshot = true;
        options.attachViewHierarchy = true;
      },
      appRunner: () async {
        WidgetsFlutterBinding.ensureInitialized();
        
        // ... rest of initialization
        runApp(MyApp());
      },
    );
  }, appName: 'sabo-arena');
}
```

### 2. Add Environment Variables

**For development:**
```bash
flutter run --dart-define=SENTRY_DSN=your-dsn-here --dart-define=ENVIRONMENT=development
```

**For production:**
- Set in CI/CD pipeline
- Or use `--dart-define-from-file=.env` (create `.env` file)

---

## ✅ Benefits

1. ✅ Automatic error tracking
2. ✅ Performance monitoring
3. ✅ User session replay
4. ✅ Crash reports with stack traces
5. ✅ Integration with StandardizedErrorHandler

---

## 📝 Next Steps

1. Add Sentry initialization to main.dart
2. Set up environment variables
3. Test error reporting
4. Monitor Sentry dashboard

---

**Last Updated:** January 2025

