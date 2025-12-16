import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> initSentry(Widget app) async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 1.0;
      options.environment = const String.fromEnvironment('ENV', defaultValue: 'development');
      options.enableAutoSessionTracking = true;
      options.attachStacktrace = true;
      options.enableAutoPerformanceTracing = true;
    },
    appRunner: () => runApp(app),
  );
}
