import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/network/authenticated_client.dart';

class LoanItem {
  final int id;
  final String name;
  final String institutionName;
  final double installmentAmount;
  final int paymentDay;
  final int totalInstallments;
  final int remainingInstallments;
  final double? remainingPrincipal;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool active;

  const LoanItem({
    required this.id,
    required this.name,
    required this.institutionName,
    required this.installmentAmount,
    required this.paymentDay,
    required this.totalInstallments,
    required this.remainingInstallments,
    required this.remainingPrincipal,
    required this.startDate,
    required this.endDate,
    required this.active,
  });

  int get paidInstallments =>
      (totalInstallments - remainingInstallments).clamp(0, totalInstallments);
  double get remainingPayable => installmentAmount * remainingInstallments;
  double get progress =>
      totalInstallments <= 0 ? 0 : paidInstallments / totalInstallments;

  factory LoanItem.fromJson(Map<String, dynamic> json) => LoanItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        institutionName: json['institutionName'] as String,
        installmentAmount: (json['installmentAmount'] as num).toDouble(),
        paymentDay: (json['paymentDay'] as num).toInt(),
        totalInstallments: (json['totalInstallments'] as num).toInt(),
        remainingInstallments:
            (json['remainingInstallments'] as num).toInt(),
        remainingPrincipal: (json['remainingPrincipal'] as num?)?.toDouble(),
        startDate: _parseDate(json['startDate']),
        endDate: _parseDate(json['endDate']),
        active: json['active'] as bool? ?? true,
      );

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class LoanRepository {
  final http.Client _client;

  LoanRepository({http.Client? client})
      : _client = client ?? AuthenticatedClient();

  Future<List<LoanItem>> fetchAll() async {
    final response = await _client
        .get(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/loans'));
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .map((e) => LoanItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String name,
    required String institutionName,
    required double installmentAmount,
    required int paymentDay,
    required int totalInstallments,
    required int paidInstallments,
    required DateTime startDate,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/loans'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'institutionName': institutionName.trim(),
        'installmentAmount': installmentAmount,
        'paymentDay': paymentDay,
        'totalInstallments': totalInstallments,
        'paidInstallments': paidInstallments,
        'startDate': _dateOnly(startDate),
      }),
    );
    _ensureSuccess(response);
  }

  Future<void> delete(int id) async {
    final response = await _client
        .delete(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/loans/$id'));
    _ensureSuccess(response, allowNoContent: true);
  }

  String _dateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _ensureSuccess(http.Response response, {bool allowNoContent = false}) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Kredi işlemi başarısız (${response.statusCode})');
  }
}
