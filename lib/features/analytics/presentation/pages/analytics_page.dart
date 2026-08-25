import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/semantic_colors.dart';
import '../../data/analytics_repository.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _repository = AnalyticsRepository();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late Future<MonthlyAnalytics> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = _repository.fetchMonthly(_month);

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        actions: [
          IconButton(
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: FutureBuilder<MonthlyAnalytics>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bar_chart_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(_reload),
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy', 'tr_TR').format(_month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Gelir',
                        value: _money(data.totalIncome),
                        accent: SemanticColors.income,
                        accentSoft: SemanticColors.incomeSoft,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Gider',
                        value: _money(data.totalExpense),
                        accent: SemanticColors.expense,
                        accentSoft: SemanticColors.expenseSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MetricCard(
                  title: 'Net nakit',
                  value: _signedMoney(data.netCashFlow),
                  subtitle: '${data.transactionCount} gerçekleşmiş hareket',
                  accent: data.netCashFlow >= 0 ? SemanticColors.income : SemanticColors.expense,
                  accentSoft: data.netCashFlow >= 0 ? SemanticColors.incomeSoft : SemanticColors.expenseSoft,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Geçen aya göre',
                        value: _changeLabel(data.expenseChangePercent),
                        subtitle: 'Geçen ay ${_money(data.previousMonthExpense)}',
                        accent: data.expenseChangePercent == null
                            ? null
                            : data.expenseChangePercent! <= 0
                                ? SemanticColors.income
                                : SemanticColors.expense,
                        accentSoft: data.expenseChangePercent == null
                            ? null
                            : data.expenseChangePercent! <= 0
                                ? SemanticColors.incomeSoft
                                : SemanticColors.expenseSoft,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Gelire oranı',
                        value: data.incomeExpenseRatio == null
                            ? '—'
                            : '%${data.incomeExpenseRatio!.toStringAsFixed(1)}',
                        subtitle: 'Gider / gelir',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.emoji_events_outlined)),
                    title: const Text('En çok harcanan kategori'),
                    trailing: Text(
                      data.topExpenseCategory ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Kategori dağılımı',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (data.expenseCategories.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('Bu ay için gerçekleşmiş gider bulunmuyor.'),
                    ),
                  )
                else
                  ...data.expenseCategories.map(
                    (item) => _CategoryBar(item: item),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _money(double value) => NumberFormat.currency(
        locale: 'tr_TR',
        symbol: '₺',
        decimalDigits: 2,
      ).format(value);

  static String _signedMoney(double value) {
    final formatted = _money(value.abs());
    return '${value >= 0 ? '+' : '−'}$formatted';
  }

  static String _changeLabel(double? value) {
    if (value == null) return '—';
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color? accent;
  final Color? accentSoft;

  const _MetricCard({
    required this.title,
    required this.value,
    this.subtitle,
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
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final CategoryAnalyticsItem item;

  const _CategoryBar({required this.item});

  @override
  Widget build(BuildContext context) {
    final progress = (item.percentage / 100).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _AnalyticsPageState._money(item.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: SemanticColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              color: SemanticColors.expense,
              backgroundColor: SemanticColors.expenseSoft,
            ),
            const SizedBox(height: 6),
            Text('%${item.percentage.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }
}
