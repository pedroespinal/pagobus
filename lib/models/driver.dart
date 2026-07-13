enum PaymentFrequency { daily, weekly, monthly }

extension PaymentFrequencyStorage on PaymentFrequency {
  String get storageValue => name;

  static PaymentFrequency fromStorage(String value) {
    return PaymentFrequency.values.firstWhere(
      (f) => f.name == value,
      orElse: () => PaymentFrequency.daily,
    );
  }
}

class Driver {
  final String id;
  final String name;
  final String? company;
  final String? phone;
  final double defaultAmount;
  final PaymentFrequency defaultFrequency;

  const Driver({
    required this.id,
    required this.name,
    this.company,
    this.phone,
    required this.defaultAmount,
    required this.defaultFrequency,
  });

  Driver copyWith({
    String? name,
    String? company,
    String? phone,
    double? defaultAmount,
    PaymentFrequency? defaultFrequency,
  }) {
    return Driver(
      id: id,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      defaultAmount: defaultAmount ?? this.defaultAmount,
      defaultFrequency: defaultFrequency ?? this.defaultFrequency,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'phone': phone,
      'defaultAmount': defaultAmount,
      'defaultFrequency': defaultFrequency.storageValue,
    };
  }

  factory Driver.fromMap(Map<String, Object?> map) {
    return Driver(
      id: map['id'] as String,
      name: map['name'] as String,
      company: map['company'] as String?,
      phone: map['phone'] as String?,
      defaultAmount: (map['defaultAmount'] as num).toDouble(),
      defaultFrequency:
          PaymentFrequencyStorage.fromStorage(map['defaultFrequency'] as String),
    );
  }
}
