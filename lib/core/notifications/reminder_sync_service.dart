import 'package:intl/intl.dart';

import '../../features/incomes/data/income_repository.dart';
import '../../features/payments/data/models/payment_item.dart';
import '../../features/payments/data/payment_repository.dart';
import 'notification_service.dart';

class ReminderSyncService {
  ReminderSyncService({
    PaymentRepository? paymentRepository,
    IncomeRepository? incomeRepository,
    NotificationService? notificationService,
  })  : _paymentRepository = paymentRepository ?? PaymentRepository(),
        _incomeRepository = incomeRepository ?? IncomeRepository(),
        _notificationService = notificationService ?? NotificationService.instance;

  static const int _maxScheduledNotifications = 60;
  static const int _lookAheadDays = 35;

  final PaymentRepository _paymentRepository;
  final IncomeRepository _incomeRepository;
  final NotificationService _notificationService;

  Future<int> sync() async {
    await _notificationService.initialize();
    await _notificationService.clearPayTrackReminders();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: _lookAheadDays));

    final payments = await _paymentRepository.getPayments(from: today, to: end);
    final incomes = await _loadIncomes(today, end);

    var scheduled = 0;

    for (final payment in payments.where((item) => !item.paid)) {
      if (scheduled >= _maxScheduledNotifications) break;
      scheduled += await _schedulePayment(payment, now, today, scheduled);
    }

    for (final income in incomes.where((item) => !item.received)) {
      if (scheduled >= _maxScheduledNotifications) break;
      scheduled += await _scheduleIncome(income, now, today, scheduled);
    }

    return scheduled;
  }

  Future<List<IncomeOccurrenceItem>> _loadIncomes(
    DateTime from,
    DateTime to,
  ) async {
    final result = <IncomeOccurrenceItem>[];
    var month = DateTime(from.year, from.month, 1);
    final lastMonth = DateTime(to.year, to.month, 1);

    while (!month.isAfter(lastMonth)) {
      final items = await _incomeRepository.fetchMonth(month);
      result.addAll(
        items.where(
          (item) => !item.expectedDate.isBefore(from) && !item.expectedDate.isAfter(to),
        ),
      );
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
  ) async {
    final due = DateTime(
      payment.dueDate.year,
      payment.dueDate.month,
      payment.dueDate.day,
    );
    final amount = _money(payment.amount);
    var count = 0;

    if (due.isBefore(today)) {
      if (alreadyScheduled + count < _maxScheduledNotifications) {
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
      if (alreadyScheduled + count < _maxScheduledNotifications) {
        final morning = DateTime(due.year, due.month, due.day, 9);
        await _notificationService.scheduleReminder(
          id: _paymentNotificationId(payment.id, 2),
          title: 'Bugün ödeme var',
          body: '${payment.name} • $amount',
          dateTime: morning.isAfter(now)
              ? morning
              : now.add(const Duration(seconds: 4)),
          payload: 'payment:${payment.id}:today',
        );
        count++;
      }
      return count;
    }

    final previousEvening = DateTime(due.year, due.month, due.day - 1, 18);
    if (previousEvening.isAfter(now) &&
        alreadyScheduled + count < _maxScheduledNotifications) {
      await _notificationService.scheduleReminder(
        id: _paymentNotificationId(payment.id, 1),
        title: 'Yarın ödeme var',
        body: '${payment.name} • $amount',
        dateTime: previousEvening,
        payload: 'payment:${payment.id}:tomorrow',
      );
      count++;
    }

    if (alreadyScheduled + count < _maxScheduledNotifications) {
      await _notificationService.scheduleReminder(
        id: _paymentNotificationId(payment.id, 2),
        title: 'Bugün ödeme var',
        body: '${payment.name} • $amount',
        dateTime: DateTime(due.year, due.month, due.day, 9),
        payload: 'payment:${payment.id}:today',
      );
      count++;
    }

    if (alreadyScheduled + count < _maxScheduledNotifications) {
      await _notificationService.scheduleReminder(
        id: _paymentNotificationId(payment.id, 3),
        title: 'Ödeme gecikti',
        body: '${payment.name} hâlâ bekliyor • $amount',
        dateTime: DateTime(due.year, due.month, due.day + 1, 9),
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
  ) async {
    if (alreadyScheduled >= _maxScheduledNotifications) return 0;

    final expected = DateTime(
      income.expectedDate.year,
      income.expectedDate.month,
      income.expectedDate.day,
    );
    if (expected.isBefore(today)) return 0;

    final morning = DateTime(expected.year, expected.month, expected.day, 9);
    await _notificationService.scheduleReminder(
      id: _incomeNotificationId(income.id),
      title: 'Bugün gelir bekleniyor',
      body: '${income.name} • ${_money(income.amount)}',
      dateTime: _sameDay(expected, today) && !morning.isAfter(now)
          ? now.add(const Duration(seconds: 6))
          : morning,
      payload: 'income:${income.id}:today',
    );
    return 1;
  }

  static int _paymentNotificationId(int paymentId, int suffix) =>
      100000 + ((paymentId % 100000) * 10) + suffix;

  static int _incomeNotificationId(int incomeId) =>
      2000000 + (incomeId % 1000000);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _money(double value) => NumberFormat.currency(
        locale: 'tr_TR',
        symbol: '₺',
        decimalDigits: 2,
      ).format(value);
}
