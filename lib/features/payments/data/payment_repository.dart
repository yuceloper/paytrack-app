import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/network/authenticated_client.dart';
import 'models/payment_item.dart';

class PaymentRepository {
  final http.Client _client;

  PaymentRepository({http.Client? client}) : _client = client ?? AuthenticatedClient();

  Future<List<PaymentItem>> getPayments({required DateTime from, required DateTime to}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/payments').replace(queryParameters: {
      'userId': AppConfig.demoUserId.toString(),
      'from': _date(from),
      'to': _date(to),
    });
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Ödemeler alınamadı (${response.statusCode})');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? const [];
    return data.map((item) => PaymentItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> createPayment({
    required String name,
    required String type,
    required double amount,
    required DateTime dueDate,
    required bool recurring,
    int? recurrenceDay,
    String? recurrenceFrequency,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    String? institution,
    String? note,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/payments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_payload(
        name: name,
        type: type,
        amount: amount,
        dueDate: dueDate,
        recurring: recurring,
        recurrenceDay: recurrenceDay,
        recurrenceFrequency: recurrenceFrequency,
        recurrenceInterval: recurrenceInterval,
        recurrenceEndDate: recurrenceEndDate,
        institution: institution,
        note: note,
      )),
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
    String scope = 'THIS',
    int? recurrenceDay,
    String? recurrenceFrequency,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    String? institution,
    String? note,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/payments/$id').replace(
      queryParameters: {'scope': scope},
    );
    final response = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_payload(
        name: name,
        type: type,
        amount: amount,
        dueDate: dueDate,
        recurring: recurring,
        recurrenceDay: recurrenceDay,
        recurrenceFrequency: recurrenceFrequency,
        recurrenceInterval: recurrenceInterval,
        recurrenceEndDate: recurrenceEndDate,
        institution: institution,
        note: note,
      )),
    );
    _ensureSuccess(response, 'Ödeme güncellenemedi');
  }

  Future<void> markPaid(int id, {int? accountId}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/payments/$id/paid').replace(
      queryParameters: accountId == null ? null : {'accountId': accountId.toString()},
    );
    final response = await _client.patch(uri);
    _ensureSuccess(response, 'Ödeme tamamlanamadı');
  }

  Future<void> markPending(int id) async {
    final response = await _client.patch(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/payments/$id/pending'));
    _ensureSuccess(response, 'Ödeme bekliyor durumuna alınamadı');
  }

  Future<void> deletePayment(int id, {String scope = 'THIS'}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/payments/$id').replace(
      queryParameters: {'scope': scope},
    );
    final response = await _client.delete(uri);
    _ensureSuccess(response, 'Ödeme silinemedi');
  }

  Map<String, dynamic> _payload({
    required String name,
    required String type,
    required double amount,
    required DateTime dueDate,
    required bool recurring,
    int? recurrenceDay,
    String? recurrenceFrequency,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    String? institution,
    String? note,
  }) => {
        'userId': AppConfig.demoUserId,
        'name': name,
        'type': type,
        'amount': amount,
        'dueDate': _date(dueDate),
        'recurring': recurring,
        'recurrenceDay': recurring ? recurrenceDay : null,
        'recurrenceFrequency': recurring ? recurrenceFrequency : null,
        'recurrenceInterval': recurring ? recurrenceInterval : null,
        'recurrenceEndDate': recurring && recurrenceEndDate != null ? _date(recurrenceEndDate) : null,
        'institution': institution,
        'note': note,
      };

  String _date(DateTime value) => value.toIso8601String().split('T').first;

  void _ensureSuccess(http.Response response, String message) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$message (${response.statusCode})');
    }
  }
}
