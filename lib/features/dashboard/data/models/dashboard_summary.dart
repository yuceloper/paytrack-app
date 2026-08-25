class DashboardSummary {
  final double dueThisMonth;
  final double dueNextSevenDays;
  final int upcomingPaymentCount;
  final double overdueAmount;
  final int overduePaymentCount;
  final double totalCreditCardDebt;
  final double monthlySubscriptionCost;
  final double yearlySubscriptionCost;
  final double expectedIncomeThisMonth;
  final double receivedIncomeThisMonth;
  final double plannedNetCashFlowThisMonth;
  final String? nextIncomeName;
  final DateTime? nextIncomeDate;
  final double nextIncomeAmount;
  final double requiredUntilNextIncome;

  const DashboardSummary({
    required this.dueThisMonth,
    required this.dueNextSevenDays,
    required this.upcomingPaymentCount,
    required this.overdueAmount,
    required this.overduePaymentCount,
    required this.totalCreditCardDebt,
    required this.monthlySubscriptionCost,
    required this.yearlySubscriptionCost,
    required this.expectedIncomeThisMonth,
    required this.receivedIncomeThisMonth,
    required this.plannedNetCashFlowThisMonth,
    required this.nextIncomeName,
    required this.nextIncomeDate,
    required this.nextIncomeAmount,
    required this.requiredUntilNextIncome,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) => (value as num?)?.toDouble() ?? 0;

    return DashboardSummary(
      dueThisMonth: number(json['dueThisMonth']),
      dueNextSevenDays: number(json['dueNextSevenDays']),
      upcomingPaymentCount: (json['upcomingPaymentCount'] as num?)?.toInt() ?? 0,
      overdueAmount: number(json['overdueAmount']),
      overduePaymentCount: (json['overduePaymentCount'] as num?)?.toInt() ?? 0,
      totalCreditCardDebt: number(json['totalCreditCardDebt']),
      monthlySubscriptionCost: number(json['monthlySubscriptionCost']),
      yearlySubscriptionCost: number(json['yearlySubscriptionCost']),
      expectedIncomeThisMonth: number(json['expectedIncomeThisMonth']),
      receivedIncomeThisMonth: number(json['receivedIncomeThisMonth']),
      plannedNetCashFlowThisMonth: number(json['plannedNetCashFlowThisMonth']),
      nextIncomeName: json['nextIncomeName'] as String?,
      nextIncomeDate: json['nextIncomeDate'] == null ? null : DateTime.parse(json['nextIncomeDate'] as String),
      nextIncomeAmount: number(json['nextIncomeAmount']),
      requiredUntilNextIncome: number(json['requiredUntilNextIncome']),
    );
  }
}
