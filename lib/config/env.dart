import 'package:flutter/foundation.dart';

/// Runtime config. Override at build time:
/// flutter run --dart-define=API_BASE=https://api.math-agent.cn
class AppEnv {
  static const _defineBase = String.fromEnvironment('API_BASE');
  static const cdnBase = String.fromEnvironment('CDN_BASE');
  static const androidPush = String.fromEnvironment(
    'ANDROID_PUSH',
    defaultValue: 'getui',
  );

  static String get apiBase {
    if (_defineBase.isNotEmpty) return _defineBase;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3010';
    }
    return 'http://127.0.0.1:3010';
  }
}

