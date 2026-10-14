class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://paytrack-api.comlekteevyemekleri.com',
  );

  static const bool screenshotDemo = bool.fromEnvironment(
    'SCREENSHOT_DEMO',
    defaultValue: false,
  );
}
