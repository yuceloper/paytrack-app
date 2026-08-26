import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/account_repository.dart';
import '../widgets/manual_transaction_sheet.dart';
import 'account_transactions_page.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final _repository = AccountRepository();
  late Future<List<AccountItem>> _future;

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
      builder: (_) => const _AddAccountSheet(),
    );
    if (created == true) setState(_reload);
  }

  Future<void> _manualTransaction(List<AccountItem> accounts) async {
    final active = accounts.where((e) => e.active && e.currency == 'TRY').toList();
    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce aktif bir TRY hesabı eklemelisin.')),
      );
      return;
    }
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ManualTransactionSheet(accounts: active),
    );
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _transfer(List<AccountItem> accounts) async {
    final active = accounts.where((e) => e.active && e.currency == 'TRY').toList();
    if (active.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer için en az iki aktif TRY hesabı gerekli.')),
      );
      return;
    }
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TransferSheet(accounts: active),
    );
    if (changed == true && mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesaplar'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountTransactionsPage()),
            ),
            icon: const Icon(Icons.history),
            tooltip: 'Hesap hareketleri',
          ),
          IconButton(onPressed: _add, icon: const Icon(Icons.add), tooltip: 'Hesap ekle'),
        ],
      ),
      body: FutureBuilder<List<AccountItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final items = snapshot.data ?? const [];
          final total = items.where((e) => e.active && e.currency == 'TRY').fold<double>(0, (s, e) => s + e.balance);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.account_balance_wallet_outlined)),
                  title: const Text('Toplam kullanılabilir bakiye'),
                  trailing: Text(_money(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _manualTransaction(items),
                      icon: const Icon(Icons.add_card),
                      label: const Text('Hareket ekle'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _transfer(items),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Transfer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (items.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Henüz hesap eklenmedi.')))
              else
                ...items.map((account) => Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(_icon(account.type))),
                        title: Text(account.name),
                        subtitle: Text(account.institution ?? _label(account.type)),
                        trailing: Text(_money(account.balance), style: const TextStyle(fontWeight: FontWeight.w700)),
                        onTap: () => _editBalance(account),
                        onLongPress: () => _delete(account),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editBalance(AccountItem account) async {
    final balanceController = TextEditingController(text: account.balance.toStringAsFixed(2));
    final descriptionController = TextEditingController(text: 'Bakiye düzeltmesi');
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${account.name} bakiyesini düzelt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mevcut bakiye: ${_money(account.balance)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Doğru bakiye', prefixText: '₺ '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Açıklama'),
            ),
            const SizedBox(height: 10),
            Text(
              'Aradaki fark hesap hareketi olarak kaydedilecek; geçmiş hareketler bozulmayacak.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(balanceController.text.replaceAll(',', '.'));
              final description = descriptionController.text.trim();
              if (value == null || description.isEmpty || value == account.balance) return;
              await _repository.adjustBalance(
                accountId: account.id,
                targetBalance: value,
                description: description,
              );
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Düzelt'),
          ),
        ],
      ),
    );
    balanceController.dispose();
    descriptionController.dispose();
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bakiye düzeltmesi hesap hareketlerine kaydedildi.')),
      );
      setState(_reload);
    }
  }

  Future<void> _delete(AccountItem account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı sil?'),
        content: Text('${account.name} hesabı silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.delete(account.id);
      if (mounted) setState(_reload);
    }
  }

  static String _money(double value) => NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(value);

  static IconData _icon(String type) => switch (type) {
        'BANK_ACCOUNT' => Icons.account_balance_outlined,
        'CASH' => Icons.payments_outlined,
        'E_WALLET' => Icons.wallet_outlined,
        'SAVINGS' => Icons.savings_outlined,
        _ => Icons.account_balance_wallet_outlined,
      };

  static String _label(String type) => switch (type) {
        'BANK_ACCOUNT' => 'Banka hesabı',
        'CASH' => 'Nakit',
        'E_WALLET' => 'E-cüzdan',
        'SAVINGS' => 'Birikim',
        _ => type,
      };
}

class _TransferSheet extends StatefulWidget {
  final List<AccountItem> accounts;
  const _TransferSheet({required this.accounts});

  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  final _repository = AccountRepository();
  final _amount = TextEditingController();
  final _description = TextEditingController(text: 'Hesaplar arası transfer');
  late int _fromId;
  late int _toId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fromId = widget.accounts[0].id;
    _toId = widget.accounts[1].id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0 || _fromId == _toId) return;
    setState(() => _saving = true);
    try {
      await _repository.transfer(
        fromAccountId: _fromId,
        toAccountId: _toId,
        amount: amount,
        description: _description.text.trim().isEmpty ? 'Hesaplar arası transfer' : _description.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.accounts
        .map((a) => DropdownMenuItem<int>(value: a.id, child: Text('${a.name} (${_AccountsPageState._money(a.balance)})')))
        .toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Transfer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            initialValue: _fromId,
            decoration: const InputDecoration(labelText: 'Gönderen hesap', border: OutlineInputBorder()),
            items: items,
            onChanged: (v) => setState(() => _fromId = v ?? _fromId),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _toId,
            decoration: const InputDecoration(labelText: 'Alıcı hesap', border: OutlineInputBorder()),
            items: items,
            onChanged: (v) => setState(() => _toId = v ?? _toId),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Tutar', prefixText: '₺ ', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(controller: _description, decoration: const InputDecoration(labelText: 'Açıklama', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.swap_horiz),
              label: Text(_saving ? 'Aktarılıyor...' : 'Transferi yap'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AddAccountSheet extends StatefulWidget {
  const _AddAccountSheet();

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _repository = AccountRepository();
  final _name = TextEditingController();
  final _institution = TextEditingController();
  final _balance = TextEditingController();
  String _type = 'BANK_ACCOUNT';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _institution.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final balance = double.tryParse(_balance.text.replaceAll(',', '.'));
    if (_name.text.trim().isEmpty || balance == null) return;
    setState(() => _saving = true);
    try {
      await _repository.create(name: _name.text.trim(), type: _type, balance: balance, institution: _institution.text);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Hesap ekle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Hesap adı', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Tür', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'BANK_ACCOUNT', child: Text('Banka hesabı')),
              DropdownMenuItem(value: 'CASH', child: Text('Nakit')),
              DropdownMenuItem(value: 'E_WALLET', child: Text('E-cüzdan')),
              DropdownMenuItem(value: 'SAVINGS', child: Text('Birikim')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'BANK_ACCOUNT'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _institution, decoration: const InputDecoration(labelText: 'Banka / kurum (opsiyonel)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _balance, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Mevcut bakiye', prefixText: '₺ ', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Kaydediliyor...' : 'Hesabı kaydet'),
            ),
          ),
        ]),
      ),
    );
  }
}
