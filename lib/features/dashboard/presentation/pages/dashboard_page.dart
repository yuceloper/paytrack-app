import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../payments/presentation/pages/add_payment_page.dart';
import '../../application/dashboard_providers.dart';
import '../../data/dashboard_repository.dart';
import '../../data/models/upcoming_payment.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PayTrack'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => ref.invalidate(dashboardProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (data) => _DashboardContent(data: data),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddPaymentPage()),
          );
          if (created == true) {
            ref.invalidate(dashboardProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ödeme eklendi')),
              );
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ödeme ekle'),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardData data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;

    return RefreshIndicator(
      onRefresh: () async {
        final container = ProviderScope.containerOf(context);
        container.invalidate(dashboardProvider);
        await container.read(dashboardProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Merhaba 👋',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text('Yaklaşan ödemelerini tek yerden takip et.'),
          const SizedBox(height: 24),
          _SummaryCard(
            title: 'Bu ay ödenecek',
            value: _currency(summary.dueThisMonth),
            subtitle: 'Toplam planlanan ödeme',
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Önümüzdeki 7 gün',
            value: _currency(summary.dueNextSevenDays),
            subtitle: '${summary.upcomingPaymentCount} yaklaşan ödeme',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CompactSummaryCard(
                  title: 'Kart borcu',
                  value: _currency(summary.totalCreditCardDebt),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactSummaryCard(
                  title: 'Aylık abonelik',
                  value: _currency(summary.monthlySubscriptionCost),
                ),
              ),
            ],
          ),
          if (summary.overduePaymentCount > 0) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text('${summary.overduePaymentCount} gecikmiş ödeme'),
                trailing: Text(
                  _currency(summary.overdueAmount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          const Text(
            'Yaklaşan ödemeler',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (data.upcomingPayments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Önümüzdeki 7 gün için ödeme yok.'),
              ),
            )
          else
            ...data.upcomingPayments.map(_PaymentTile.new),
        ],
      ),
    );
  }

  static String _currency(double value) {
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    ).format(value);
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class _CompactSummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _CompactSummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final UpcomingPayment payment;

  const _PaymentTile(this.payment);

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMMM', 'tr_TR').format(payment.dueDate);
    final amount = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    ).format(payment.amount);

    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(_iconForType(payment.type))),
        title: Text(payment.name),
        subtitle: Text(date),
        trailing: Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.w700),
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
            const SizedBox(height: 16),
            const Text(
              'Backend bağlantısı kurulamadı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
