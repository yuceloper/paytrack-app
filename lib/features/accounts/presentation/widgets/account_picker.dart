import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/account_repository.dart';

Future<AccountItem?> showAccountPicker(BuildContext context, {required String title}) async {
  final repository = AccountRepository();
  final accounts = (await repository.fetchAll())
      .where((e) => e.active && e.currency == 'TRY')
      .toList();
  if (!context.mounted) return null;

  if (accounts.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesap bulunamadı'),
        content: const Text('Bu işlem için önce bir hesap eklemelisin.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam'))],
      ),
    );
    return null;
  }

  return showModalBottomSheet<AccountItem>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...accounts.map((account) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.account_balance_wallet_outlined)),
                  title: Text(account.name),
                  subtitle: Text(account.institution ?? account.type),
                  trailing: Text(
                    NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(account.balance),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () => Navigator.pop(context, account),
                )),
          ],
        ),
      ),
    ),
  );
}
