import 'package:flutter/material.dart';
import 'core/auth/auth_service.dart';
import 'core/api/api_client.dart';
import 'core/socket/socket_service.dart';
import 'core/utils/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CondominiosApp());
}

class CondominiosApp extends StatefulWidget {
  const CondominiosApp({super.key});

  @override
  State<CondominiosApp> createState() => _CondominiosAppState();
}

class _CondominiosAppState extends State<CondominiosApp> {
  final AuthService _authService = AuthService(apiClient: ApiClient());
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      // Conectar socket en background
      SocketService.instance.connect();
    }
    setState(() {
      _isLoggedIn = loggedIn;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Condominios Suite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isChecking
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (_isLoggedIn ? const HomeScreen() : const LoginScreen()),
    );
  }
}
