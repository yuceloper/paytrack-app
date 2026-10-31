import 'package:flutter_test/flutter_test.dart';
import 'package:paytrack_app/features/payments/application/payment_text_parser.dart';

void main() {
  PaymentTextDraft parse(String text, [DateTime? now]) =>
      PaymentTextParser.parse(text, now: now ?? DateTime(2026, 10, 12));

  test('extracts the full conversational internet subscription example', () {
    final draft = parse('Bu ay eve internet bağlattım, TürkNet abonesiyim '
        'her ayın 27sinde 1900 TL ödüyorum');
    expect(draft.name, 'TürkNet');
    expect(draft.amount, 1900);
    expect(draft.day, 27);
    expect(draft.dueDate, DateTime(2026, 10, 27));
    expect(draft.type, 'SUBSCRIPTION');
  });

  test('supports Turkish grouping, decimals and curly apostrophe', () {
    expect(parse('TürkNet her ayın 27’sinde 1.900,50 TL').amount, 1900.50);
  });

  test('does not skip today even in the evening', () {
    expect(parse('Kira her ayın 27sinde 1900 TL', DateTime(2026, 10, 27, 23))
        .dueDate, DateTime(2026, 10, 27));
  });

  test('moves a past day to next year when necessary', () {
    expect(parse('Kira her ayın 27sinde 1900 TL', DateTime(2026, 12, 28))
        .dueDate, DateTime(2027, 1, 27));
  });

  test('clamps February while retaining the monthly day anchor', () {
    final draft = parse('Kira her ayın 31inde 1900 TL', DateTime(2027, 2, 3));
    expect(draft.day, 31);
    expect(draft.dueDate, DateTime(2027, 2, 28));
    expect(parse('Kira her ayın 31inde 1900 TL', DateTime(2028, 2, 3))
        .dueDate, DateTime(2028, 2, 29));
  });

  for (final text in [
    'TürkNet 1900 TL',
    'TürkNet her ayın 32sinde 1900 TL',
    'TürkNet her ayın 0ında 1900 TL',
    'TürkNet her ayın 27sinde 0 TL',
    'TürkNet her ayın 27sinde -1900 TL',
    'TürkNet her ayın 27sinde 1900',
    'TürkNet her ayın 27sinde 1900 TL veya 2000 TL',
    'TürkNet ve Netflix her ayın 27sinde 1900 TL',
    'TürkNet her ayın 27sinde veya her ayın 28inde 1900 TL',
    'Bilinmeyen gider her ayın 27sinde 1900 TL',
    'TürkNet her ayın 27sinde 1900.50 TL',
  ]) {
    test('requests clarification for: $text', () {
      expect(() => parse(text), throwsFormatException);
    });
  }
}
