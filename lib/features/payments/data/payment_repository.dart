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
      body: _body(
        name: name,
        type: type,
        amount: amount,
        dueDate: dueDate,
        recurring: recurring,
        recurrenceDay: recurrenceDay,
        institution: institution,
        note: note,
      ),
    );
    _ensureSuccess(response, 'Ödeme kaydedilemedi');
  }

  Future<void> updatePayment({
    required int id,
    required String name,
    required String type,
    required double amount,
    required DateTime dueDate,
    required bool recurring,
    int? recurrenceDay,
    String? institution,
    String? note,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/payments/$id');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: _body(
        name: name,
        type: type,
        amount: amount,
        dueDate: dueDate,
        recurring: recurring,
        recurrenceDay: recurrenceDay,
        institution: institution,
        note: note,
      ),
    );
    _ensureSuccess(response, 'Ödeme güncellenemedi');
  }

  Future<void> markPaid(int id) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/payments/$id/paid');
    final response = await http.patch(uri);
    _ensureSuccess(response, 'Ödeme tamamlandı olarak işaretlenemedi');
  }

  Future<void> markPending(int id) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/payments/$id/pending');
    final response = await http.patch(uri);
    _ensureSuccess(response, 'Ödeme bekliyor olarak işaretlenemedi');
  }

  Future<void> deletePayment(int id) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/payments/$id');
    final response = await http.delete(uri);
    _ensureSuccess(response, 'Ödeme silinemedi');
  }

  String _body({
    required String name,
    required String type,
    required double amount,
    required DateTime dueDate,
    required bool recurring,
    int? recurrenceDay,
    String? institution,
    String? note,
  }) {
    return jsonEncode({
      'userId': AppConfig.demoUserId,
      'name': name,
      'type': type,
      'amount': amount,
      'dueDate': dueDate.toIso8601String().split('T').first,
      'recurring': recurring,
      'recurrenceDay': recurring ? recurrenceDay : null,
      'institution': institution,
      'note': note,
    });
  }

  void _ensureSuccess(http.Response response, String message) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$message (${response.statusCode})');
    }
  }
}
