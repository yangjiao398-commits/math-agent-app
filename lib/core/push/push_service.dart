import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

/// Push facade.
/// iOS: APNs device token.
/// Android: 个推/极光 + Huawei / Xiaomi / OPPO / vivo vendor channels
/// (vendor SDKs are enabled inside Getui/JPush, not called one by one).
abstract class PushGateway {
  Future<void> initialize();
  Future<String?> deviceToken();
  String get vendor;
  String get platform;
}

class ApnsPushGateway implements PushGateway {
  @override
  String get platform => 'ios';

  @override
  String get vendor => 'apns';

  @override
  Future<void> initialize() async {
    // Wire UIApplication.registerForRemoteNotifications in AppDelegate.
  }

  @override
  Future<String?> deviceToken() async => null;
}

class GetuiPushGateway implements PushGateway {
  GetuiPushGateway({this.fallbackToJPush = false});

  final bool fallbackToJPush;

  @override
  String get platform => 'android';

  @override
  String get vendor => fallbackToJPush ? 'jpush' : 'getui';

  @override
  Future<void> initialize() async {
    // Initialize Getui SDK + manufacturer adapter (Huawei/Xiaomi/OPPO/vivo).
  }

  @override
  Future<String?> deviceToken() async => null;
}

class PushService {
  PushService(this.api, {PushGateway? gateway})
      : gateway = gateway ?? _defaultGateway();

  final ApiClient api;
  final PushGateway gateway;

  static PushGateway _defaultGateway() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return ApnsPushGateway();
    }
    return GetuiPushGateway();
  }

  Future<void> registerIfPossible() async {
    await gateway.initialize();
    final token = await gateway.deviceToken();
    if (token == null || token.isEmpty) return;
    await api.post('/api/app/devices', {
      'platform': gateway.platform,
      'vendor': gateway.vendor,
      'push_token': token,
    });
  }
}
