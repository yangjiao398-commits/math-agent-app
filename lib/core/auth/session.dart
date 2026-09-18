import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

class SessionController extends ChangeNotifier {
  SessionController(this.api);

  final ApiClient api;
  String? token;
  Map<String, dynamic>? user;
  Map<String, dynamic>? remoteConfig;
  String? error;

  bool get signedIn => token != null && token!.isNotEmpty;
  bool get entitled =>
      user?['membership'] is Map && user!['membership']['entitled'] == true;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    api.setToken(token);
    try {
      remoteConfig = await api.get('/api/app/config');
    } catch (_) {
      remoteConfig = null;
    }
    if (signedIn) {
      try {
        final me = await api.get('/api/app/me');
        user = me['user'] as Map<String, dynamic>?;
      } on ApiException catch (e) {
        if (e.needsLogin) await signOut();
      }
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> sendSms(String phone) {
    return api.post('/api/app/auth/sms', {'phone': phone});
  }

  Future<void> login(String phone, String code) async {
    error = null;
    final data = await api.post('/api/app/auth/login', {
      'phone': phone,
      'code': code,
    });
    token = data['token'] as String?;
    user = data['user'] as Map<String, dynamic>?;
    api.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token ?? '');
    notifyListeners();
  }

  Future<void> refreshMe() async {
    if (!signedIn) return;
    final me = await api.get('/api/app/me');
    user = me['user'] as Map<String, dynamic>?;
    notifyListeners();
  }

  Future<void> signOut() async {
    token = null;
    user = null;
    api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}
