class PaymentItem {
  final int id;
  final String name;
  final String type;
  final double amount;
  final DateTime dueDate;
  final bool recurring;
  final bool paid;
  final String? institution;
  final String? note;

  const PaymentItem({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.dueDate,
    required this.recurring,
    required this.paid,
    this.institution,
    this.note,
  });

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    return PaymentItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      recurring: json['recurring'] as bool? ?? false,
      paid: json['paid'] as bool? ?? false,
      institution: json['institution'] as String?,
      note: json['note'] as String?,
    );
  }
}
