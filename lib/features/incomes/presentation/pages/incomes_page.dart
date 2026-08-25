import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/semantic_colors.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../data/income_repository.dart';

class IncomesPage extends StatefulWidget {
  const IncomesPage({super.key});

  @override
  State<IncomesPage> createState() => _IncomesPageState();
}

class _IncomesPageState extends State<IncomesPage> {
  final _repository = IncomeRepository();
  DateTime _month = DateTime.now();
  late Future<List<IncomeOccurrenceItem>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = _repository.fetchMonth(_month);

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      _reload();
    });
  }

  Future<void> _addIncome() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddIncomeSheet(),
    );
    if (created == true) setState(_reload);
  }

  Future<void> _receive(IncomeOccurrenceItem item) async {
    final account = await showAccountPicker(context, title: 'Gelir hangi hesaba geldi?');
    if (account == null || !mounted) return;
    await _repository.markReceived(item.id, accountId: account.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${account.name} hesabına gelir işlendi')),
      );
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelirler'),
        actions: [IconButton(onPressed: _addIncome, icon: const Icon(Icons.add))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
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
          ),
          Expanded(
            child: FutureBuilder<List<IncomeOccurrenceItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
                final items = snapshot.data ?? const [];
                if (items.isEmpty) return const Center(child: Text('Bu ay için gelir kaydı yok.'));

                final planned = items.fold<double>(0, (sum, item) => sum + item.amount);
                final received = items.where((e) => e.received).fold<double>(0, (sum, item) => sum + item.amount);
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(children: [
                      Expanded(child: _MetricCard(title: 'Planlanan', value: _money(planned))),
                      const SizedBox(width: 12),
                      Expanded(child: _MetricCard(title: 'Gelen', value: _money(received), emphasized: true)),
                    ]),
                    const SizedBox(height: 18),
                    ...items.map((item) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: SemanticColors.incomeSoftFor(context),
                              child: Icon(
                                item.received ? Icons.check : Icons.south_west,
                                color: SemanticColors.incomeFor(context),
                              ),
                            ),
                            title: Text(item.name, style: TextStyle(decoration: item.received ? TextDecoration.lineThrough : null)),
                            subtitle: Text('${DateFormat('d MMMM', 'tr_TR').format(item.expectedDate)} • ${item.received ? 'Geldi' : 'Bekleniyor'}'),
                            trailing: Text(
                              _money(item.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: SemanticColors.incomeFor(context),
                              ),
                            ),
                            onTap: item.received ? null : () => _receive(item),
                          ),
                        )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _money(double value) => NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(value);
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final bool emphasized;

  const _MetricCard({required this.title, required this.value, this.emphasized = false});

  @override
  Widget build(BuildContext context) => Card(
        color: emphasized ? SemanticColors.incomeSoftFor(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: emphasized ? SemanticColors.incomeFor(context) : null,
                ),
              ),
            ),
          ]),
        ),
      );
}

class _AddIncomeSheet extends StatefulWidget {
  const _AddIncomeSheet();

  @override
  State<_AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<_AddIncomeSheet> {
  final _repository = IncomeRepository();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _interval = TextEditingController(text: '1');

  String _type = 'SALARY';
  String _frequency = 'MONTHLY';
  DateTime _date = DateTime.now();
  DateTime? _endDate;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _interval.dispose();
    super.dispose();
  }

  bool get _isRecurring => _frequency != 'ONE_TIME';

  bool get _usesMonthlyAnchor =>
      _frequency == 'MONTHLY' || _frequency == 'CUSTOM_MONTHS';

  bool get _customInterval =>
      _frequency == 'CUSTOM_DAYS' || _frequency == 'CUSTOM_MONTHS';

  String get _intervalLabel => switch (_frequency) {
        'CUSTOM_DAYS' => 'Kaç günde bir',
        'CUSTOM_MONTHS' => 'Kaç ayda bir',
        'WEEKLY' => 'Kaç haftada bir',
        'YEARLY' => 'Kaç yılda bir',
        _ => 'Kaç ayda bir',
      };

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    final interval = _isRecurring ? int.tryParse(_interval.text) : null;
    if (_name.text.trim().isEmpty || amount == null || amount <= 0) return;
    if (_isRecurring && (interval == null || interval < 1)) return;

    setState(() => _saving = true);
    try {
      await _repository.createSource(
        name: _name.text.trim(),
        type: _type,
        amount: amount,
        frequency: _frequency,
        nextIncomeDate: _date,
        recurrenceInterval: interval,
        recurrenceEndDate: _isRecurring ? _endDate : null,
      );
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
          const Text('Gelir ekle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Gelir adı', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Tutar', prefixText: '₺ ', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Tür', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'SALARY', child: Text('Maaş')),
              DropdownMenuItem(value: 'RENT', child: Text('Kira')),
              DropdownMenuItem(value: 'FREELANCE', child: Text('Freelance')),
              DropdownMenuItem(value: 'BUSINESS', child: Text('İş geliri')),
              DropdownMenuItem(value: 'INVESTMENT', child: Text('Yatırım')),
              DropdownMenuItem(value: 'OTHER', child: Text('Diğer')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'OTHER'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _frequency,
            decoration: const InputDecoration(labelText: 'Tekrar', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'MONTHLY', child: Text('Aylık')),
              DropdownMenuItem(value: 'WEEKLY', child: Text('Haftalık')),
              DropdownMenuItem(value: 'YEARLY', child: Text('Yıllık')),
              DropdownMenuItem(value: 'CUSTOM_DAYS', child: Text('Özel • gün aralığı')),
              DropdownMenuItem(value: 'CUSTOM_MONTHS', child: Text('Özel • ay aralığı')),
              DropdownMenuItem(value: 'ONE_TIME', child: Text('Tek seferlik')),
            ],
            onChanged: (v) => setState(() {
              _frequency = v ?? 'ONE_TIME';
              if (!_customInterval) _interval.text = '1';
              if (!_isRecurring) _endDate = null;
            }),
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _interval,
              enabled: _customInterval,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: _intervalLabel, border: const OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(4)),
            title: const Text('İlk / sonraki gelir tarihi'),
            subtitle: Text(DateFormat('d MMMM yyyy', 'tr_TR').format(_date)),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (picked != null) {
                setState(() {
                  _date = picked;
                  if (_endDate != null && _endDate!.isBefore(_date)) _endDate = null;
                });
              }
            },
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(4)),
              title: const Text('Bitiş tarihi'),
              subtitle: Text(_endDate == null ? 'Süresiz' : DateFormat('d MMMM yyyy', 'tr_TR').format(_endDate!)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endDate != null)
                    IconButton(
                      tooltip: 'Bitiş tarihini kaldır',
                      onPressed: () => setState(() => _endDate = null),
                      icon: const Icon(Icons.close),
                    ),
                  const Icon(Icons.event_repeat),
                ],
              ),
              onTap: () async {
                final initial = _endDate ?? _date.add(const Duration(days: 30));
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial.isBefore(_date) ? _date : initial,
                  firstDate: _date,
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
            ),
            if (_usesMonthlyAnchor) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ayın ${_date.day}. günü hedeflenir; kısa aylarda otomatik olarak ayın son gününe çekilir.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Kaydediliyor...' : 'Geliri kaydet'),
            ),
          ),
        ]),
      ),
    );
  }
}
