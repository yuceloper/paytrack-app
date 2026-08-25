import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/network/authenticated_client.dart';

class AccountItem {
  final int id;
  final String name;
  final String type;
  final String? institution;
  final double balance;
  final String currency;
  final bool active;

  const AccountItem({
    required this.id,
    required this.name,
    required this.type,
    required this.institution,
    required this.balance,
    required this.currency,
    required this.active,
  });

  factory AccountItem.fromJson(Map<String, dynamic> json) => AccountItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        type: json['type'] as String,
        institution: json['institution'] as String?,
        balance: (json['balance'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'TRY',
        active: json['active'] as bool? ?? true,
      );
}

class AccountTransactionItem {
  final int id;
  final String type;
  final int accountId;
  final int? counterAccountId;
  final int? categoryId;
  final double amount;
  final String currency;
  final DateTime occurredOn;
  final String description;
  final String? sourceType;
  final int? sourceId;
  final bool reversed;

  const AccountTransactionItem({
    required this.id,
    required this.type,
    required this.accountId,
    required this.counterAccountId,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.occurredOn,
    required this.description,
    required this.sourceType,
    required this.sourceId,
    required this.reversed,
  });

  factory AccountTransactionItem.fromJson(Map<String, dynamic> json) => AccountTransactionItem(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String,
        accountId: (json['accountId'] as num).toInt(),
        counterAccountId: (json['counterAccountId'] as num?)?.toInt(),
        categoryId: (json['categoryId'] as num?)?.toInt(),
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'TRY',
        occurredOn: DateTime.parse(json['occurredOn'] as String),
        description: json['description'] as String,
        sourceType: json['sourceType'] as String?,
        sourceId: (json['sourceId'] as num?)?.toInt(),
        reversed: json['reversed'] as bool? ?? false,
      );
}

class AccountRepository {
  final http.Client _client;

  AccountRepository({http.Client? client}) : _client = client ?? AuthenticatedClient();

  Future<List<AccountItem>> fetchAll() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/accounts')
        .replace(queryParameters: {'userId': AppConfig.demoUserId.toString()});
    final response = await _client.get(uri);
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? const [];
    return data.map((e) => AccountItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AccountTransactionItem>> fetchTransactions({
    required DateTime from,
    required DateTime to,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/account-transactions').replace(queryParameters: {
      'userId': AppConfig.demoUserId.toString(),
      'from': _date(from),
      'to': _date(to),
    });
    final response = await _client.get(uri);
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? const [];
    return data.map((e) => AccountTransactionItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create({
    required String name,
    required String type,
    required double balance,
    String? institution,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/accounts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': AppConfig.demoUserId,
        'name': name,
        'type': type,
        'institution': institution?.trim().isEmpty == true ? null : institution?.trim(),
        'balance': balance,
        'currency': 'TRY',
        'active': true,
      }),
    );
    _ensureSuccess(response);
  }

  Future<void> update(AccountItem account, {required double balance}) async {
    final response = await _client.put(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/accounts/${account.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': AppConfig.demoUserId,
        'name': account.name,
        'type': account.type,
        'institution': account.institution,
        'balance': balance,
        'currency': account.currency,
        'active': account.active,
      }),
    );
    _ensureSuccess(response);
  }

  Future<void> transfer({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required String description,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/account-transactions/transfer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': AppConfig.demoUserId,
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'amount': amount,
        'description': description,
      }),
    );
    _ensureSuccess(response);
  }

  Future<void> createManualTransaction({
    required int accountId,
    required String type,
    required double amount,
    required String description,
    required DateTime occurredOn,
    int? categoryId,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/account-transactions/manual'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': AppConfig.demoUserId,
        'accountId': accountId,
        'type': type,
        'amount': amount,
        'categoryId': categoryId,
        'description': description,
        'occurredOn': _date(occurredOn),
      }),
    );
    _ensureSuccess(response);
  }

  Future<void> delete(int id) async {
    final response = await _client.delete(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/accounts/$id'));
    _ensureSuccess(response, allowNoContent: true);
  }

  String _date(DateTime value) => value.toIso8601String().split('T').first;

  void _ensureSuccess(http.Response response, {bool allowNoContent = false}) {
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (!ok) throw Exception('Hesap işlemi başarısız (${response.statusCode})');
    if (response.statusCode == 204 && !allowNoContent) return;
  }
}
