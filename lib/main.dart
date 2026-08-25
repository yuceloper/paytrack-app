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
  await AuthSessionService.initialize();

  runApp(const ProviderScope(child: PayTrackApp()));
  unawaited(_syncRemindersSilently());
}

Future<void> _syncRemindersSilently() async {
  try {
    await ReminderSyncService().sync();
  } catch (_) {
    // Reminder synchronization must never block app startup.
  }
}
