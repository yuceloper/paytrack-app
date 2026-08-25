import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/semantic_colors.dart';
import '../../data/models/payment_item.dart';
import '../../data/payment_repository.dart';
import 'add_payment_page.dart';
import 'payment_detail_page.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final _repository = PaymentRepository();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<List<PaymentItem>> _payments;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final from = DateTime(_month.year, _month.month, 1);
    final to = DateTime(_month.year, _month.month + 1, 0);
    _payments = _repository.getPayments(from: from, to: to);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödemeler'),
        actions: [
          IconButton(
            tooltip: 'Ödeme ekle',
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddPaymentPage()),
              );
              if (changed == true) setState(_reload);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy', 'tr_TR').format(_month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PaymentItem>>(
              future: _payments,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                final payments = snapshot.data ?? const <PaymentItem>[];
                if (payments.isEmpty) {
                  return const Center(child: Text('Bu ay için ödeme yok.'));
                }
                final pendingTotal = payments.where((p) => !p.paid).fold<double>(0, (sum, p) => sum + p.amount);
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_reload);
                    await _payments;
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Card(
                        color: pendingTotal > 0 ? SemanticColors.expenseSoftFor(context) : null,
                        child: ListTile(
                          title: const Text('Kalan toplam'),
                          trailing: Text(
                            NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(pendingTotal),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: pendingTotal > 0 ? SemanticColors.expenseFor(context) : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...payments.map((payment) => _PaymentListTile(
                            payment: payment,
                            onChanged: () => setState(_reload),
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentListTile extends StatelessWidget {
  final PaymentItem payment;
  final VoidCallback onChanged;

  const _PaymentListTile({required this.payment, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMMM', 'tr_TR').format(payment.dueDate);
    final amount = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(payment.amount);
    final accent = payment.paid ? SemanticColors.incomeFor(context) : SemanticColors.expenseFor(context);
    final accentSoft = payment.paid ? SemanticColors.incomeSoftFor(context) : SemanticColors.expenseSoftFor(context);

    return Card(
      child: ListTile(
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => PaymentDetailPage(payment: payment)),
          );
          if (changed == true) onChanged();
        },
        leading: CircleAvatar(
          backgroundColor: accentSoft,
          child: Icon(
            payment.paid ? Icons.check : _iconForType(payment.type),
            color: accent,
          ),
        ),
        title: Text(
          payment.name,
          style: TextStyle(decoration: payment.paid ? TextDecoration.lineThrough : null),
        ),
        subtitle: Text('$date • ${payment.paid ? 'Ödendi' : 'Bekliyor'}'),
        trailing: Text(
          amount,
          style: TextStyle(fontWeight: FontWeight.w700, color: accent),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'CREDIT_CARD' => Icons.credit_card,
      'LOAN' => Icons.account_balance,
      'SUBSCRIPTION' => Icons.autorenew,
      'BILL' => Icons.receipt_long,
      _ => Icons.payments_outlined,
    };
  }
}
