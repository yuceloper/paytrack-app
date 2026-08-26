import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/credit_card_repository.dart';

class CreditCardsPage extends StatefulWidget {
  const CreditCardsPage({super.key});

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  final _repository = CreditCardRepository();
  late Future<List<CreditCardItem>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = _repository.fetchAll();

  Future<void> _add() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddCreditCardSheet(),
    );
    if (created == true && mounted) setState(_reload);
  }

  Future<void> _delete(CreditCardItem card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kartı sil?'),
        content: Text('${card.name} kartı silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.delete(card.id);
      if (mounted) setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kredi kartları'),
        actions: [IconButton(onPressed: _add, icon: const Icon(Icons.add), tooltip: 'Kart ekle')],
      ),
      body: FutureBuilder<List<CreditCardItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final cards = snapshot.data ?? const [];
          final active = cards.where((e) => e.active).toList();
          final totalDebt = active.fold<double>(0, (sum, e) => sum + e.currentDebt);
          final totalLimit = active.fold<double>(0, (sum, e) => sum + e.creditLimit);
          final available = active.fold<double>(0, (sum, e) => sum + e.availableLimit);

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Toplam kart borcu', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(_money(totalDebt), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _Metric(label: 'Toplam limit', value: _money(totalLimit))),
                            const SizedBox(width: 12),
                            Expanded(child: _Metric(label: 'Kullanılabilir', value: _money(available))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (cards.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Henüz kredi kartı eklenmedi.')))
                else
                  ...cards.map((card) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(child: Icon(Icons.credit_card)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(card.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        Text('${card.bankName}${card.lastFourDigits == null ? '' : ' •••• ${card.lastFourDigits}'}'),
                                      ],
                                    ),
                                  ),
                                  IconButton(onPressed: () => _delete(card), icon: const Icon(Icons.delete_outline)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              LinearProgressIndicator(value: card.creditLimit <= 0 ? 0 : (card.currentDebt / card.creditLimit).clamp(0, 1)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _Metric(label: 'Borç', value: _money(card.currentDebt), negative: true)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _Metric(label: 'Kullanılabilir', value: _money(card.availableLimit))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('Hesap kesim: Ayın ${card.statementDay}. günü • Son ödeme: Ayın ${card.dueDay}. günü'),
                              if (card.minimumPayment > 0) Text('Asgari ödeme: ${_money(card.minimumPayment)}'),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _money(double value) => NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(value);
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool negative;

  const _Metric({required this.label, required this.value, this.negative = false});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          FittedBox(child: Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: negative ? Theme.of(context).colorScheme.error : null))),
        ],
      );
}

class _AddCreditCardSheet extends StatefulWidget {
  const _AddCreditCardSheet();

  @override
  State<_AddCreditCardSheet> createState() => _AddCreditCardSheetState();
}

class _AddCreditCardSheetState extends State<_AddCreditCardSheet> {
  final _repository = CreditCardRepository();
  final _name = TextEditingController();
  final _bank = TextEditingController();
  final _lastFour = TextEditingController();
  final _limit = TextEditingController();
  final _debt = TextEditingController(text: '0');
  final _minimum = TextEditingController(text: '0');
  final _statementDay = TextEditingController(text: '15');
  final _dueDay = TextEditingController(text: '25');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _bank, _lastFour, _limit, _debt, _minimum, _statementDay, _dueDay]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final limit = double.tryParse(_limit.text.replaceAll(',', '.'));
    final debt = double.tryParse(_debt.text.replaceAll(',', '.'));
    final minimum = double.tryParse(_minimum.text.replaceAll(',', '.'));
    final statementDay = int.tryParse(_statementDay.text);
    final dueDay = int.tryParse(_dueDay.text);
    final lastFour = _lastFour.text.trim();
    if (_name.text.trim().isEmpty || _bank.text.trim().isEmpty || limit == null || limit < 0 || debt == null || debt < 0 || debt > limit || minimum == null || minimum < 0 || statementDay == null || statementDay < 1 || statementDay > 31 || dueDay == null || dueDay < 1 || dueDay > 31 || (lastFour.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(lastFour))) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.create(
        name: _name.text.trim(),
        bankName: _bank.text.trim(),
        lastFourDigits: lastFour.isEmpty ? null : lastFour,
        statementDay: statementDay,
        dueDay: dueDay,
        creditLimit: limit,
        currentDebt: debt,
        minimumPayment: minimum,
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Kredi kartı ekle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Kart adı', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _bank, decoration: const InputDecoration(labelText: 'Banka', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _lastFour, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'Son 4 hane (opsiyonel)', border: OutlineInputBorder())),
              const SizedBox(height: 4),
              TextField(controller: _limit, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Kart limiti', prefixText: '₺ ', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _debt, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Mevcut borç', prefixText: '₺ ', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _minimum, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Asgari ödeme', prefixText: '₺ ', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _statementDay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hesap kesim günü', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _dueDay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Son ödeme günü', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Kaydediliyor...' : 'Kartı kaydet'),
                ),
              ),
            ],
          ),
        ),
      );
}
