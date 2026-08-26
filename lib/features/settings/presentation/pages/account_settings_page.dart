import 'package:flutter/material.dart';

import '../../../../core/auth/account_profile_service.dart';
import '../../../../core/auth/auth_session_service.dart';
import '../../../../core/auth/google_link_service.dart';
import '../../../../core/auth/session_store.dart';
import '../../../vault/presentation/pages/bank_vault_page.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _linking = false;
  bool _loggingOut = false;
  late Future<AccountProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = AccountProfileService.load();
  }

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
                                  ? 'PayTrack verilerin Google hesabınla ilişkilendirildi ve yeni cihazlarda geri yüklenebilir.'
                                  : 'Verilerin bu misafir hesabında tutuluyor. Google ile bağlayarak hesabını kalıcı ve cihazlar arası kullanılabilir hale getirebilirsin.',
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
          if (linked) ...[
            const SizedBox(height: 14),
            _buildProfileCard(),
          ],
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.lock_outline)),
              title: const Text('Banka Kasası'),
              subtitle: const Text('Banka şifrelerini Face ID ile koruyup yalnızca bu telefonda sakla.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BankVaultPage()),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: Icon(linked ? Icons.sync_outlined : Icons.info_outline),
              title: Text(linked ? 'Yeni telefonda da devam et' : 'Mevcut verilerin kaybolmaz'),
              subtitle: Text(
                linked
                    ? 'Yeni bir cihazda PayTrack’i kurup aynı Google hesabını bağladığında eski verilerin geri gelir.'
                    : 'Google hesabını bağladığında mevcut ödeme, gelir, hesap ve hareketlerin korunur.',
              ),
            ),
          ),
          if (linked) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loggingOut ? null : _confirmLogout,
                icon: _loggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(_loggingOut ? 'Çıkış yapılıyor...' : 'Bu cihazdan çıkış yap'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Çıkış yaptığında Google hesabındaki PayTrack verilerin silinmez. Bu cihaz yeni bir misafir hesapla devam eder.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return FutureBuilder<AccountProfile>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
            child: ListTile(
              leading: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Google hesabın yükleniyor...'),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('Hesap bilgileri alınamadı'),
              subtitle: const Text('Bağlantını kontrol edip tekrar deneyebilirsin.'),
              trailing: IconButton(
                tooltip: 'Tekrar dene',
                onPressed: () => setState(() => _profile = AccountProfileService.load()),
                icon: const Icon(Icons.refresh),
              ),
            ),
          );
        }

        final profile = snapshot.data!;
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.account_circle_outlined)),
            title: Text(profile.name.isEmpty ? 'Google hesabı' : profile.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.email.isNotEmpty) Text(profile.email),
                const SizedBox(height: 2),
                const Text('Google ile bağlı'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _linkGoogle() async {
    setState(() => _linking = true);
    try {
      await GoogleLinkService.linkCurrentGuest();
      if (!mounted) return;
      setState(() {
        _profile = AccountProfileService.load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google hesabın bağlandı.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bu cihazdan çıkış yapılsın mı?'),
        content: const Text('Google hesabındaki verilerin silinmez. Bu cihaz çıkıştan sonra yeni bir misafir hesapla devam eder.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Çıkış yap')),
        ],
      ),
    );
    if (confirmed == true) await _logout();
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await AuthSessionService.logoutAndCreateGuest();
      if (!mounted) return;
      setState(() {
        _profile = AccountProfileService.load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu cihazdan çıkış yapıldı. Misafir hesapla devam ediyorsun.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }
}
