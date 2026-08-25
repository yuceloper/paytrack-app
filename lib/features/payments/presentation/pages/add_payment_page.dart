import 'package:flutter/material.dart';
import '../../data/payment_repository.dart';

class AddPaymentPage extends StatefulWidget {
  const AddPaymentPage({super.key});

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _institutionController = TextEditingController();
  final _noteController = TextEditingController();
  final _repository = PaymentRepository();

  String _type = 'OTHER';
  DateTime _dueDate = DateTime.now();
  bool _recurring = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _institutionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repository.createPayment(
        name: _nameController.text.trim(),
        type: _type,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        dueDate: _dueDate,
        recurring: _recurring,
        recurrenceDay: _recurring ? _dueDate.day : null,
        institution: _institutionController.text.trim().isEmpty ? null : _institutionController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme ekle')),
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
              shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(4)),
              title: const Text('Son ödeme tarihi'),
              subtitle: Text('${_dueDate.day}.${_dueDate.month}.${_dueDate.year}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tekrarlayan ödeme'),
              subtitle: const Text('Her ay aynı gün tekrarlar'),
              value: _recurring,
              onChanged: (value) => setState(() => _recurring = value),
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _institutionController, decoration: const InputDecoration(labelText: 'Kurum / banka', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            TextFormField(controller: _noteController, maxLines: 3, decoration: const InputDecoration(labelText: 'Not', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Kaydediliyor...' : 'Ödemeyi kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
