import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class CategoryAnalyticsItem {
  final int? categoryId;
  final String categoryName;
  final double amount;
  final double percentage;

  const CategoryAnalyticsItem({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
  });

  factory CategoryAnalyticsItem.fromJson(Map<String, dynamic> json) => CategoryAnalyticsItem(
        categoryId: (json['categoryId'] as num?)?.toInt(),
        categoryName: json['categoryName'] as String,
        amount: (json['amount'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
      );
}

class MonthlyAnalytics {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;
  final double previousMonthExpense;
  final double? expenseChangePercent;
  final double? incomeExpenseRatio;
  final String? topExpenseCategory;
  final int transactionCount;
  final List<CategoryAnalyticsItem> expenseCategories;

  const MonthlyAnalytics({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.previousMonthExpense,
    required this.expenseChangePercent,
    required this.incomeExpenseRatio,
    required this.topExpenseCategory,
    required this.transactionCount,
    required this.expenseCategories,
  });

  factory MonthlyAnalytics.fromJson(Map<String, dynamic> json) => MonthlyAnalytics(
        year: (json['year'] as num).toInt(),
        month: (json['month'] as num).toInt(),
        totalIncome: (json['totalIncome'] as num).toDouble(),
        totalExpense: (json['totalExpense'] as num).toDouble(),
        netCashFlow: (json['netCashFlow'] as num).toDouble(),
        previousMonthExpense: (json['previousMonthExpense'] as num).toDouble(),
        expenseChangePercent: (json['expenseChangePercent'] as num?)?.toDouble(),
        incomeExpenseRatio: (json['incomeExpenseRatio'] as num?)?.toDouble(),
        topExpenseCategory: json['topExpenseCategory'] as String?,
        transactionCount: (json['transactionCount'] as num).toInt(),
        expenseCategories: (json['expenseCategories'] as List<dynamic>? ?? const [])
            .map((e) => CategoryAnalyticsItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AnalyticsRepository {
  final http.Client _client;

  AnalyticsRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<MonthlyAnalytics> fetchMonthly(DateTime month) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/analytics/monthly').replace(
      queryParameters: {
        'userId': AppConfig.demoUserId.toString(),
        'year': month.year.toString(),
        'month': month.month.toString(),
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('İstatistikler alınamadı (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return MonthlyAnalytics.fromJson(body['data'] as Map<String, dynamic>);
  }
}
