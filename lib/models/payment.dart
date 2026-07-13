class Payment {
  final String id;
  final String driverId;
  final DateTime date;
  final double amount;
  final bool paid;
  final bool isExtra;
  final String? note;

  const Payment({
    required this.id,
    required this.driverId,
    required this.date,
    required this.amount,
    required this.paid,
    this.isExtra = false,
    this.note,
  });

  Payment copyWith({
    double? amount,
    bool? paid,
    bool? isExtra,
    String? note,
  }) {
    return Payment(
      id: id,
      driverId: driverId,
      date: date,
      amount: amount ?? this.amount,
      paid: paid ?? this.paid,
      isExtra: isExtra ?? this.isExtra,
      note: note ?? this.note,
    );
  }

  static String dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'date': dateKey(date),
      'amount': amount,
      'paid': paid ? 1 : 0,
      'isExtra': isExtra ? 1 : 0,
      'note': note,
    };
  }

  factory Payment.fromMap(Map<String, Object?> map) {
    return Payment(
      id: map['id'] as String,
      driverId: map['driverId'] as String,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num).toDouble(),
      paid: (map['paid'] as int) == 1,
      isExtra: (map['isExtra'] as int) == 1,
      note: map['note'] as String?,
    );
  }
}
