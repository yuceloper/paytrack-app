import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/paytrack_app.dart';
import 'core/auth/auth_session_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/reminder_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  await NotificationService.instance.initialize();

  runApp(const ProviderScope(child: _AuthBootstrapApp()));
}

class _AuthBootstrapApp extends StatefulWidget {
  const _AuthBootstrapApp();

  @override
  State<_AuthBootstrapApp> createState() => _AuthBootstrapAppState();
}

class _AuthBootstrapAppState extends State<_AuthBootstrapApp> {
  late Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _bootstrap = _initialize();
  }

  Future<void> _initialize() async {
    await AuthSessionService.initialize();
    unawaited(_syncRemindersSilently());
  }

  void _retry() {
    setState(() => _bootstrap = _initialize());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('PayTrack hazırlanıyor...'),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'PayTrack sunucusuna bağlanılamadı',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const PayTrackApp();
      },
    );
  }
}

Future<void> _syncRemindersSilently() async {
  try {
    await ReminderSyncService().sync();
  } catch (_) {
    // Reminder synchronization must never block app startup.
  }
}
