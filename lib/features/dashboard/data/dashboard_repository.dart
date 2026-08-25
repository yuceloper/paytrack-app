import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/network/authenticated_client.dart';
import '../../payments/data/models/payment_item.dart';
import 'models/dashboard_summary.dart';

class DashboardData {
  final DashboardSummary summary;
  final List<PaymentItem> upcomingPayments;

  const DashboardData({required this.summary, required this.upcomingPayments});
}

class DashboardRepository {
  final http.Client _client;

  DashboardRepository({http.Client? client}) : _client = client ?? AuthenticatedClient();

  Future<DashboardData> fetchDashboard({int? userId}) async {
    final resolvedUserId = userId ?? AppConfig.demoUserId;

    final results = await Future.wait([
      _get('/api/v1/dashboard/summary?userId=$resolvedUserId'),
      _get('/api/v1/payments/upcoming?userId=$resolvedUserId&days=7'),
    ]);

    final summaryEnvelope = results[0] as Map<String, dynamic>;
    final paymentsEnvelope = results[1] as Map<String, dynamic>;

    final summaryData = summaryEnvelope['data'] as Map<String, dynamic>?;
    final paymentData = paymentsEnvelope['data'] as List<dynamic>?;

    if (summaryData == null || paymentData == null) {
      throw const DashboardApiException('Backend response data is missing');
    }

    return DashboardData(
      summary: DashboardSummary.fromJson(summaryData),
      upcomingPayments: paymentData
          .map((item) => PaymentItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<dynamic> _get(String path) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DashboardApiException('HTTP ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const DashboardApiException('Invalid backend response');
    }

    if (body['success'] != true) {
      final error = body['error'];
      final message = error is Map<String, dynamic>
          ? error['message']?.toString()
          : null;
      throw DashboardApiException(message ?? 'Backend request failed');
    }

    return body;
  }
}

class DashboardApiException implements Exception {
  final String message;

  const DashboardApiException(this.message);

  @override
  String toString() => message;
}
