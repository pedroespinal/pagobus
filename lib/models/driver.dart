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

/// Standard number of days used to split a monthly `defaultAmount` into a
/// single day's charge (e.g. 6000/month ÷ 20 = 300/day). This is a fixed,
/// user-chosen convention rather than the actual number of weekdays in a
/// given calendar month (which varies 20-23 and would make the daily rate
/// drift month to month, confusing users who already agreed on a flat
/// daily rate with the driver).
const int defaultStandardDaysPerMonth = 20;

class Driver {
  final String id;
  final String name;
  final String? company;
  final String? phone;
  final double defaultAmount;
  final PaymentFrequency defaultFrequency;
  final Set<int> serviceWeekdays;
  final int standardDaysPerMonth;

  /// Children this driver normally carries. Empty means "no restriction" —
  /// any child in the system can be picked when logging a payment for this
  /// driver. Non-empty narrows the child dropdown to just these children and
  /// auto-selects the child when there's exactly one.
  final Set<String> assignedChildIds;

  const Driver({
    required this.id,
    required this.name,
    this.company,
    this.phone,
    required this.defaultAmount,
    required this.defaultFrequency,
    this.serviceWeekdays = defaultServiceWeekdays,
    this.standardDaysPerMonth = defaultStandardDaysPerMonth,
    this.assignedChildIds = const {},
  });

  Driver copyWith({
    String? name,
    String? company,
    String? phone,
    double? defaultAmount,
    PaymentFrequency? defaultFrequency,
    Set<int>? serviceWeekdays,
    int? standardDaysPerMonth,
    Set<String>? assignedChildIds,
  }) {
    return Driver(
      id: id,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      defaultAmount: defaultAmount ?? this.defaultAmount,
      defaultFrequency: defaultFrequency ?? this.defaultFrequency,
      serviceWeekdays: serviceWeekdays ?? this.serviceWeekdays,
      standardDaysPerMonth: standardDaysPerMonth ?? this.standardDaysPerMonth,
      assignedChildIds: assignedChildIds ?? this.assignedChildIds,
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
      'standardDaysPerMonth': standardDaysPerMonth,
      'assignedChildIds': assignedChildIds.join(','),
    };
  }

  factory Driver.fromMap(Map<String, Object?> map) {
    final weekdaysRaw = map['serviceWeekdays'] as String?;
    final weekdays = (weekdaysRaw == null || weekdaysRaw.isEmpty)
        ? defaultServiceWeekdays
        : weekdaysRaw.split(',').map(int.parse).toSet();
    final childIdsRaw = map['assignedChildIds'] as String?;
    final childIds = (childIdsRaw == null || childIdsRaw.isEmpty)
        ? const <String>{}
        : childIdsRaw.split(',').toSet();
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
      standardDaysPerMonth:
          (map['standardDaysPerMonth'] as num?)?.toInt() ??
          defaultStandardDaysPerMonth,
      assignedChildIds: childIds,
    );
  }
}
