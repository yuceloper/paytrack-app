import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../payments/application/payment_text_parser.dart';
import '../../../payments/data/payment_repository.dart';
import '../../../payments/presentation/pages/add_payment_page.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key, this.repository});
  final PaymentRepository? repository;

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final _input = TextEditingController();
  late final _repository = widget.repository ?? PaymentRepository();
  PaymentTextDraft? _draft;
  String? _message;
  String? _reply;
  bool _saving = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    if (_saving || _input.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _message = _input.text.trim();
      _draft = null;
      try {
        _draft = PaymentTextParser.parse(_message!, now: DateTime.now());
        _reply = 'Şöyle bir gider hazırladım. Ekleyelim mi?';
      } on FormatException catch (error) {
        _reply = error.message;
      }
    });
  }

  Future<void> _confirm() async {
    final draft = _draft;
    if (_saving || draft == null) return;
    setState(() => _saving = true);
    try {
      await _repository.createPayment(
        name: draft.name, type: draft.type, amount: draft.amount,
        dueDate: draft.dueDate, recurring: true,
        recurrenceDay: draft.day, recurrenceFrequency: 'MONTHLY',
        recurrenceInterval: 1,
        institution: draft.type == 'SUBSCRIPTION' ? draft.name : null,
        note: _message,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _reply = 'Kayıt tamamlanamadı. Bağlantını kontrol edip tekrar dene.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => AddPaymentPage(
        repository: _repository, initialDraft: _draft, draftNote: _message,
      ),
    ));
    if (saved == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final draft = _draft;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('PayTrack Asistan')),
        body: SafeArea(
          child: Column(children: [
            Expanded(child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Icon(Icons.auto_awesome, size: 44, color: colors.primary),
                const SizedBox(height: 16),
                Text('Giderini anlat, birlikte ekleyelim.',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Şimdilik aylık abonelik ve kira eklemene yardımcı olabilirim. '
                  'Onayın olmadan kayıt oluşturmam.', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                if (_message == null)
                  ActionChip(
                    avatar: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('TürkNet gideriyle dene'),
                    onPressed: () => setState(() {
                      _input.text = 'TürkNet abonesiyim, her ayın 27’sinde 1900 TL ödüyorum.';
                    }),
                  ),
                if (_message != null) ...[
                  Align(alignment: Alignment.centerRight, child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(_message!, style: TextStyle(color: colors.onPrimaryContainer)),
                  )),
                  const SizedBox(height: 20),
                  Text(_reply ?? '', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                ],
                if (draft != null) Card(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('AYLIK GİDER'),
                    const SizedBox(height: 8),
                    Text(draft.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(draft.amount),
                      style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    Text('Her ayın ${draft.day}. günü'),
                    Text('İlk ödeme: ${DateFormat('dd.MM.yyyy').format(draft.dueDate)}'),
                    const Text('Bitiş: Süresiz'),
                    if (draft.day > 28) const Text('Kısa aylarda ayın son günü kullanılır.'),
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: FilledButton.icon(
                      onPressed: _saving ? null : _confirm,
                      icon: _saving
                        ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                      label: Text(_saving ? 'Ekleniyor…' : 'Onayla ve ekle'),
                    )),
                    Center(child: TextButton(onPressed: _saving ? null : _edit,
                      child: const Text('Düzenle'))),
                  ]),
                )),
                if (_message != null && draft == null)
                  TextButton(onPressed: _edit, child: const Text('Formdan ekle')),
              ],
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: TextField(
                  controller: _input, enabled: !_saving, minLines: 1, maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Örn. Her ayın 27’sinde TürkNet’e 1900 TL',
                    counterText: '', border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)))),
                )),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _saving ? null : _send,
                  tooltip: 'Gönder', icon: const Icon(Icons.arrow_upward)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
