import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/semantic_colors.dart';
import '../../../categories/data/category_repository.dart';
import '../../data/account_repository.dart';

class AccountTransactionsPage extends StatefulWidget {
  const AccountTransactionsPage({super.key});

  @override
  State<AccountTransactionsPage> createState() => _AccountTransactionsPageState();
}

class _AccountTransactionsPageState extends State<AccountTransactionsPage> {
  final _repository = AccountRepository();
  final _categoryRepository = TransactionCategoryRepository();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late Future<_HistoryData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = _load();

  Future<_HistoryData> _load() async {
    final from = DateTime(_month.year, _month.month, 1);
    final to = DateTime(_month.year, _month.month + 1, 0);
    final results = await Future.wait([
      _repository.fetchAll(),
      _repository.fetchTransactions(from: from, to: to),
      _categoryRepository.fetchAll(),
    ]);
    return _HistoryData(
      accounts: results[0] as List<AccountItem>,
      transactions: results[1] as List<AccountTransactionItem>,
      categories: results[2] as List<TransactionCategoryItem>,
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hesap hareketleri')),
      body: FutureBuilder<_HistoryData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final data = snapshot.data!;
          final names = {for (final a in data.accounts) a.id: a.name};
          final categoryNames = {for (final c in data.categories) c.id: c.name};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy', 'tr_TR').format(_month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
              ]),
              const SizedBox(height: 12),
              if (data.transactions.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Bu ay için hesap hareketi yok.')))
              else
                ...data.transactions.reversed.map((tx) {
                  final account = names[tx.accountId] ?? 'Hesap #${tx.accountId}';
                  final counter = tx.counterAccountId == null ? null : names[tx.counterAccountId!] ?? 'Hesap #${tx.counterAccountId}';
                  final category = tx.categoryId == null ? null : categoryNames[tx.categoryId!];
                  final signed = switch (tx.type) {
                    'INCOME' => '+${_money(tx.amount)}',
                    'EXPENSE' => '−${_money(tx.amount)}',
                    'TRANSFER' => _money(tx.amount),
                    _ => _money(tx.amount),
                  };
                  final accountText = tx.type == 'TRANSFER' ? '$account → $counter' : account;
                  final details = [
                    DateFormat('d MMMM', 'tr_TR').format(tx.occurredOn),
                    accountText,
                    if (category != null) category,
                    if (tx.reversed) 'Terslendi',
                  ].join(' • ');
                  final accent = _accent(tx.type);
                  final accentSoft = _accentSoft(tx.type);
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: accentSoft,
                        child: Icon(_icon(tx.type), color: accent),
                      ),
                      title: Text(
                        tx.description,
                        style: TextStyle(decoration: tx.reversed ? TextDecoration.lineThrough : null),
                      ),
                      subtitle: Text(details),
                      trailing: Text(
                        signed,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: tx.reversed ? Theme.of(context).colorScheme.onSurfaceVariant : accent,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  static String _money(double value) => NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(value);

  static IconData _icon(String type) => switch (type) {
        'INCOME' => Icons.south_west,
        'EXPENSE' => Icons.north_east,
        'TRANSFER' => Icons.swap_horiz,
        _ => Icons.tune,
      };

  static Color _accent(String type) => switch (type) {
        'INCOME' => SemanticColors.income,
        'EXPENSE' => SemanticColors.expense,
        'TRANSFER' => SemanticColors.transfer,
        _ => SemanticColors.transfer,
      };

  static Color _accentSoft(String type) => switch (type) {
        'INCOME' => SemanticColors.incomeSoft,
        'EXPENSE' => SemanticColors.expenseSoft,
        'TRANSFER' => SemanticColors.transferSoft,
        _ => SemanticColors.transferSoft,
      };
}

class _HistoryData {
  final List<AccountItem> accounts;
  final List<AccountTransactionItem> transactions;
  final List<TransactionCategoryItem> categories;

  const _HistoryData({
    required this.accounts,
    required this.transactions,
    required this.categories,
  });
}
