import 'package:flutter/material.dart';

import '../../../creditcards/presentation/pages/credit_cards_page.dart';
import '../../../loans/presentation/pages/loans_page.dart';

class DebtHubPage extends StatelessWidget {
  const DebtHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borçlar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Borçlarını tek yerden yönet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('Kredi kartlarını ve kredilerini ayrı detaylarla takip et.'),
          const SizedBox(height: 22),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const CircleAvatar(child: Icon(Icons.credit_card_outlined)),
              title: const Text('Kredi kartları', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Limit, güncel borç, ekstre ve son ödeme günleri'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreditCardsPage()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const CircleAvatar(child: Icon(Icons.account_balance_outlined)),
              title: const Text('Krediler', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Taksit ilerlemesi, kalan ödeme ve bitiş tarihi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoansPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
