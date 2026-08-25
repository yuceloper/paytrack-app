import '../auth/session_store.dart';

class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.130:8080',
  );

  static int get demoUserId => SessionStore.userId ?? 1;
}
