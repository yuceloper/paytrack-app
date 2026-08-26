import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/network/authenticated_client.dart';

class CreditCardItem {
  final int id;
  final String name;
  final String bankName;
  final String? lastFourDigits;
  final int statementDay;
  final int dueDay;
  final double creditLimit;
  final double currentDebt;
  final double availableLimit;
  final double minimumPayment;
  final bool active;

  const CreditCardItem({
    required this.id,
    required this.name,
    required this.bankName,
    required this.lastFourDigits,
    required this.statementDay,
    required this.dueDay,
    required this.creditLimit,
    required this.currentDebt,
    required this.availableLimit,
    required this.minimumPayment,
    required this.active,
  });

  factory CreditCardItem.fromJson(Map<String, dynamic> json) => CreditCardItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        bankName: json['bankName'] as String,
        lastFourDigits: json['lastFourDigits'] as String?,
        statementDay: (json['statementDay'] as num).toInt(),
        dueDay: (json['dueDay'] as num).toInt(),
        creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
        currentDebt: (json['currentDebt'] as num?)?.toDouble() ?? 0,
        availableLimit: (json['availableLimit'] as num?)?.toDouble() ?? 0,
        minimumPayment: (json['minimumPayment'] as num?)?.toDouble() ?? 0,
        active: json['active'] as bool? ?? true,
      );
}

class CreditCardRepository {
  final http.Client _client;

  CreditCardRepository({http.Client? client}) : _client = client ?? AuthenticatedClient();

  Future<List<CreditCardItem>> fetchAll() async {
    final response = await _client.get(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/credit-cards'));
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? const [];
    return data.map((e) => CreditCardItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create({
    required String name,
    required String bankName,
    String? lastFourDigits,
    required int statementDay,
    required int dueDay,
    required double creditLimit,
    required double currentDebt,
    required double minimumPayment,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/credit-cards'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'bankName': bankName,
        'lastFourDigits': lastFourDigits?.trim().isEmpty == true ? null : lastFourDigits?.trim(),
        'statementDay': statementDay,
        'dueDay': dueDay,
        'creditLimit': creditLimit,
        'currentDebt': currentDebt,
        'minimumPayment': minimumPayment,
      }),
    );
    _ensureSuccess(response);
  }

  Future<void> delete(int id) async {
    final response = await _client.delete(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/credit-cards/$id'));
    _ensureSuccess(response, allowNoContent: true);
  }

  void _ensureSuccess(http.Response response, {bool allowNoContent = false}) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Kredi kartı işlemi başarısız (${response.statusCode})');
  }
}
