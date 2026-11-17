import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({this.baseUrl = AppConstants.defaultApiBaseUrl});

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);
    final condoId = prefs.getInt(AppConstants.keyActiveCondo);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (condoId != null) {
      headers['x-condominio-id'] = condoId.toString();
    }

    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
    return _processResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded['data'] ?? decoded;
    } else {
      final message = decoded['message'] ?? 'Error en la petición';
      final code = decoded['code'] ?? 'API_ERROR';
      throw ApiException(message, code, response.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  ApiException(this.message, this.code, this.statusCode);

  @override
  String toString() => message;
}
