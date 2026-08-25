class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.130:8080',
  );

  static const int demoUserId = int.fromEnvironment(
    'USER_ID',
    defaultValue: 1,
  );
}
