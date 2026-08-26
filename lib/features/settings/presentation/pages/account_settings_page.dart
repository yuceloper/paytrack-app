import 'package:flutter/material.dart';

import '../../../../core/auth/google_link_service.dart';
import '../../../../core/auth/session_store.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _linking = false;

  @override
  Widget build(BuildContext context) {
    final linked = !SessionStore.guest;

    return Scaffold(
      appBar: AppBar(title: const Text('Hesap')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Icon(linked ? Icons.verified_user_outlined : Icons.person_outline),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              linked ? 'Hesabın güvende' : 'Misafir olarak kullanıyorsun',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              linked
                                  ? 'PayTrack verilerin Google hesabınla ilişkilendirildi.'
                                  : 'Verilerin bu cihazdaki misafir hesabına bağlı. Google ile bağlayarak hesabını kalıcı hale getirebilirsin.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!linked) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _linking ? null : _linkGoogle,
                        icon: _linking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.account_circle_outlined),
                        label: Text(_linking ? 'Bağlanıyor...' : 'Google ile hesabını bağla'),
                      ),
                    ),
                    if (!GoogleLinkService.isConfigured) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Google OAuth yapılandırması tamamlandığında bu buton aktif olarak giriş yapacak.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Verilerin taşınmaz'),
              subtitle: Text(
                'Google hesabını bağladığında mevcut ödeme, gelir, hesap ve hareketlerin aynı PayTrack kullanıcı kaydında kalır.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _linkGoogle() async {
    setState(() => _linking = true);
    try {
      await GoogleLinkService.linkCurrentGuest();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google hesabı başarıyla bağlandı')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }
}
