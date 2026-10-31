/// A local parser for explicit Turkish monthly payment instructions.
/// Returns a draft only; callers must obtain confirmation before saving.
class PaymentTextDraft {
  const PaymentTextDraft({required this.name, required this.amount,
    required this.day, required this.dueDate, required this.type});

  final String name;
  final double amount;
  final int day;
  final DateTime dueDate;
  final String type;
}

class PaymentTextParser {
  static PaymentTextDraft parse(String input, {required DateTime now}) {
    final text = input.trim();
    final normalized = text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    final dates = RegExp(r"(?:her\s+ayın|her\s+ay|aylık|ayın)\s+(\d{1,2})(?!\d)")
        .allMatches(normalized).toList();
    if (dates.length != 1 ||
        !RegExp(r'her\s+ay|aylık').hasMatch(normalized)) {
      throw const FormatException('Tekrarı ve günü belirt: “her ayın 27’sinde” gibi.');
    }
    final day = int.parse(dates.single.group(1)!);
    if (day < 1 || day > 31) {
      throw const FormatException('Ayın günü 1 ile 31 arasında olmalı.');
    }
    final amounts = RegExp(r'(?<![\d.,+−-])\d+(?:\.\d{3})*(?:,\d{1,2})?\s*(?:tl|₺|lira)(?![a-zçğıöşü])')
        .allMatches(normalized).toList();
    if (amounts.length != 1) {
      throw const FormatException('Tek bir tutar belirt: “1900 TL” veya “1.900,50 TL” gibi.');
    }
    final numeric = RegExp(r'[\d.,]+').firstMatch(amounts.single.group(0)!)!.group(0)!;
    final amount = double.tryParse(numeric.replaceAll('.', '').replaceAll(',', '.'));
    if (amount == null || !amount.isFinite || amount <= 0) {
      throw const FormatException('Sıfırdan büyük bir tutar belirt.');
    }

    // Keep unknown names editable rather than guessing a merchant from prose.
    const merchants = {
      'türknet': 'TürkNet', 'turknet': 'TürkNet',
      'türk telekom': 'Türk Telekom', 'turk telekom': 'Türk Telekom',
      'superonline': 'Superonline', 'vodafone': 'Vodafone',
      'turkcell': 'Turkcell', 'netflix': 'Netflix', 'spotify': 'Spotify',
      'youtube': 'YouTube',
    };
    final found = merchants.entries.where((entry) =>
      RegExp('(?<![a-zçğıöşü])${entry.key}(?![a-zçğıöşü])').hasMatch(normalized))
        .map((entry) => entry.value).toSet();
    if (found.length > 1) {
      throw const FormatException('Her seferinde yalnızca bir gider yaz.');
    }
    String name;
    String type;
    if (found.isNotEmpty) {
      name = found.single;
      type = 'SUBSCRIPTION';
    } else if (normalized.contains('kira')) {
      name = 'Kira';
      type = 'OTHER';
    } else {
      throw const FormatException('Gider adını netleştiremedim. Aşağıdaki formdan ekleyebilirsin.');
    }
    DateTime occurrence(int year, int month) {
      final lastDay = DateTime(year, month + 1, 0).day;
      return DateTime(year, month, day > lastDay ? lastDay : day);
    }
    final today = DateTime(now.year, now.month, now.day);
    var dueDate = occurrence(now.year, now.month);
    if (dueDate.isBefore(today)) dueDate = occurrence(now.year, now.month + 1);
    return PaymentTextDraft(name: name, amount: amount, day: day,
      dueDate: dueDate, type: type);
  }
}
