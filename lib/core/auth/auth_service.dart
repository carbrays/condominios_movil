import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../utils/constants.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService({required this.apiClient});

  Future<Map<String, dynamic>> login(String ci, String password) async {
    final response = await apiClient.post('/auth/login', {
      'ci': ci.trim(),
      'password': password,
    });

    final prefs = await SharedPreferences.getInstance();
    final tokens = response['tokens'];
    final usuario = response['usuario'];
    final activo = response['condominioActivo'];
    final permisos = response['permisos'] as List? ?? [];

    await prefs.setString(AppConstants.keyAccessToken, tokens['accessToken']);
    await prefs.setString(AppConstants.keyRefreshToken, tokens['refreshToken']);
    await prefs.setString(AppConstants.keyUserData, jsonEncode(usuario));
    await prefs.setString(AppConstants.keyPermissions, jsonEncode(permisos));

    if (activo != null) {
      final condoId = int.tryParse(activo['id'].toString()) ?? (activo['id'] as int? ?? 0);
      await prefs.setInt(AppConstants.keyActiveCondo, condoId);
      await prefs.setString(AppConstants.keyActiveRole, activo['rol_id']?.toString() ?? '');
    }

    return response;
  }

  Future<void> seleccionarCondominio(int condominioId) async {
    final response = await apiClient.post('/auth/condominio/seleccionar', {
      'condominio_id': condominioId,
    });

    final prefs = await SharedPreferences.getInstance();
    final tokens = response['tokens'];
    final activo = response['condominioActivo'];
    final permisos = response['permisos'] as List? ?? [];

    await prefs.setString(AppConstants.keyAccessToken, tokens['accessToken']);
    await prefs.setString(AppConstants.keyRefreshToken, tokens['refreshToken']);
    await prefs.setString(AppConstants.keyPermissions, jsonEncode(permisos));
    if (activo != null) {
      final condoId = int.tryParse(activo['id'].toString()) ?? (activo['id'] as int? ?? 0);
      await prefs.setInt(AppConstants.keyActiveCondo, condoId);
      await prefs.setString(AppConstants.keyActiveRole, activo['rol_id']?.toString() ?? '');
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getActiveRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyActiveRole);
  }

  Future<int?> getActiveCondoId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyActiveCondo);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyUserData);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
