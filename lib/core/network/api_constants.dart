class ApiConstants {
  // Base URLs
  static const String authBaseUrl = 'http://54.241.200.172:8801';
  static const String apiBaseUrl = 'http://54.241.200.172:8800';

  // Auth Endpoints
  static const String tokenEndpoint = '/auth-ws/oauth2/token';

  // API Endpoints
  static const String updateAppEndpoint = '/setup-ws/api/v1/app/update-app/2';
  static const String getAppsEndpoint = '/setup-ws/api/v1/app/get-permitted-apps';

  // Auth Credentials
  static const String basicAuth = 'Basic Y2xpZW50OnNlY3JldA==';
  static const String username = 'abir';
  static const String password = 'ati123';
  static const String grantType = 'password';
  static const String scope = 'profile';

  // Company ID
  static const int companyId = 2;

  // Transfer Settings
  static const int maxRetries = 3;
  static const int timeoutSeconds = 300; // 5 minutes
  static const int chunkSize = 1024 * 1024; // 1MB chunks
}