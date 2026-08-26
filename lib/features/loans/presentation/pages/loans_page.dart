import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/loan_repository.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  final _repository = LoanRepository();
  late Future<List<LoanItem>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repository.fetchAll();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Krediler'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addLoan,
        icon: const Icon(Icons.add),
        label: const Text('Kredi ekle'),
      ),
      body: FutureBuilder<List<LoanItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(_reload),
            );
          }

          final loans = snapshot.data ?? const [];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                _Summary(loans: loans),
                const SizedBox(height: 18),
                if (loans.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Henüz kredi eklenmedi.'),
                    ),
                  )
                else
                  ...loans.map((loan) => _LoanCard(
                        loan: loan,
                        onDelete: () => _deleteLoan(loan),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteLoan(LoanItem loan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kredi silinsin mi?'),
        content: Text(
          '${loan.name} ve henüz ödenmemiş kredi taksitleri kaldırılacak. Ödenmiş taksiti olan krediler silinemez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.delete(loan.id);
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kredi silindi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _addLoan() async {
    final created = await showModalBottomSheet<_LoanDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddLoanSheet(),
    );
    if (created == null) return;

    try {
      await _repository.create(
        name: created.name,
        institutionName: created.institutionName,
        installmentAmount: created.installmentAmount,
        paymentDay: created.paymentDay,
        totalInstallments: created.totalInstallments,
        remainingInstallments: created.remainingInstallments,
        startDate: created.startDate,
        endDate: created.endDate,
      );
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kredi ve kalan taksitler eklendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

class _Summary extends StatelessWidget {
  final List<LoanItem> loans;

  const _Summary({required this.loans});

  @override
  Widget build(BuildContext context) {
    final active = loans.where((e) => e.active).toList();
    final remaining = active.fold<double>(0, (sum, e) => sum + e.remainingPayable);
    final monthly = active.fold<double>(0, (sum, e) => sum + e.installmentAmount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kredi özeti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Metric(label: 'Kalan ödeme', value: _currency(remaining))),
                const SizedBox(width: 12),
                Expanded(child: _Metric(label: 'Aylık taksit', value: _currency(monthly))),
              ],
            ),
            const SizedBox(height: 10),
            Text('${active.length} aktif kredi'),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanItem loan;
  final VoidCallback onDelete;

  const _LoanCard({required this.loan, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final paid = loan.paidInstallments;
    final end = loan.endDate == null ? null : DateFormat('d MMMM yyyy', 'tr_TR').format(loan.endDate!);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(loan.active ? Icons.account_balance : Icons.check_circle_outline),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loan.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text(loan.institutionName),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Sil')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$paid/${loan.totalInstallments} ödendi',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('${loan.remainingInstallments} taksit kaldı'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: loan.progress.clamp(0, 1)),
            const SizedBox(height: 16),
            _InfoLine(label: 'Aylık taksit', value: _currency(loan.installmentAmount)),
            const SizedBox(height: 7),
            _InfoLine(label: 'Kalan ödeme', value: _currency(loan.remainingPayable)),
            const SizedBox(height: 7),
            _InfoLine(label: 'Ödeme günü', value: 'Her ayın ${loan.paymentDay}. günü'),
            if (end != null) ...[
              const SizedBox(height: 7),
              _InfoLine(label: 'Bitiş tarihi', value: end),
            ],
            if (!loan.active) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 18),
                  SizedBox(width: 7),
                  Text('Kredi tamamlandı', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _LoanDraft {
  final String name;
  final String institutionName;
  final double installmentAmount;
  final int paymentDay;
  final int totalInstallments;
  final int remainingInstallments;
  final DateTime? startDate;
  final DateTime? endDate;

  const _LoanDraft({
    required this.name,
    required this.institutionName,
    required this.installmentAmount,
    required this.paymentDay,
    required this.totalInstallments,
    required this.remainingInstallments,
    required this.startDate,
    required this.endDate,
  });
}

class _AddLoanSheet extends StatefulWidget {
  const _AddLoanSheet();

  @override
  State<_AddLoanSheet> createState() => _AddLoanSheetState();
}

class _AddLoanSheetState extends State<_AddLoanSheet> {
  final _name = TextEditingController();
  final _institution = TextEditingController();
  final _installment = TextEditingController();
  final _paymentDay = TextEditingController();
  final _total = TextEditingController();
  final _remaining = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _institution.dispose();
    _installment.dispose();
    _paymentDay.dispose();
    _total.dispose();
    _remaining.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _startDate ?? DateTime.now(),
    );
    if (date != null) setState(() => _startDate = date);
  }

  Future<void> _pickEnd() async {
    final initial = _endDate ?? _startDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (date != null) setState(() => _endDate = date);
  }

  void _save() {
    final amount = double.tryParse(_installment.text.replaceAll(',', '.'));
    final day = int.tryParse(_paymentDay.text);
    final total = int.tryParse(_total.text);
    final remaining = int.tryParse(_remaining.text);

    if (_name.text.trim().isEmpty ||
        _institution.text.trim().isEmpty ||
        amount == null ||
        amount <= 0 ||
        day == null ||
        day < 1 ||
        day > 31 ||
        total == null ||
        total <= 0 ||
        remaining == null ||
        remaining < 0 ||
        remaining > total) {
      setState(() => _error = 'Alanları kontrol edin. Kalan taksit toplam taksitten büyük olamaz.');
      return;
    }

    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'Bitiş tarihi başlangıç tarihinden önce olamaz.');
      return;
    }

    Navigator.pop(
      context,
      _LoanDraft(
        name: _name.text.trim(),
        institutionName: _institution.text.trim(),
        installmentAmount: amount,
        paymentDay: day,
        totalInstallments: total,
        remainingInstallments: remaining,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'tr_TR');
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kredi ekle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Kredi adı')),
              const SizedBox(height: 12),
              TextField(controller: _institution, decoration: const InputDecoration(labelText: 'Banka / kurum')),
              const SizedBox(height: 12),
              TextField(
                controller: _installment,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Aylık taksit tutarı'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _paymentDay,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Ödeme günü'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _total,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Toplam taksit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _remaining,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kalan taksit',
                  helperText: 'Örn. 12 taksitin 3’ü ödendiyse 9',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStart,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(_startDate == null ? 'Başlangıç' : dateFormat.format(_startDate!)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickEnd,
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text(_endDate == null ? 'Bitiş' : dateFormat.format(_endDate!)),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 18),
              const Text(
                'Kredi kaydedildiğinde kalan taksitler ödeme takvimine otomatik eklenir.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _save, child: const Text('Krediyi kaydet')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 14),
            const Text('Krediler yüklenemedi', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tekrar dene')),
          ],
        ),
      ),
    );
  }
}

String _currency(double value) => NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    ).format(value);
