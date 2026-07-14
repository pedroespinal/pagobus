/// Tracks whether the transport service was actually received on a given
/// day for a driver, independent from the money/payment tracking. When
/// [received] is false the user must supply a [reason] (e.g. "bus broke
/// down", "child was sick", "driver on vacation").
class ServiceRecord {
  final String id;
  final String driverId;
  final DateTime date;
  final bool received;
  final String? reason;

  const ServiceRecord({
    required this.id,
    required this.driverId,
    required this.date,
    required this.received,
    this.reason,
  });

  ServiceRecord copyWith({
    bool? received,
    String? reason,
    bool clearReason = false,
  }) {
    return ServiceRecord(
      id: id,
      driverId: driverId,
      date: date,
      received: received ?? this.received,
      reason: clearReason ? null : (reason ?? this.reason),
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
      'received': received ? 1 : 0,
      'reason': reason,
    };
  }

  factory ServiceRecord.fromMap(Map<String, Object?> map) {
    return ServiceRecord(
      id: map['id'] as String,
      driverId: map['driverId'] as String,
      date: DateTime.parse(map['date'] as String),
      received: (map['received'] as int) == 1,
      reason: map['reason'] as String?,
    );
  }
}
