import 'package:flutter/material.dart';
import 'main_shell.dart';

class PayTrackApp extends StatelessWidget {
  const PayTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PayTrack',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3157D5)),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const MainShell(),
    );
  }
}
