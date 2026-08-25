class PaymentItem {
  final int id;
  final String name;
  final String type;
  final double amount;
  final DateTime dueDate;
  final bool recurring;
  final int? recurrenceDay;
  final String? recurrenceFrequency;
  final int? recurrenceInterval;
  final DateTime? recurrenceEndDate;
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
    this.recurrenceDay,
    this.recurrenceFrequency,
    this.recurrenceInterval,
    this.recurrenceEndDate,
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
      recurrenceDay: (json['recurrenceDay'] as num?)?.toInt(),
      recurrenceFrequency: json['recurrenceFrequency'] as String?,
      recurrenceInterval: (json['recurrenceInterval'] as num?)?.toInt(),
      recurrenceEndDate: json['recurrenceEndDate'] == null
          ? null
          : DateTime.parse(json['recurrenceEndDate'] as String),
      paid: json['paid'] as bool? ?? false,
      institution: json['institution'] as String?,
      note: json['note'] as String?,
    );
  }
}
