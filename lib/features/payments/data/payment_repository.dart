import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';

class PaymentRepository {
  Future<void> createPayment({
    required String name,
    required String type,
    required double amount,
    required DateTime dueDate,
    required bool recurring,
    int? recurrenceDay,
    String? institution,
    String? note,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/payments');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': AppConfig.demoUserId,
        'name': name,
        'type': type,
        'amount': amount,
        'dueDate': dueDate.toIso8601String().split('T').first,
        'recurring': recurring,
        'recurrenceDay': recurring ? recurrenceDay : null,
        'institution': institution,
        'note': note,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Ödeme kaydedilemedi (${response.statusCode})');
    }
  }
}
