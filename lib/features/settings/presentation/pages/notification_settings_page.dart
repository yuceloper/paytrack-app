import 'package:flutter/material.dart';

import '../../../../core/notifications/notification_preferences.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/notifications/reminder_sync_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _store = NotificationPreferencesStore();
  NotificationPreferences _preferences = const NotificationPreferences();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _store.load();
    if (!mounted) return;
    setState(() {
      _preferences = value;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildirim izni kapalı. iPhone Ayarlar’dan açabilirsin.')),
        );
        return;
      }

      await _store.save(_preferences);
      final count = await ReminderSyncService().sync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ayarlar kaydedildi • $count hatırlatma planlandı')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay current) => showTimePicker(
        context: context,
        initialTime: current,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim ayarları')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                const Text(
                  'Ödemeler',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                _ReminderCard(
                  title: '1 gün önce',
                  subtitle: 'Ödeme tarihinden bir gün önce hatırlat',
                  enabled: _preferences.dayBeforeEnabled,
                  time: _preferences.dayBeforeTime,
                  onEnabledChanged: (value) => setState(() {
                    _preferences = _preferences.copyWith(dayBeforeEnabled: value);
                  }),
                  onTimeTap: () async {
                    final picked = await _pickTime(_preferences.dayBeforeTime);
                    if (picked != null && mounted) {
                      setState(() => _preferences = _preferences.copyWith(dayBeforeTime: picked));
                    }
                  },
                ),
                _ReminderCard(
                  title: 'Ödeme günü',
                  subtitle: 'Vade günü tekrar hatırlat',
                  enabled: _preferences.dueDayEnabled,
                  time: _preferences.dueDayTime,
                  onEnabledChanged: (value) => setState(() {
                    _preferences = _preferences.copyWith(dueDayEnabled: value);
                  }),
                  onTimeTap: () async {
                    final picked = await _pickTime(_preferences.dueDayTime);
                    if (picked != null && mounted) {
                      setState(() => _preferences = _preferences.copyWith(dueDayTime: picked));
                    }
                  },
                ),
                _ReminderCard(
                  title: 'Gecikince',
                  subtitle: 'Ödeme hâlâ bekliyorsa ertesi gün uyar',
                  enabled: _preferences.overdueEnabled,
                  time: _preferences.overdueTime,
                  onEnabledChanged: (value) => setState(() {
                    _preferences = _preferences.copyWith(overdueEnabled: value);
                  }),
                  onTimeTap: () async {
                    final picked = await _pickTime(_preferences.overdueTime);
                    if (picked != null && mounted) {
                      setState(() => _preferences = _preferences.copyWith(overdueTime: picked));
                    }
                  },
                ),
                const SizedBox(height: 22),
                const Text(
                  'Gelirler',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                _ReminderCard(
                  title: 'Gelir günü',
                  subtitle: 'Beklenen gelir tarihinde hatırlat',
                  enabled: _preferences.incomeDayEnabled,
                  time: _preferences.incomeDayTime,
                  onEnabledChanged: (value) => setState(() {
                    _preferences = _preferences.copyWith(incomeDayEnabled: value);
                  }),
                  onTimeTap: () async {
                    final picked = await _pickTime(_preferences.incomeDayTime);
                    if (picked != null && mounted) {
                      setState(() => _preferences = _preferences.copyWith(incomeDayTime: picked));
                    }
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.check),
                  label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet ve planla'),
                ),
              ],
            ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onTimeTap;

  const _ReminderCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.time,
    required this.onEnabledChanged,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: enabled,
            onChanged: onEnabledChanged,
            title: Text(title),
            subtitle: Text(subtitle),
          ),
          if (enabled)
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Saat'),
              trailing: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: onTimeTap,
            ),
        ],
      ),
    );
  }
}
