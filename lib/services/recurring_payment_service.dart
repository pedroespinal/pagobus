import 'package:uuid/uuid.dart';

import '../models/driver.dart';
import '../models/payment.dart';
import 'database_service.dart';
import 'holiday_service.dart';

const _uuid = Uuid();

/// Auto-generates the expected payment entries for a driver for a given
/// month, based on their default frequency and configured service weekdays,
/// skipping weekends/holidays and never duplicating a day that already has
/// a payment recorded.
class RecurringPaymentService {
  static Future<int> generateForMonth(
    Driver driver,
    DateTime monthAnchor,
  ) async {
    final db = DatabaseService.instance;
    final holidays = HolidayService.instance;
    final year = monthAnchor.year;
    final month = monthAnchor.month;
    final existing = await db.getPaymentsForDriver(driver.id);
    final existingKeys = existing.map((p) => Payment.dateKey(p.date)).toSet();
    final serviceDays = driver.serviceWeekdays;
    var created = 0;

    Future<void> createPayment(DateTime date) async {
      await db.upsertPayment(
        Payment(
          id: _uuid.v4(),
          driverId: driver.id,
          date: date,
          amount: driver.defaultAmount,
          paid: false,
        ),
      );
      created++;
    }

    switch (driver.defaultFrequency) {
      case PaymentFrequency.daily:
        final daysInMonth = DateTime(year, month + 1, 0).day;
        for (var d = 1; d <= daysInMonth; d++) {
          final date = DateTime(year, month, d);
          if (!serviceDays.contains(date.weekday)) continue;
          if (existingKeys.contains(Payment.dateKey(date))) continue;
          if (await holidays.isExcludedDay(date)) continue;
          await createPayment(date);
        }
        break;

      case PaymentFrequency.weekly:
        // Bill once per week, on the last configured service weekday of
        // that week (e.g. Friday for a Mon-Fri schedule).
        final billingWeekday = serviceDays.isEmpty
            ? DateTime.friday
            : serviceDays.reduce((a, b) => a > b ? a : b);
        final daysInMonth = DateTime(year, month + 1, 0).day;
        for (var d = 1; d <= daysInMonth; d++) {
          final date = DateTime(year, month, d);
          if (date.weekday != billingWeekday) continue;
          if (await holidays.isHoliday(date)) continue;
          final weekStart = date.subtract(Duration(days: date.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          final hasWeekPayment = existing.any(
            (p) => !p.date.isBefore(weekStart) && !p.date.isAfter(weekEnd),
          );
          if (hasWeekPayment) continue;
          await createPayment(date);
        }
        break;

      case PaymentFrequency.monthly:
        final hasMonthPayment = existing.any(
          (p) => p.date.year == year && p.date.month == month,
        );
        if (!hasMonthPayment) {
          var date = DateTime(year, month, 1);
          final lastDay = DateTime(year, month + 1, 0).day;
          while (await holidays.isExcludedDay(date) && date.day < lastDay) {
            date = date.add(const Duration(days: 1));
          }
          await createPayment(date);
        }
        break;
    }

    return created;
  }

  /// The amount a single calendar day should be pre-filled with for this
  /// driver. `defaultAmount` is a *period* total (the whole week or month),
  /// not a per-day figure, for weekly/monthly drivers — so a single day's
  /// entry must divide it down, otherwise adding one day would wrongly
  /// charge the full period amount (e.g. the whole month's 6000 instead of
  /// that day's 300 share of it).
  ///
  /// The monthly divisor is the driver's fixed `standardDaysPerMonth` (a
  /// convention the user picks, e.g. 20), not the actual varying weekday
  /// count of a given calendar month — otherwise the same driver's daily
  /// rate would drift from month to month, which doesn't match how a flat
  /// daily rate is normally agreed with a driver.
  static double dailyRate(Driver driver, DateTime referenceDate) {
    switch (driver.defaultFrequency) {
      case PaymentFrequency.daily:
        return driver.defaultAmount;
      case PaymentFrequency.weekly:
        final days = driver.serviceWeekdays.isEmpty
            ? 1
            : driver.serviceWeekdays.length;
        return driver.defaultAmount / days;
      case PaymentFrequency.monthly:
        final days = driver.standardDaysPerMonth <= 0
            ? defaultStandardDaysPerMonth
            : driver.standardDaysPerMonth;
        return driver.defaultAmount / days;
    }
  }
}
