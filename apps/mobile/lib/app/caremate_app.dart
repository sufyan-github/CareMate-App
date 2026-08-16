import 'package:caremate/app/theme/caremate_theme.dart';
import 'package:caremate/features/auth/application/auth_coordinator.dart';
import 'package:caremate/features/auth/data/http_auth_gateway.dart';
import 'package:caremate/features/auth/data/secure_session_store.dart';
import 'package:caremate/features/auth/presentation/auth_flow_page.dart';
import 'package:caremate/features/shell/presentation/app_shell.dart';
import 'package:flutter/material.dart';

class CareMateApp extends StatefulWidget {
  const CareMateApp({this.authCoordinator, super.key});

  final AuthCoordinator? authCoordinator;

  @override
  State<CareMateApp> createState() => _CareMateAppState();
}

class _CareMateAppState extends State<CareMateApp> {
  late final AuthCoordinator _authCoordinator;
  late final bool _ownsCoordinator;

  @override
  void initState() {
    super.initState();
    _ownsCoordinator = widget.authCoordinator == null;
    _authCoordinator =
        widget.authCoordinator ??
        AuthCoordinator(
          gateway: HttpAuthGateway(
            baseUrl: const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:3000/api/v1',
            ),
          ),
          sessionStore: SecureSessionStore(),
        );
    _authCoordinator.initialize();
  }

  @override
  void dispose() {
    if (_ownsCoordinator) _authCoordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareMate',
      theme: CareMateTheme.light,
      darkTheme: CareMateTheme.dark,
      themeMode: ThemeMode.system,
      home: AnimatedBuilder(
        animation: _authCoordinator,
        builder: (context, _) => switch (_authCoordinator.status) {
          AuthStatus.restoring => const _RestoringSessionPage(),
          AuthStatus.signedIn => AppShell(onLogout: _authCoordinator.logout),
          AuthStatus.signedOut ||
          AuthStatus.awaitingOtp => AuthFlowPage(coordinator: _authCoordinator),
        },
      ),
    );
  }
}

class _RestoringSessionPage extends StatelessWidget {
  const _RestoringSessionPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Restoring your secure CareMate session',
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
