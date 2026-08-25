import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../categories/data/category_repository.dart';
import '../../data/account_repository.dart';

class ManualTransactionSheet extends StatefulWidget {
  final List<AccountItem> accounts;

  const ManualTransactionSheet({super.key, required this.accounts});

  @override
  State<ManualTransactionSheet> createState() => _ManualTransactionSheetState();
}

class _ManualTransactionSheetState extends State<ManualTransactionSheet> {
  final _accountRepository = AccountRepository();
  final _categoryRepository = TransactionCategoryRepository();
  final _amount = TextEditingController();
  final _description = TextEditingController();

  String _type = 'EXPENSE';
  late int _accountId;
  int? _categoryId;
  DateTime _date = DateTime.now();
  bool _saving = false;
  late Future<List<TransactionCategoryItem>> _categories;

  @override
  void initState() {
    super.initState();
    _accountId = widget.accounts.first.id;
    _categories = _categoryRepository.fetchAll();
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0 || _description.text.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      await _accountRepository.createManualTransaction(
        accountId: _accountId,
        type: _type,
        amount: amount,
        description: _description.text.trim(),
        occurredOn: _date,
        categoryId: _categoryId,
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hareket ekle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'EXPENSE', label: Text('Gider'), icon: Icon(Icons.north_east)),
                ButtonSegment(value: 'INCOME', label: Text('Gelir'), icon: Icon(Icons.south_west)),
              ],
              selected: {_type},
              onSelectionChanged: (values) {
                setState(() {
                  _type = values.first;
                  _categoryId = null;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Hesap', border: OutlineInputBorder()),
              items: widget.accounts
                  .map((account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _accountId = value ?? _accountId),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Tutar', prefixText: '₺ ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<TransactionCategoryItem>>(
              future: _categories,
              builder: (context, snapshot) {
                final items = (snapshot.data ?? const <TransactionCategoryItem>[])
                    .where((category) => category.supports(_type))
                    .toList();
                return DropdownButtonFormField<int?>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Kategorisiz')),
                    ...items.map((category) => DropdownMenuItem<int?>(
                          value: category.id,
                          child: Text(category.name),
                        )),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Örn. Migros alışverişi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              title: const Text('Tarih'),
              subtitle: Text(DateFormat('d MMMM yyyy', 'tr_TR').format(_date)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: Icon(_type == 'EXPENSE' ? Icons.remove_circle_outline : Icons.add_circle_outline),
                label: Text(_saving ? 'Kaydediliyor...' : 'Hareketi kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
