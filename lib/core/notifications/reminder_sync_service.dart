import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/incomes/data/income_repository.dart';
import '../../features/payments/data/models/payment_item.dart';
import '../../features/payments/data/payment_repository.dart';
import 'notification_preferences.dart';
import 'notification_service.dart';

class ReminderSyncService {
  ReminderSyncService({
    PaymentRepository? paymentRepository,
    IncomeRepository? incomeRepository,
    NotificationService? notificationService,
    NotificationPreferencesStore? preferencesStore,
  })  : _paymentRepository = paymentRepository ?? PaymentRepository(),
        _incomeRepository = incomeRepository ?? IncomeRepository(),
        _notificationService = notificationService ?? NotificationService.instance,
        _preferencesStore = preferencesStore ?? NotificationPreferencesStore();

  static const int _maxScheduledNotifications = 60;
  static const int _lookAheadDays = 35;

  final PaymentRepository _paymentRepository;
  final IncomeRepository _incomeRepository;
  final NotificationService _notificationService;
  final NotificationPreferencesStore _preferencesStore;

  Future<int> sync() async {
    await _notificationService.initialize();
    await _notificationService.clearPayTrackReminders();

    final preferences = await _preferencesStore.load();
    if (!preferences.enabled) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: _lookAheadDays));

    final payments = await _paymentRepository.getPayments(from: today, to: end);
    final incomes = await _loadIncomes(today, end);

    var scheduled = 0;

    for (final payment in payments.where((item) => !item.paid)) {
      if (scheduled >= _maxScheduledNotifications) break;
      scheduled += await _schedulePayment(payment, now, today, scheduled, preferences);
    }

    for (final income in incomes.where((item) => !item.received)) {
      if (scheduled >= _maxScheduledNotifications) break;
      scheduled += await _scheduleIncome(income, now, today, scheduled, preferences);
    }

    return scheduled;
  }

  Future<List<IncomeOccurrenceItem>> _loadIncomes(DateTime from, DateTime to) async {
    final result = <IncomeOccurrenceItem>[];
    var month = DateTime(from.year, from.month, 1);
    final lastMonth = DateTime(to.year, to.month, 1);

    while (!month.isAfter(lastMonth)) {
      final items = await _incomeRepository.fetchMonth(month);
      result.addAll(items.where(
        (item) => !item.expectedDate.isBefore(from) && !item.expectedDate.isAfter(to),
      ));
      month = DateTime(month.year, month.month + 1, 1);
    }

    result.sort((a, b) => a.expectedDate.compareTo(b.expectedDate));
    return result;
  }

  Future<int> _schedulePayment(
    PaymentItem payment,
    DateTime now,
    DateTime today,
    int alreadyScheduled,
    NotificationPreferences preferences,
  ) async {
    final due = DateTime(payment.dueDate.year, payment.dueDate.month, payment.dueDate.day);
    final amount = _money(payment.amount);
    var count = 0;

    if (due.isBefore(today)) {
      if (preferences.overdueEnabled && alreadyScheduled + count < _maxScheduledNotifications) {
        await _notificationService.scheduleReminder(
          id: _paymentNotificationId(payment.id, 3),
          title: 'Ödeme gecikti',
          body: '${payment.name} • $amount',
          dateTime: now.add(const Duration(seconds: 4)),
          payload: 'payment:${payment.id}:overdue',
        );
        count++;
      }
      return count;
    }

    if (_sameDay(due, today)) {
      if (preferences.dueDayEnabled && alreadyScheduled + count < _maxScheduledNotifications) {
        final dueTime = _atTime(due, preferences.dueDayTime);
        await _notificationService.scheduleReminder(
          id: _paymentNotificationId(payment.id, 2),
          title: 'Bugün ödeme var',
          body: '${payment.name} • $amount',
          dateTime: dueTime.isAfter(now) ? dueTime : now.add(const Duration(seconds: 4)),
          payload: 'payment:${payment.id}:today',
        );
        count++;
      }
      return count;
    }

    if (preferences.dayBeforeEnabled && alreadyScheduled + count < _maxScheduledNotifications) {
      final previousDay = due.subtract(const Duration(days: 1));
      final previousTime = _atTime(previousDay, preferences.dayBeforeTime);
      if (previousTime.isAfter(now)) {
        await _notificationService.scheduleReminder(
          id: _paymentNotificationId(payment.id, 1),
          title: 'Yarın ödeme var',
          body: '${payment.name} • $amount',
          dateTime: previousTime,
          payload: 'payment:${payment.id}:tomorrow',
        );
        count++;
      }
    }

    if (preferences.dueDayEnabled && alreadyScheduled + count < _maxScheduledNotifications) {
      await _notificationService.scheduleReminder(
        id: _paymentNotificationId(payment.id, 2),
        title: 'Bugün ödeme var',
        body: '${payment.name} • $amount',
        dateTime: _atTime(due, preferences.dueDayTime),
        payload: 'payment:${payment.id}:today',
      );
      count++;
    }

    if (preferences.overdueEnabled && alreadyScheduled + count < _maxScheduledNotifications) {
      final overdueDay = due.add(const Duration(days: 1));
      await _notificationService.scheduleReminder(
        id: _paymentNotificationId(payment.id, 3),
        title: 'Ödeme gecikti',
        body: '${payment.name} hâlâ bekliyor • $amount',
        dateTime: _atTime(overdueDay, preferences.overdueTime),
        payload: 'payment:${payment.id}:overdue',
      );
      count++;
    }

    return count;
  }

  Future<int> _scheduleIncome(
    IncomeOccurrenceItem income,
    DateTime now,
    DateTime today,
    int alreadyScheduled,
    NotificationPreferences preferences,
  ) async {
    if (!preferences.incomeDayEnabled || alreadyScheduled >= _maxScheduledNotifications) return 0;

    final expected = DateTime(income.expectedDate.year, income.expectedDate.month, income.expectedDate.day);
    if (expected.isBefore(today)) return 0;

    final expectedTime = _atTime(expected, preferences.incomeDayTime);
    await _notificationService.scheduleReminder(
      id: _incomeNotificationId(income.id),
      title: 'Bugün gelir bekleniyor',
      body: '${income.name} • ${_money(income.amount)}',
      dateTime: _sameDay(expected, today) && !expectedTime.isAfter(now)
          ? now.add(const Duration(seconds: 6))
          : expectedTime,
      payload: 'income:${income.id}:today',
    );
    return 1;
  }

  static DateTime _atTime(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  static int _paymentNotificationId(int paymentId, int suffix) =>
      100000 + ((paymentId % 100000) * 10) + suffix;

  static int _incomeNotificationId(int incomeId) => 2000000 + (incomeId % 1000000);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _money(double value) => NumberFormat.currency(
        locale: 'tr_TR',
        symbol: '₺',
        decimalDigits: 2,
      ).format(value);
}
