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
                  leading: CircleAvatar(
                    child: Icon(account.isLiability ? Icons.credit_score_outlined : Icons.account_balance_wallet_outlined),
                  ),
                  title: Text(account.name),
                  subtitle: Text(
                    account.isLiability && account.availableLimit != null
                        ? '${account.institution ?? 'Ek hesap'} • Kullanılabilir ${_money(account.availableLimit!)}'
                        : account.institution ?? account.type,
                  ),
                  trailing: Text(
                    _money(account.signedBalance),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: account.isLiability ? Theme.of(context).colorScheme.error : null,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, account),
                )),
          ],
        ),
      ),
    ),
  );
}

String _money(double value) => NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(value);
