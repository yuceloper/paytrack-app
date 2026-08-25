class UpcomingPayment {
  final int id;
  final String name;
  final String type;
  final double amount;
  final DateTime dueDate;
  final bool recurring;
  final String? institution;
  final String? note;

  const UpcomingPayment({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.dueDate,
    required this.recurring,
    this.institution,
    this.note,
  });

  factory UpcomingPayment.fromJson(Map<String, dynamic> json) {
    return UpcomingPayment(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      recurring: json['recurring'] as bool? ?? false,
      institution: json['institution'] as String?,
      note: json['note'] as String?,
    );
  }
}
