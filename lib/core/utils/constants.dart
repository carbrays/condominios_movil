class AppConstants {
  // En emulador Android usar 10.0.2.2; en dispositivo físico o web usar IP del host
  static const String defaultApiBaseUrl = 'http://10.0.2.2:3000/api/v1';
  static const String defaultSocketUrl = 'http://10.0.2.2:3000';

  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyActiveCondo = 'active_condo';
  static const String keyActiveRole = 'active_role';
  static const String keyPermissions = 'user_permissions';
}
