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

/// Weekdays (DateTime.monday..DateTime.sunday) on which a driver is expected
/// to provide the school-transport service. Defaults to Monday-Friday, since
/// that's the common case, but is fully configurable per driver.
const Set<int> defaultServiceWeekdays = {
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
};

class Driver {
  final String id;
  final String name;
  final String? company;
  final String? phone;
  final double defaultAmount;
  final PaymentFrequency defaultFrequency;
  final Set<int> serviceWeekdays;

  const Driver({
    required this.id,
    required this.name,
    this.company,
    this.phone,
    required this.defaultAmount,
    required this.defaultFrequency,
    this.serviceWeekdays = defaultServiceWeekdays,
  });

  Driver copyWith({
    String? name,
    String? company,
    String? phone,
    double? defaultAmount,
    PaymentFrequency? defaultFrequency,
    Set<int>? serviceWeekdays,
  }) {
    return Driver(
      id: id,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      defaultAmount: defaultAmount ?? this.defaultAmount,
      defaultFrequency: defaultFrequency ?? this.defaultFrequency,
      serviceWeekdays: serviceWeekdays ?? this.serviceWeekdays,
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
      'serviceWeekdays': (serviceWeekdays.toList()..sort()).join(','),
    };
  }

  factory Driver.fromMap(Map<String, Object?> map) {
    final weekdaysRaw = map['serviceWeekdays'] as String?;
    final weekdays = (weekdaysRaw == null || weekdaysRaw.isEmpty)
        ? defaultServiceWeekdays
        : weekdaysRaw.split(',').map(int.parse).toSet();
    return Driver(
      id: map['id'] as String,
      name: map['name'] as String,
      company: map['company'] as String?,
      phone: map['phone'] as String?,
      defaultAmount: (map['defaultAmount'] as num).toDouble(),
      defaultFrequency: PaymentFrequencyStorage.fromStorage(
        map['defaultFrequency'] as String,
      ),
      serviceWeekdays: weekdays,
    );
  }
}
