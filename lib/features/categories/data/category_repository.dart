import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/network/authenticated_client.dart';

class TransactionCategoryItem {
  final int id;
  final String name;
  final String type;
  final String iconKey;
  final bool builtIn;
  final bool active;

  const TransactionCategoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.builtIn,
    required this.active,
  });

  factory TransactionCategoryItem.fromJson(Map<String, dynamic> json) => TransactionCategoryItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        type: json['type'] as String,
        iconKey: json['iconKey'] as String? ?? 'category',
        builtIn: json['builtIn'] as bool? ?? false,
        active: json['active'] as bool? ?? true,
      );

  bool supports(String transactionType) => type == 'BOTH' || type == transactionType;
}

class TransactionCategoryRepository {
  final http.Client _client;

  TransactionCategoryRepository({http.Client? client}) : _client = client ?? AuthenticatedClient();

  Future<List<TransactionCategoryItem>> fetchAll() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/categories');
    final response = await _client.get(uri);
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? const [];
    return data.map((e) => TransactionCategoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create({
    required String name,
    required String type,
    String iconKey = 'category',
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'type': type,
        'iconKey': iconKey,
      }),
    );
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Kategori işlemi başarısız (${response.statusCode})');
    }
  }
}
