import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paytrack_app/features/payments/data/payment_repository.dart';
import 'package:paytrack_app/features/assistant/presentation/pages/assistant_page.dart';

void main() {
  testWidgets('only posts a monthly payment after explicit confirmation', (tester) async {
    final requests = <http.Request>[];
    final repository = PaymentRepository(client: MockClient((request) async {
      requests.add(request);
      return http.Response('{}', 201);
    }));
    await tester.pumpWidget(MaterialApp(home: AssistantPage(repository: repository)));
    await tester.enterText(find.byType(TextField).first,
        'TürkNet abonesiyim her ayın 27sinde 1900 TL ödüyorum');
    await tester.tap(find.byTooltip('Gönder'));
    await tester.pumpAndSettle();
    expect(find.text('AYLIK GİDER'), findsOneWidget);
    expect(requests, isEmpty);
    await tester.ensureVisible(find.text('Düzenle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    expect(requests, isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Gönder'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Onayla ve ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onayla ve ekle'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
    final payload = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(payload['name'], 'TürkNet');
    expect(payload['amount'], 1900);
    expect(payload['recurring'], true);
    expect(payload['recurrenceFrequency'], 'MONTHLY');
    expect(payload['recurrenceInterval'], 1);
    expect(payload['recurrenceDay'], 27);
  });
}
