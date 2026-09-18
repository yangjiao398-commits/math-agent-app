import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'core/api/api_client.dart';
import 'core/auth/session.dart';
import 'core/push/push_service.dart';
import 'core/webview/setup.dart'
    if (dart.library.html) 'core/webview/setup_web.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupWebView();
  final api = ApiClient();
  runApp(MathAgentApp(api: api));
}

class MathAgentApp extends StatelessWidget {
  const MathAgentApp({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(create: (_) => SessionController(api)..restore()),
        Provider(create: (_) => PushService(api)),
      ],
      child: MaterialApp(
        title: '数理助理',
        theme: AppTheme.light(),
        home: const _Gate(),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    if (session.signedIn) return const HomePage();
    return const LoginPage();
  }
}
