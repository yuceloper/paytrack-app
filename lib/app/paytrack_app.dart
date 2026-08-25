import 'package:flutter/material.dart';
import 'main_shell.dart';

class PayTrackApp extends StatelessWidget {
  const PayTrackApp({super.key});

  static const _seedColor = Color(0xFF3157D5);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PayTrack',
      themeMode: ThemeMode.system,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const MainShell(),
    );
  }

  static ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          brightness == Brightness.light ? const Color(0xFFF6F7FB) : scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceTint,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
      ),
    );
  }
}
