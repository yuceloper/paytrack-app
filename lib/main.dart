import 'package:flutter/material.dart';

void main() {
  runApp(const PayTrackApp());
}

class PayTrackApp extends StatelessWidget {
  const PayTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PayTrack',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3157D5)),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayTrack'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Merhaba 👋',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text('Yaklaşan ödemelerini tek yerden takip et.'),
          SizedBox(height: 24),
          _SummaryCard(
            title: 'Bu ay ödenecek',
            value: '₺31.420',
            subtitle: 'Toplam planlanan ödeme',
          ),
          SizedBox(height: 12),
          _SummaryCard(
            title: 'Önümüzdeki 7 gün',
            value: '₺18.550',
            subtitle: '3 yaklaşan ödeme',
          ),
          SizedBox(height: 28),
          Text(
            'Yaklaşan ödemeler',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _PaymentTile(name: 'Spotify', date: '25 Ağustos', amount: '₺99,99'),
          _PaymentTile(name: 'Kredi Kartı', date: '28 Ağustos', amount: '₺18.450'),
          _PaymentTile(name: 'Kredi Taksiti', date: '1 Eylül', amount: '₺7.850'),
        ],
      ),
      floatingActionButton: const FloatingActionButton.extended(
        onPressed: null,
        icon: Icon(Icons.add),
        label: Text('Ödeme ekle'),
      ),
    );
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
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String name;
  final String date;
  final String amount;

  const _PaymentTile({required this.name, required this.date, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
        title: Text(name),
        subtitle: Text(date),
        trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
