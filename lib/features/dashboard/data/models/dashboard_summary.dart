class DashboardSummary {
  final double dueThisMonth;
  final double dueNextSevenDays;
  final int upcomingPaymentCount;
  final double overdueAmount;
  final int overduePaymentCount;
  final double totalCreditCardDebt;
  final double monthlySubscriptionCost;
  final double yearlySubscriptionCost;

  const DashboardSummary({
    required this.dueThisMonth,
    required this.dueNextSevenDays,
    required this.upcomingPaymentCount,
    required this.overdueAmount,
    required this.overduePaymentCount,
    required this.totalCreditCardDebt,
    required this.monthlySubscriptionCost,
    required this.yearlySubscriptionCost,
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
    );
  }
}
