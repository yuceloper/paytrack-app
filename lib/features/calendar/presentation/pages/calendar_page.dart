import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../payments/data/models/payment_item.dart';
import '../../../payments/data/payment_repository.dart';
import '../../../payments/presentation/pages/payment_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _repository = PaymentRepository();
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  late Future<List<PaymentItem>> _payments;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final from = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final to = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    _payments = _repository.getPayments(from: from, to: to);
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
      _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Takvim')),
      body: FutureBuilder<List<PaymentItem>>(
        future: _payments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString(), onRetry: () => setState(_load));
          }
          final payments = snapshot.data ?? const <PaymentItem>[];
          final selected = payments.where((p) => _sameDay(p.dueDate, _selectedDate)).toList();
          final paymentDays = payments.map((p) => DateUtils.dateOnly(p.dueDate)).toSet();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy', 'tr_TR').format(_focusedMonth),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
                ],
              ),
              const SizedBox(height: 8),
              _MonthGrid(
                month: _focusedMonth,
                selectedDate: _selectedDate,
                paymentDays: paymentDays,
                onSelected: (date) => setState(() => _selectedDate = date),
              ),
              const SizedBox(height: 24),
              Text(
                DateFormat('d MMMM EEEE', 'tr_TR').format(_selectedDate),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (selected.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Bu tarihte ödeme yok.')))
              else
                ...selected.map((payment) => _PaymentCard(
                      payment: payment,
                      onChanged: () => setState(_load),
                    )),
            ],
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final Set<DateTime> paymentDays;
  final ValueChanged<DateTime> onSelected;

  const _MonthGrid({
    required this.month,
    required this.selectedDate,
    required this.paymentDays,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = first.weekday - 1;
    final cells = leading + days;
    final rows = (cells / 7).ceil();
    const week = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: week.map((label) => Expanded(child: Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))))).toList(),
            ),
            const SizedBox(height: 8),
            for (var row = 0; row < rows; row++)
              Row(
                children: List.generate(7, (column) {
                  final index = row * 7 + column;
                  final day = index - leading + 1;
                  if (day < 1 || day > days) return const Expanded(child: SizedBox(height: 48));
                  final date = DateTime(month.year, month.month, day);
                  final selected = DateUtils.isSameDay(date, selectedDate);
                  final hasPayment = paymentDays.contains(DateUtils.dateOnly(date));
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => onSelected(date),
                      child: SizedBox(
                        height: 48,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: selected
                                  ? BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle)
                                  : null,
                              child: Text('$day', style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
                            ),
                            SizedBox(
                              height: 4,
                              child: hasPayment ? const Icon(Icons.circle, size: 5) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentItem payment;
  final VoidCallback onChanged;

  const _PaymentCard({required this.payment, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(payment.amount);
    return Card(
      child: ListTile(
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => PaymentDetailPage(payment: payment)),
          );
          if (changed == true) onChanged();
        },
        leading: Icon(payment.paid ? Icons.check_circle : Icons.schedule),
        title: Text(payment.name),
        subtitle: Text(payment.paid ? 'Ödendi' : 'Bekliyor'),
        trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      ),
    );
  }
}
