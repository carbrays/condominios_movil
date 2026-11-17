import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/api/api_client.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _ciController = TextEditingController(text: '3000003'); // Demo conserje
  final _passController = TextEditingController(text: 'password123');
  bool _isLoading = false;
  String? _errorMessage;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(apiClient: ApiClient());
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.login(_ciController.text, _passController.text);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _fillDemo(String ci) {
    _ciController.text = ci;
    _passController.text = 'password123';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  size: 72,
                  color: Color(0xFF1E3A8A),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gestión de Condominios',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingrese con su Cédula de Identidad (CI)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(left: BorderSide(color: Colors.red, width: 4)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFF991B1B)),
                    ),
                  ),
                TextField(
                  controller: _ciController,
                  decoration: const InputDecoration(
                    labelText: 'Cédula de Identidad (CI)',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Iniciar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Cuentas Demo Rápidas:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    ActionChip(label: const Text('Conserje'), onPressed: () => _fillDemo('3000003')),
                    ActionChip(label: const Text('Propietario'), onPressed: () => _fillDemo('4000004')),
                    ActionChip(label: const Text('Inquilino'), onPressed: () => _fillDemo('5000005')),
                    ActionChip(label: const Text('Admin'), onPressed: () => _fillDemo('2000002')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
