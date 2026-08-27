import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../accounts/data/account_repository.dart';
import '../../data/credit_card_repository.dart';

class CreditCardsPage extends StatefulWidget {
  const CreditCardsPage({super.key});

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  final _repository = CreditCardRepository();
  final _accountRepository = AccountRepository();
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

  Future<void> _pay(CreditCardItem card) async {
    if (card.currentDebt <= 0) return;
    try {
      final accounts = (await _accountRepository.fetchAll())
          .where((e) => e.active && (e.currency == 'TRY' || e.currency == 'TL'))
          .toList();
      if (!mounted) return;
      if (accounts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödeme için aktif bir TRY hesabı ekleyin.')),
        );
        return;
      }

      final draft = await showModalBottomSheet<_CardPaymentDraft>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _CardPaymentSheet(card: card, accounts: accounts),
      );
      if (draft == null) return;

      await _repository.pay(
        cardId: card.id,
        accountId: draft.accountId,
        amount: draft.amount,
      );
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.name} için ${_money(draft.amount)} ödeme kaydedildi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _delete(CreditCardItem card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kartı sil?'),
        content: Text(
          card.currentDebt > 0
              ? '${card.name} kartında ${_money(card.currentDebt)} borç var. Borç sıfırlanmadan kart silinemez.'
              : '${card.name} kartı silinecek.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          if (card.currentDebt <= 0)
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _repository.delete(card.id);
        if (mounted) setState(_reload);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
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
                        Text(
                          _money(totalDebt),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
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
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'pay') _pay(card);
                                      if (value == 'delete') _delete(card);
                                    },
                                    itemBuilder: (_) => [
                                      if (card.currentDebt > 0)
                                        const PopupMenuItem(value: 'pay', child: Text('Borç öde')),
                                      const PopupMenuItem(value: 'delete', child: Text('Sil')),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              LinearProgressIndicator(
                                value: card.creditLimit <= 0 ? 0 : (card.currentDebt / card.creditLimit).clamp(0, 1),
                              ),
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
                              if (card.currentDebt > 0) ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () => _pay(card),
                                    icon: const Icon(Icons.account_balance_wallet_outlined),
                                    label: const Text('Borç öde'),
                                  ),
                                ),
                              ],
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

class _CardPaymentDraft {
  final int accountId;
  final double amount;

  const _CardPaymentDraft({required this.accountId, required this.amount});
}

class _CardPaymentSheet extends StatefulWidget {
  final CreditCardItem card;
  final List<AccountItem> accounts;

  const _CardPaymentSheet({required this.card, required this.accounts});

  @override
  State<_CardPaymentSheet> createState() => _CardPaymentSheetState();
}

class _CardPaymentSheetState extends State<_CardPaymentSheet> {
  late int _accountId;
  late final TextEditingController _amount;
  String? _error;

  @override
  void initState() {
    super.initState();
    _accountId = widget.accounts.first.id;
    _amount = TextEditingController(text: widget.card.currentDebt.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0 || amount > widget.card.currentDebt) {
      setState(() => _error = 'Ödeme tutarı 0’dan büyük ve kart borcundan fazla olmamalı.');
      return;
    }
    Navigator.pop(context, _CardPaymentDraft(accountId: _accountId, amount: amount));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.card.name} borç öde', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Mevcut borç: ${CreditCardsPageStateMoney.money(widget.card.currentDebt)}'),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                initialValue: _accountId,
                decoration: const InputDecoration(labelText: 'Ödeme hesabı', border: OutlineInputBorder()),
                items: widget.accounts
                    .map((account) => DropdownMenuItem(
                          value: account.id,
                          child: Text('${account.name} • ${CreditCardsPageStateMoney.money(account.signedBalance)}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _accountId = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Ödeme tutarı', prefixText: '₺ ', border: OutlineInputBorder()),
              ),
              if (widget.card.minimumPayment > 0) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _amount.text = widget.card.minimumPayment.toStringAsFixed(2),
                  child: Text('Asgariyi yaz (${CreditCardsPageStateMoney.money(widget.card.minimumPayment)})'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              const Text(
                'Bu işlem seçilen hesaptan para düşürür ve kart borcunu azaltır. Harcama analitiğine ikinci kez gider olarak eklenmez.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _save, child: const Text('Ödemeyi kaydet')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreditCardsPageStateMoney {
  static String money(double value) => NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(value);
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
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: negative ? Theme.of(context).colorScheme.error : null,
              ),
            ),
          ),
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
