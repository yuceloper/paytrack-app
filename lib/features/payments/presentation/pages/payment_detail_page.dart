import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../data/models/payment_item.dart';
import '../../data/payment_repository.dart';
import 'add_payment_page.dart';

class PaymentDetailPage extends StatefulWidget {
  final PaymentItem payment;

  const PaymentDetailPage({super.key, required this.payment});

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  final _repository = PaymentRepository();
  bool _busy = false;

  Future<void> _togglePaid() async {
    if (widget.payment.paid) {
      await _runAction(
        () => _repository.markPending(widget.payment.id),
        'Ödeme bekliyor durumuna alındı',
      );
      return;
    }

    final account = await showAccountPicker(context, title: 'Ödeme hangi hesaptan yapıldı?');
    if (account == null || !mounted) return;
    await _runAction(
      () => _repository.markPaid(widget.payment.id, accountId: account.id),
      '${account.name} hesabından ödeme işlendi',
    );
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddPaymentPage(payment: widget.payment)),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödemeyi sil?'),
        content: Text('${widget.payment.name} kalıcı olarak silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(() => _repository.deletePayment(widget.payment.id), 'Ödeme silindi');
  }

  Future<void> _runAction(Future<void> Function() action, String message) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final date = DateFormat('d MMMM yyyy', 'tr_TR').format(payment.dueDate);
    final amount = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(payment.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme detayı'),
        actions: [
          IconButton(onPressed: _busy ? null : _edit, icon: const Icon(Icons.edit_outlined), tooltip: 'Düzenle'),
          IconButton(onPressed: _busy ? null : _delete, icon: const Icon(Icons.delete_outline), tooltip: 'Sil'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(payment.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
                    if (payment.paid) const Chip(label: Text('Ödendi')),
                  ]),
                  const SizedBox(height: 12),
                  Text(amount, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  _DetailRow(label: 'Tür', value: _typeLabel(payment.type)),
                  _DetailRow(label: 'Son ödeme', value: date),
                  if (payment.institution != null && payment.institution!.isNotEmpty)
                    _DetailRow(label: 'Kurum / banka', value: payment.institution!),
                  _DetailRow(label: 'Tekrarlayan', value: payment.recurring ? 'Evet' : 'Hayır'),
                  if (payment.note != null && payment.note!.isNotEmpty) _DetailRow(label: 'Not', value: payment.note!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _togglePaid,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(payment.paid ? Icons.undo : Icons.check_circle_outline),
            label: Text(_busy
                ? 'İşleniyor...'
                : payment.paid
                    ? 'Bekliyor olarak işaretle'
                    : 'Ödendi olarak işaretle'),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        'CREDIT_CARD' => 'Kredi kartı',
        'LOAN' => 'Kredi',
        'SUBSCRIPTION' => 'Abonelik',
        'BILL' => 'Fatura',
        _ => 'Diğer',
      };
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
