import 'package:flutter/material.dart';
import '../../data/models/payment_item.dart';
import '../../data/payment_repository.dart';

class AddPaymentPage extends StatefulWidget {
  final PaymentItem? payment;

  const AddPaymentPage({super.key, this.payment});

  bool get isEditing => payment != null;

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _institutionController = TextEditingController();
  final _noteController = TextEditingController();
  final _intervalController = TextEditingController(text: '1');
  final _repository = PaymentRepository();

  String _type = 'OTHER';
  DateTime _dueDate = DateTime.now();
  bool _recurring = false;
  String _recurrenceFrequency = 'MONTHLY';
  DateTime? _recurrenceEndDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    if (payment != null) {
      _nameController.text = payment.name;
      _amountController.text = payment.amount.toStringAsFixed(2);
      _institutionController.text = payment.institution ?? '';
      _noteController.text = payment.note ?? '';
      _type = payment.type;
      _dueDate = payment.dueDate;
      _recurring = payment.recurring;
      _recurrenceFrequency = payment.recurrenceFrequency ?? 'MONTHLY';
      _intervalController.text = (payment.recurrenceInterval ?? 1).toString();
      _recurrenceEndDate = payment.recurrenceEndDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _institutionController.dispose();
    _noteController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    var scope = 'THIS';
    if (widget.isEditing && widget.payment!.seriesId != null) {
      final selected = await _selectSeriesScope();
      if (selected == null || !mounted) return;
      scope = selected;
    }

    setState(() => _saving = true);
    try {
      final interval = _recurring ? int.parse(_intervalController.text) : null;
      final args = (
        name: _nameController.text.trim(),
        type: _type,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        dueDate: _dueDate,
        recurring: _recurring,
        recurrenceDay: _recurring && _usesMonthlyAnchor ? _dueDate.day : null,
        recurrenceFrequency: _recurring ? _recurrenceFrequency : null,
        recurrenceInterval: interval,
        recurrenceEndDate: _recurring ? _recurrenceEndDate : null,
        institution: _institutionController.text.trim().isEmpty ? null : _institutionController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (widget.isEditing) {
        await _repository.updatePayment(
          id: widget.payment!.id,
          name: args.name,
          type: args.type,
          amount: args.amount,
          dueDate: args.dueDate,
          recurring: args.recurring,
          scope: scope,
          recurrenceDay: args.recurrenceDay,
          recurrenceFrequency: args.recurrenceFrequency,
          recurrenceInterval: args.recurrenceInterval,
          recurrenceEndDate: args.recurrenceEndDate,
          institution: args.institution,
          note: args.note,
        );
      } else {
        await _repository.createPayment(
          name: args.name,
          type: args.type,
          amount: args.amount,
          dueDate: args.dueDate,
          recurring: args.recurring,
          recurrenceDay: args.recurrenceDay,
          recurrenceFrequency: args.recurrenceFrequency,
          recurrenceInterval: args.recurrenceInterval,
          recurrenceEndDate: args.recurrenceEndDate,
          institution: args.institution,
          note: args.note,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _selectSeriesScope() => showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hangi ödemeler değişsin?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Ödenmiş geçmiş kayıtlar toplu değişikliklerde korunur.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.looks_one_outlined),
                  title: const Text('Sadece bu ödeme'),
                  subtitle: const Text('Serinin diğer tarihleri değişmez'),
                  onTap: () => Navigator.pop(context, 'THIS'),
                ),
                ListTile(
                  leading: const Icon(Icons.trending_flat),
                  title: const Text('Bu ve sonraki ödemeler'),
                  subtitle: const Text('Bu tarihten itibaren bekleyen kayıtları günceller'),
                  onTap: () => Navigator.pop(context, 'THIS_AND_FUTURE'),
                ),
                ListTile(
                  leading: const Icon(Icons.all_inclusive),
                  title: const Text('Tüm seri'),
                  subtitle: const Text('Bekleyen tüm seri kayıtlarını günceller'),
                  onTap: () => Navigator.pop(context, 'ALL'),
                ),
              ],
            ),
          ),
        ),
      );

  bool get _usesMonthlyAnchor =>
      _recurrenceFrequency == 'MONTHLY' || _recurrenceFrequency == 'CUSTOM_MONTHS';

  String get _intervalLabel => switch (_recurrenceFrequency) {
        'WEEKLY' => 'Kaç haftada bir',
        'YEARLY' => 'Kaç yılda bir',
        'CUSTOM_DAYS' => 'Kaç günde bir',
        'CUSTOM_MONTHS' => 'Kaç ayda bir',
        _ => 'Kaç ayda bir',
      };

  String get _recurrenceSummary => switch (_recurrenceFrequency) {
        'WEEKLY' => 'Haftalık',
        'YEARLY' => 'Yıllık',
        'CUSTOM_DAYS' => 'Özel gün aralığı',
        'CUSTOM_MONTHS' => 'Özel ay aralığı',
        _ => 'Aylık',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Ödemeyi düzenle' : 'Ödeme ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ödeme adı', border: OutlineInputBorder()),
              validator: (value) => value == null || value.trim().isEmpty ? 'Ödeme adı gerekli' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tür', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'CREDIT_CARD', child: Text('Kredi kartı')),
                DropdownMenuItem(value: 'LOAN', child: Text('Kredi')),
                DropdownMenuItem(value: 'SUBSCRIPTION', child: Text('Abonelik')),
                DropdownMenuItem(value: 'BILL', child: Text('Fatura')),
                DropdownMenuItem(value: 'OTHER', child: Text('Diğer')),
              ],
              onChanged: (value) => setState(() => _type = value ?? 'OTHER'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Tutar', prefixText: '₺ ', border: OutlineInputBorder()),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                return parsed == null || parsed <= 0 ? 'Geçerli bir tutar gir' : null;
              },
            ),
            const SizedBox(height: 14),
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              title: const Text('Son ödeme tarihi'),
              subtitle: Text('${_dueDate.day}.${_dueDate.month}.${_dueDate.year}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tekrarlayan ödeme'),
              subtitle: Text(_recurring ? _recurrenceSummary : 'Tek seferlik ödeme'),
              value: _recurring,
              onChanged: (value) => setState(() => _recurring = value),
            ),
            if (_recurring) ...[
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _recurrenceFrequency,
                decoration: const InputDecoration(labelText: 'Tekrar sıklığı', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'WEEKLY', child: Text('Haftalık')),
                  DropdownMenuItem(value: 'MONTHLY', child: Text('Aylık')),
                  DropdownMenuItem(value: 'YEARLY', child: Text('Yıllık')),
                  DropdownMenuItem(value: 'CUSTOM_DAYS', child: Text('Özel • gün aralığı')),
                  DropdownMenuItem(value: 'CUSTOM_MONTHS', child: Text('Özel • ay aralığı')),
                ],
                onChanged: (value) => setState(() {
                  _recurrenceFrequency = value ?? 'MONTHLY';
                  if (_recurrenceFrequency == 'MONTHLY' ||
                      _recurrenceFrequency == 'WEEKLY' ||
                      _recurrenceFrequency == 'YEARLY') {
                    _intervalController.text = '1';
                  }
                }),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _intervalController,
                enabled: _recurrenceFrequency == 'CUSTOM_DAYS' || _recurrenceFrequency == 'CUSTOM_MONTHS',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _intervalLabel, border: const OutlineInputBorder()),
                validator: (value) {
                  if (!_recurring) return null;
                  final parsed = int.tryParse(value ?? '');
                  return parsed == null || parsed < 1 ? 'En az 1 olmalı' : null;
                },
              ),
              const SizedBox(height: 14),
              ListTile(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                title: const Text('Bitiş tarihi'),
                subtitle: Text(
                  _recurrenceEndDate == null
                      ? 'Süresiz'
                      : '${_recurrenceEndDate!.day}.${_recurrenceEndDate!.month}.${_recurrenceEndDate!.year}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_recurrenceEndDate != null)
                      IconButton(
                        tooltip: 'Bitiş tarihini kaldır',
                        onPressed: () => setState(() => _recurrenceEndDate = null),
                        icon: const Icon(Icons.close),
                      ),
                    const Icon(Icons.event_repeat),
                  ],
                ),
                onTap: () async {
                  final initial = _recurrenceEndDate ?? _dueDate.add(const Duration(days: 30));
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial.isBefore(_dueDate) ? _dueDate : initial,
                    firstDate: _dueDate,
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _recurrenceEndDate = picked);
                },
              ),
              if (_usesMonthlyAnchor) ...[
                const SizedBox(height: 8),
                Text(
                  'Ayın ${_dueDate.day}. günü hedeflenir; kısa aylarda otomatik olarak ayın son gününe çekilir.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _institutionController,
              decoration: const InputDecoration(labelText: 'Kurum / banka', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Not', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Kaydediliyor...' : widget.isEditing ? 'Değişiklikleri kaydet' : 'Ödemeyi kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
