import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/semantic_colors.dart';
import '../../../accounts/data/account_repository.dart';
import '../../../accounts/presentation/pages/accounts_page.dart';
import '../../../incomes/data/income_repository.dart';
import '../../../payments/data/models/payment_item.dart';
import '../../../payments/data/payment_repository.dart';

class CashFlowPage extends StatefulWidget {
  const CashFlowPage({super.key});

  @override
  State<CashFlowPage> createState() => _CashFlowPageState();
}

class _CashFlowPageState extends State<CashFlowPage> {
  final _paymentRepository = PaymentRepository();
  final _incomeRepository = IncomeRepository();
  final _accountRepository = AccountRepository();

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late Future<_CashFlowData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _loadMonth(_month);
  }

  Future<_CashFlowData> _loadMonth(DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);

    final payments = await _paymentRepository.getPayments(from: from, to: to);
    final incomes = await _incomeRepository.fetchMonth(month);
    final accounts = await _accountRepository.fetchAll();

    final openingBalance = accounts
        .where((item) => item.active && item.currency == 'TRY')
        .fold<double>(0, (sum, item) => sum + item.balance);

    final entries = <_CashFlowEntry>[
      ...payments.map(_CashFlowEntry.fromPayment),
      ...incomes.map(_CashFlowEntry.fromIncome),
    ]..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        if (a.isIncome == b.isIncome) return a.title.compareTo(b.title);
        return a.isIncome ? -1 : 1;
      });

    var projectedBalance = openingBalance;
    final projectedEntries = entries.map((entry) {
      projectedBalance += entry.signedAmount;
      return entry.copyWith(projectedBalance: projectedBalance);
    }).toList();

    final plannedIncome = incomes.fold<double>(0, (sum, item) => sum + item.amount);
    final totalPayments = payments.fold<double>(0, (sum, item) => sum + item.amount);
    final remainingPayments = payments
        .where((item) => !item.paid)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final receivedIncome = incomes
        .where((item) => item.received)
        .fold<double>(0, (sum, item) => sum + item.amount);

    return _CashFlowData(
      entries: projectedEntries,
      openingBalance: openingBalance,
      projectedClosingBalance: projectedBalance,
      plannedIncome: plannedIncome,
      receivedIncome: receivedIncome,
      totalPayments: totalPayments,
      remainingPayments: remainingPayments,
      plannedNet: plannedIncome - totalPayments,
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      _reload();
    });
  }

  Future<void> _openAccounts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountsPage()),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nakit Akışı'),
        actions: [
          IconButton(
            tooltip: 'Hesaplar',
            onPressed: _openAccounts,
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_CashFlowData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(_reload),
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _MonthHeader(
                  month: _month,
                  onPrevious: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mevcut toplam bakiye'),
                        const SizedBox(height: 8),
                        Text(_money(data.openingBalance), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          'Ay sonu tahmini: ${_money(data.projectedClosingBalance)}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Planlanan gelir',
                        value: _money(data.plannedIncome),
                        subtitle: '${_money(data.receivedIncome)} geldi',
                        accent: SemanticColors.income,
                        accentSoft: SemanticColors.incomeSoft,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Kalan ödeme',
                        value: _money(data.remainingPayments),
                        subtitle: '${_money(data.totalPayments)} toplam',
                        accent: SemanticColors.expense,
                        accentSoft: SemanticColors.expenseSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: data.plannedNet >= 0 ? SemanticColors.incomeSoft : SemanticColors.expenseSoft,
                      child: Icon(
                        Icons.swap_vert,
                        color: data.plannedNet >= 0 ? SemanticColors.income : SemanticColors.expense,
                      ),
                    ),
                    title: const Text('Planlanan net değişim'),
                    subtitle: const Text('Gelir − toplam ödeme'),
                    trailing: Text(
                      _signedMoney(data.plannedNet),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: data.plannedNet >= 0 ? SemanticColors.income : SemanticColors.expense,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text('Akış', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (data.entries.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('Bu ay için gelir veya ödeme yok.'),
                    ),
                  )
                else
                  ..._groupEntries(data.entries),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _groupEntries(List<_CashFlowEntry> entries) {
    final widgets = <Widget>[];
    DateTime? previousDate;

    for (final entry in entries) {
      if (previousDate == null || !DateUtils.isSameDay(previousDate, entry.date)) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Text(
              DateFormat('d MMMM EEEE', 'tr_TR').format(entry.date),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        );
        previousDate = entry.date;
      }
      widgets.add(_CashFlowTile(entry: entry));
    }

    return widgets;
  }

  static String _money(double value) => NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(value);

  static String _signedMoney(double value) {
    final formatted = _money(value.abs());
    return '${value >= 0 ? '+' : '−'}$formatted';
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthHeader({required this.month, required this.onPrevious, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy', 'tr_TR').format(month),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color? accent;
  final Color? accentSoft;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.accent,
    this.accentSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: accentSoft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: accent),
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _CashFlowTile extends StatelessWidget {
  final _CashFlowEntry entry;

  const _CashFlowTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final amount = _CashFlowPageState._money(entry.amount);
    final projected = _CashFlowPageState._money(entry.projectedBalance);
    final accent = entry.isIncome ? SemanticColors.income : SemanticColors.expense;
    final accentSoft = entry.isIncome ? SemanticColors.incomeSoft : SemanticColors.expenseSoft;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentSoft,
          child: Icon(entry.isIncome ? Icons.south_west : Icons.north_east, color: accent),
        ),
        title: Text(entry.title),
        subtitle: Text('${entry.statusLabel} • Tahmini bakiye $projected'),
        trailing: Text(
          '${entry.isIncome ? '+' : '−'}$amount',
          style: TextStyle(fontWeight: FontWeight.w800, color: accent),
        ),
      ),
    );
  }
}

class _CashFlowData {
  final List<_CashFlowEntry> entries;
  final double openingBalance;
  final double projectedClosingBalance;
  final double plannedIncome;
  final double receivedIncome;
  final double totalPayments;
  final double remainingPayments;
  final double plannedNet;

  const _CashFlowData({
    required this.entries,
    required this.openingBalance,
    required this.projectedClosingBalance,
    required this.plannedIncome,
    required this.receivedIncome,
    required this.totalPayments,
    required this.remainingPayments,
    required this.plannedNet,
  });
}

class _CashFlowEntry {
  final DateTime date;
  final String title;
  final double amount;
  final bool isIncome;
  final bool completed;
  final double projectedBalance;

  const _CashFlowEntry({
    required this.date,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.completed,
    this.projectedBalance = 0,
  });

  factory _CashFlowEntry.fromPayment(PaymentItem payment) => _CashFlowEntry(
        date: payment.dueDate,
        title: payment.name,
        amount: payment.amount,
        isIncome: false,
        completed: payment.paid,
      );

  factory _CashFlowEntry.fromIncome(IncomeOccurrenceItem income) => _CashFlowEntry(
        date: income.expectedDate,
        title: income.name,
        amount: income.amount,
        isIncome: true,
        completed: income.received,
      );

  double get signedAmount => isIncome ? amount : -amount;

  String get statusLabel => isIncome
      ? (completed ? 'Geldi' : 'Bekleniyor')
      : (completed ? 'Ödendi' : 'Bekliyor');

  _CashFlowEntry copyWith({double? projectedBalance}) => _CashFlowEntry(
        date: date,
        title: title,
        amount: amount,
        isIncome: isIncome,
        completed: completed,
        projectedBalance: projectedBalance ?? this.projectedBalance,
      );
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
