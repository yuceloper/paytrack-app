import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class IncomeSourceItem {
  final int id;
  final String name;
  final String type;
  final double amount;
  final String currency;
  final String frequency;
  final int? recurrenceDay;
  final DateTime nextIncomeDate;
  final bool active;

  const IncomeSourceItem({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.currency,
    required this.frequency,
    required this.recurrenceDay,
    required this.nextIncomeDate,
    required this.active,
  });

  factory IncomeSourceItem.fromJson(Map<String, dynamic> json) => IncomeSourceItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        frequency: json['frequency'] as String,
        recurrenceDay: (json['recurrenceDay'] as num?)?.toInt(),
        nextIncomeDate: DateTime.parse(json['nextIncomeDate'] as String),
        active: json['active'] as bool? ?? true,
      );
}

class IncomeOccurrenceItem {
  final int id;
  final String name;
  final double amount;
  final String currency;
  final DateTime expectedDate;
  final bool received;

  const IncomeOccurrenceItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.expectedDate,
    required this.received,
  });

  factory IncomeOccurrenceItem.fromJson(Map<String, dynamic> json) => IncomeOccurrenceItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        expectedDate: DateTime.parse(json['expectedDate'] as String),
        received: json['received'] as bool? ?? false,
      );
}

class IncomeRepository {
  final http.Client _client;

  IncomeRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<IncomeOccurrenceItem>> fetchMonth(DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/incomes/occurrences?userId=${AppConfig.demoUserId}&from=${_date(from)}&to=${_date(to)}',
    );
    final data = await _getData(uri) as List<dynamic>;
    return data.map((e) => IncomeOccurrenceItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createSource({
    required String name,
    required String type,
    required double amount,
    required String frequency,
    required DateTime nextIncomeDate,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/incomes/sources');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': AppConfig.demoUserId,
        'name': name,
        'type': type,
        'amount': amount,
        'currency': 'TRY',
        'frequency': frequency,
        'recurrenceDay': frequency == 'MONTHLY' ? nextIncomeDate.day : null,
        'nextIncomeDate': _date(nextIncomeDate),
      }),
    );
    _ensureSuccess(response);
  }

  Future<void> markReceived(int id) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/incomes/occurrences/$id/received');
    _ensureSuccess(await _client.patch(uri));
  }

  Future<dynamic> _getData(Uri uri) async {
    final response = await _client.get(uri);
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'];
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gelir işlemi başarısız (${response.statusCode})');
    }
  }

  String _date(DateTime date) => date.toIso8601String().split('T').first;
}
