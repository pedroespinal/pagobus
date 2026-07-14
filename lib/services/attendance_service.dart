import 'package:uuid/uuid.dart';

import '../models/driver.dart';
import '../models/service_record.dart';
import 'database_service.dart';
import 'holiday_service.dart';

const _uuid = Uuid();

/// Ensures a [ServiceRecord] (defaulting to "received") exists for every one
/// of the driver's configured service weekdays in the given month, skipping
/// weekends/holidays and days that already have a record. This is what lets
/// the user just flip a switch to "not received" + add a reason, instead of
/// having to create each day's attendance entry by hand.
class AttendanceService {
  static Future<int> ensureRecordsForMonth(
    Driver driver,
    DateTime monthAnchor,
  ) async {
    final db = DatabaseService.instance;
    final holidays = HolidayService.instance;
    final year = monthAnchor.year;
    final month = monthAnchor.month;
    final existing = await db.getServiceRecordsInRange(
      driver.id,
      DateTime(year, month, 1),
      DateTime(year, month + 1, 0),
    );
    final existingKeys = existing
        .map((r) => ServiceRecord.dateKey(r.date))
        .toSet();
    final daysInMonth = DateTime(year, month + 1, 0).day;
    var created = 0;

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      if (!driver.serviceWeekdays.contains(date.weekday)) continue;
      if (existingKeys.contains(ServiceRecord.dateKey(date))) continue;
      if (await holidays.isExcludedDay(date)) continue;
      await db.upsertServiceRecord(
        ServiceRecord(
          id: _uuid.v4(),
          driverId: driver.id,
          date: date,
          received: true,
        ),
      );
      created++;
    }
    return created;
  }
}
