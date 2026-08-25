import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/semantic_colors.dart';
import '../../../incomes/data/income_repository.dart';
import '../../../payments/data/models/payment_item.dart';
import '../../../payments/data/payment_repository.dart';
import '../../../payments/presentation/pages/payment_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _paymentRepository = PaymentRepository();
  final _incomeRepository = IncomeRepository();

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  late Future<_CalendarData> _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final from = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final to = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    _data = Future.wait([
      _paymentRepository.getPayments(from: from, to: to),
      _incomeRepository.fetchMonth(_focusedMonth),
    ]).then(
      (results) => _CalendarData(
        payments: results[0] as List<PaymentItem>,
        incomes: results[1] as List<IncomeOccurrenceItem>,
      ),
    );
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
      body: FutureBuilder<_CalendarData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(_load),
            );
          }

          final data = snapshot.data ?? const _CalendarData();
          final selectedPayments = data.payments
              .where((payment) => _sameDay(payment.dueDate, _selectedDate))
              .toList();
          final selectedIncomes = data.incomes
              .where((income) => _sameDay(income.expectedDate, _selectedDate))
              .toList();

          final paymentDays = data.payments
              .map((payment) => DateUtils.dateOnly(payment.dueDate))
              .toSet();
          final incomeDays = data.incomes
              .map((income) => DateUtils.dateOnly(income.expectedDate))
              .toSet();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy', 'tr_TR').format(_focusedMonth),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const _Legend(),
              const SizedBox(height: 8),
              _MonthGrid(
                month: _focusedMonth,
                selectedDate: _selectedDate,
                paymentDays: paymentDays,
                incomeDays: incomeDays,
                onSelected: (date) => setState(() => _selectedDate = date),
              ),
              const SizedBox(height: 24),
              Text(
                DateFormat('d MMMM EEEE', 'tr_TR').format(_selectedDate),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (selectedPayments.isEmpty && selectedIncomes.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Bu tarihte gelir veya ödeme yok.'),
                  ),
                )
              else ...[
                ...selectedIncomes.map(_IncomeCard.new),
                ...selectedPayments.map(
                  (payment) => _PaymentCard(
                    payment: payment,
                    onChanged: () => setState(_load),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _CalendarData {
  final List<PaymentItem> payments;
  final List<IncomeOccurrenceItem> incomes;

  const _CalendarData({
    this.payments = const [],
    this.incomes = const [],
  });
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          icon: Icons.arrow_upward,
          label: 'Gelir',
          color: SemanticColors.incomeFor(context),
        ),
        const SizedBox(width: 18),
        _LegendItem(
          icon: Icons.arrow_downward,
          label: 'Ödeme',
          color: SemanticColors.expenseFor(context),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _LegendItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final Set<DateTime> paymentDays;
  final Set<DateTime> incomeDays;
  final ValueChanged<DateTime> onSelected;

  const _MonthGrid({
    required this.month,
    required this.selectedDate,
    required this.paymentDays,
    required this.incomeDays,
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
              children: week
                  .map(
                    (label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            for (var row = 0; row < rows; row++)
              Row(
                children: List.generate(7, (column) {
                  final index = row * 7 + column;
                  final day = index - leading + 1;
                  if (day < 1 || day > days) {
                    return const Expanded(child: SizedBox(height: 54));
                  }

                  final date = DateTime(month.year, month.month, day);
                  final selected = DateUtils.isSameDay(date, selectedDate);
                  final normalized = DateUtils.dateOnly(date);
                  final hasPayment = paymentDays.contains(normalized);
                  final hasIncome = incomeDays.contains(normalized);

                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => onSelected(date),
                      child: SizedBox(
                        height: 54,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: selected
                                  ? BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    )
                                  : null,
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 14,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasIncome)
                                    Icon(
                                      Icons.arrow_upward,
                                      size: 12,
                                      color: SemanticColors.incomeFor(context),
                                    ),
                                  if (hasIncome && hasPayment) const SizedBox(width: 2),
                                  if (hasPayment)
                                    Icon(
                                      Icons.arrow_downward,
                                      size: 12,
                                      color: SemanticColors.expenseFor(context),
                                    ),
                                ],
                              ),
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

class _IncomeCard extends StatelessWidget {
  final IncomeOccurrenceItem income;

  const _IncomeCard(this.income);

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '+₺',
      decimalDigits: 2,
    ).format(income.amount);

    final accent = SemanticColors.incomeFor(context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: SemanticColors.incomeSoftFor(context),
          foregroundColor: accent,
          child: Icon(income.received ? Icons.check : Icons.south_west),
        ),
        title: Text(income.name),
        subtitle: Text(income.received ? 'Gelir · Geldi' : 'Gelir · Bekleniyor'),
        trailing: Text(
          amount,
          style: TextStyle(fontWeight: FontWeight.w700, color: accent),
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
    final amount = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '-₺',
      decimalDigits: 2,
    ).format(payment.amount);

    final accent = payment.paid
        ? SemanticColors.incomeFor(context)
        : SemanticColors.expenseFor(context);
    final soft = payment.paid
        ? SemanticColors.incomeSoftFor(context)
        : SemanticColors.expenseSoftFor(context);

    return Card(
      child: ListTile(
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => PaymentDetailPage(payment: payment)),
          );
          if (changed == true) onChanged();
        },
        leading: CircleAvatar(
          backgroundColor: soft,
          foregroundColor: accent,
          child: Icon(payment.paid ? Icons.check : Icons.schedule),
        ),
        title: Text(payment.name),
        subtitle: Text(payment.paid ? 'Ödeme · Ödendi' : 'Ödeme · Bekliyor'),
        trailing: Text(
          amount,
          style: TextStyle(fontWeight: FontWeight.w700, color: accent),
        ),
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
