import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../data/bank_vault_service.dart';

class BankVaultPage extends StatefulWidget {
  const BankVaultPage({super.key});

  @override
  State<BankVaultPage> createState() => _BankVaultPageState();
}

class _BankVaultPageState extends State<BankVaultPage>
    with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  final _service = BankVaultService();

  List<BankVaultEntry> _entries = const [];
  bool _unlocked = false;
  bool _authenticating = false;
  bool _sensitiveAuthInProgress = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unlock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final shouldLock = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;

    // iOS may report inactive while the native Face ID sheet is on screen.
    // Do not lock the vault in the middle of our own authentication flow.
    if (shouldLock && !_authenticating && !_sensitiveAuthInProgress) {
      if (mounted) setState(() => _unlocked = false);
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _error = null;
    });

    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) {
        if (mounted) {
          setState(() =>
              _error = 'Bu cihazda biyometrik doğrulama kullanılamıyor.');
        }
        return;
      }

      final ok = await _auth.authenticate(
        localizedReason:
            'Banka Kasası içindeki şifrelerinizi görüntülemek için doğrulayın.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!ok || !mounted) return;

      final entries = await _service.load();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _unlocked = true;
      });
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() => _error = e.message ?? 'Biyometrik doğrulama başarısız.');
      }
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  Future<bool> _confirmSensitiveAction(String reason) async {
    if (_sensitiveAuthInProgress) return false;
    if (mounted) setState(() => _sensitiveAuthInProgress = true);

    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() => _sensitiveAuthInProgress = false);
    }
  }

  Future<void> _copyPassword(BankVaultEntry entry) async {
    final ok = await _confirmSensitiveAction(
      '${entry.bankName} şifresini kopyalamak için doğrulayın.',
    );
    if (!ok) return;

    await Clipboard.setData(ClipboardData(text: entry.password));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Şifre kopyalandı. 30 saniye sonra panodan temizlenecek.',
        ),
      ),
    );

    Timer(const Duration(seconds: 30), () async {
      final current = await Clipboard.getData('text/plain');
      if (current?.text == entry.password) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  Future<void> _showPassword(BankVaultEntry entry) async {
    final ok = await _confirmSensitiveAction(
      '${entry.bankName} şifresini görüntülemek için doğrulayın.',
    );
    if (!ok || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.bankName),
        content: SelectableText(
          entry.password,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _addEntry() async {
    final created = await showModalBottomSheet<BankVaultEntry>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _VaultEntrySheet(),
    );
    if (created == null) return;

    final updated = [..._entries, created];
    await _service.save(updated);
    if (mounted) setState(() => _entries = updated);
  }

  Future<void> _editEntry(BankVaultEntry entry) async {
    final ok = await _confirmSensitiveAction(
      '${entry.bankName} kasa kaydını düzenlemek için doğrulayın.',
    );
    if (!ok || !mounted) return;

    final edited = await showModalBottomSheet<BankVaultEntry>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VaultEntrySheet(existing: entry),
    );
    if (edited == null) return;

    final updated = _entries.map((e) => e.id == entry.id ? edited : e).toList();
    await _service.save(updated);
    if (mounted) setState(() => _entries = updated);
  }

  Future<void> _delete(BankVaultEntry entry) async {
    final ok = await _confirmSensitiveAction(
      '${entry.bankName} kaydını silmek için doğrulayın.',
    );
    if (!ok) return;

    final updated = _entries.where((e) => e.id != entry.id).toList();
    await _service.save(updated);
    if (mounted) setState(() => _entries = updated);
  }

  String _passwordAge(BankVaultEntry entry) {
    final days = DateTime.now().difference(entry.updatedAt).inDays;
    if (days <= 0) return 'Şifre bugün kaydedildi';
    if (days < 30) return 'Şifre $days gün önce güncellendi';
    final months = days ~/ 30;
    if (months < 12) return 'Şifre $months ay önce güncellendi';
    final years = days ~/ 365;
    return 'Şifre $years yıl önce güncellendi';
  }

  bool _passwordIsOld(BankVaultEntry entry) =>
      DateTime.now().difference(entry.updatedAt).inDays >= 180;

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Banka Kasası')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Banka Kasası kilitli',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ??
                      'Şifrelerinize erişmek için Face ID / biyometri ile doğrulayın.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _authenticating ? null : _unlock,
                  icon: const Icon(Icons.face),
                  label: Text(
                    _authenticating ? 'Doğrulanıyor...' : 'Kasayı aç',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banka Kasası'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _unlocked = false),
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Kilitle',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('Banka ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Şifreleriniz yalnızca bu telefonda, cihazın güvenli depolama alanında saklanır. PayTrack sunucularına gönderilmez ve hesabınızla senkronize edilmez.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Önemli: Bu cihaz silinir, değiştirilir veya kasa verileri kaldırılırsa şifreler PayTrack hesabınızdan geri getirilemez. Banka Kasası buluta yedeklenmez.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_entries.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('Kasada henüz kayıt yok.'),
              ),
            )
          else
            ..._entries.map(
              (entry) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      _passwordIsOld(entry)
                          ? Icons.warning_amber_rounded
                          : Icons.account_balance_outlined,
                    ),
                  ),
                  title: Text(entry.bankName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.username.isEmpty
                            ? 'Kullanıcı bilgisi eklenmedi'
                            : entry.username,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _passwordIsOld(entry)
                            ? '${_passwordAge(entry)} • Değiştirmeyi düşünebilirsiniz'
                            : _passwordAge(entry),
                        style: TextStyle(
                          fontSize: 12,
                          color: _passwordIsOld(entry)
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'show') _showPassword(entry);
                      if (value == 'copy') _copyPassword(entry);
                      if (value == 'edit') _editEntry(entry);
                      if (value == 'delete') _delete(entry);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'show',
                        child: Text('Şifreyi göster'),
                      ),
                      PopupMenuItem(
                        value: 'copy',
                        child: Text('Şifreyi kopyala'),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Düzenle / şifreyi güncelle'),
                      ),
                      PopupMenuItem(value: 'delete', child: Text('Sil')),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _VaultEntrySheet extends StatefulWidget {
  final BankVaultEntry? existing;

  const _VaultEntrySheet({this.existing});

  @override
  State<_VaultEntrySheet> createState() => _VaultEntrySheetState();
}

class _VaultEntrySheetState extends State<_VaultEntrySheet> {
  late final TextEditingController _bank;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final entry = widget.existing;
    _bank = TextEditingController(text: entry?.bankName ?? '');
    _username = TextEditingController(text: entry?.username ?? '');
    _password = TextEditingController(text: entry?.password ?? '');
    _note = TextEditingController(text: entry?.note ?? '');
  }

  @override
  void dispose() {
    _bank.dispose();
    _username.dispose();
    _password.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (_bank.text.trim().isEmpty || _password.text.isEmpty) return;

    final now = DateTime.now();
    final existing = widget.existing;
    final result = existing == null
        ? BankVaultEntry(
            id: now.microsecondsSinceEpoch.toString(),
            bankName: _bank.text.trim(),
            username: _username.text.trim(),
            password: _password.text,
            note: _note.text.trim(),
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            bankName: _bank.text.trim(),
            username: _username.text.trim(),
            password: _password.text,
            note: _note.text.trim(),
            updatedAt: _password.text == existing.password
                ? existing.updatedAt
                : now,
          );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                editing ? 'Kasa kaydını düzenle' : 'Banka şifresi ekle',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bank,
                decoration: const InputDecoration(labelText: 'Banka adı'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _username,
                decoration:
                    const InputDecoration(labelText: 'Müşteri / kullanıcı no'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'Şifre'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Not (opsiyonel)'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
              if (!editing) ...[
                const SizedBox(height: 14),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu kayıt yalnızca bu cihazda saklanır. Telefon silinir, değiştirilir veya PayTrack kaldırılırsa kasa verileri geri getirilemeyebilir.',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(editing ? 'Kaydet' : 'Kasaya kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
