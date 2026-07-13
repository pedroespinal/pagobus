import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/app_localizations.dart';
import '../models/child.dart';
import '../models/driver.dart';
import '../models/payment.dart';
import '../services/database_service.dart';
import '../services/holiday_service.dart';
import '../services/settings_service.dart';
import '../utils/currency_formatter.dart';
import 'add_payment_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<String, List<Payment>> _paymentsByDay = {};
  List<Driver> _drivers = [];
  List<Child> _children = [];
  bool _selectedDayExcluded = false;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
    _loadChildren();
    _loadMonth(_focusedDay);
    _refreshExclusion(_selectedDay);
  }

  Future<void> _loadDrivers() async {
    final drivers = await DatabaseService.instance.getDrivers();
    if (mounted) setState(() => _drivers = drivers);
  }

  Future<void> _loadChildren() async {
    final children = await DatabaseService.instance.getChildren();
    if (mounted) setState(() => _children = children);
  }

  Future<void> _loadMonth(DateTime month) async {
    final start = DateTime(month.year, month.month - 1, 1);
    final end = DateTime(month.year, month.month + 2, 0);
    final payments = await DatabaseService.instance.getPaymentsInRange(start, end);
    final grouped = <String, List<Payment>>{};
    for (final p in payments) {
      grouped.putIfAbsent(Payment.dateKey(p.date), () => []).add(p);
    }
    if (mounted) setState(() => _paymentsByDay = grouped);
  }

  Future<void> _refreshExclusion(DateTime day) async {
    final excluded = await HolidayService.instance.isExcludedDay(day);
    if (mounted) setState(() => _selectedDayExcluded = excluded);
  }

  List<Payment> _eventsForDay(DateTime day) {
    return _paymentsByDay[Payment.dateKey(day)] ?? [];
  }

  Future<void> _openAddPayment({Payment? existing}) async {
    if (_drivers.isEmpty) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddPaymentSheet(
        date: _selectedDay,
        isExcludedDay: _selectedDayExcluded,
        drivers: _drivers,
        children: _children,
        existing: existing,
      ),
    );
    if (saved == true) {
      _loadMonth(_focusedDay);
    }
  }

  Future<void> _togglePaid(Payment payment) async {
    await DatabaseService.instance.upsertPayment(payment.copyWith(paid: !payment.paid));
    _loadMonth(_focusedDay);
  }

  Future<void> _deletePayment(Payment payment) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeletePayment),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.instance.deletePayment(payment.id);
      _loadMonth(_focusedDay);
    }
  }

  String _driverName(String driverId) {
    final match = _drivers.where((d) => d.id == driverId);
    return match.isEmpty ? '' : match.first.name;
  }

  String? _childName(String? childId) {
    if (childId == null) return null;
    final match = _children.where((c) => c.id == childId);
    return match.isEmpty ? null : match.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final currencyCode = SettingsService.instance.currencyCode;
    final events = _eventsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarTitle)),
      body: Column(
        children: [
          TableCalendar<Payment>(
            locale: locale,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: _eventsForDay,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _refreshExclusion(selected);
            },
            onPageChanged: (focused) {
              _focusedDay = focused;
              _loadMonth(focused);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(color: scheme.onPrimary),
              weekendTextStyle: TextStyle(color: scheme.outline),
              markerDecoration: BoxDecoration(
                color: scheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false),
          ),
          const Divider(height: 1),
          if (_selectedDayExcluded)
            Container(
              width: double.infinity,
              color: scheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${isWeekendDay(_selectedDay) ? l10n.weekendLabel : l10n.holidayLabel} · ${l10n.extraServiceHint}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: events.isEmpty
                ? Center(child: Text(l10n.noPaymentsForDay))
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final payment = events[index];
                      return ListTile(
                        leading: Icon(
                          payment.paid ? Icons.check_circle : Icons.pending,
                          color: payment.paid ? Colors.green : Colors.orange,
                        ),
                        title: Text(
                          _childName(payment.childId) != null
                              ? '${_driverName(payment.driverId)} · ${_childName(payment.childId)}'
                              : _driverName(payment.driverId),
                        ),
                        subtitle: Text(
                          formatAmount(payment.amount, currencyCode) +
                              (payment.isExtra ? ' · ${l10n.holidayLabel}' : ''),
                        ),
                        onTap: () => _openAddPayment(existing: payment),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(payment.paid
                                  ? Icons.undo
                                  : Icons.check),
                              tooltip: payment.paid
                                  ? l10n.markAsUnpaid
                                  : l10n.markAsPaid,
                              onPressed: () => _togglePaid(payment),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deletePayment(payment),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddPayment(),
        icon: const Icon(Icons.add),
        label: Text(_selectedDayExcluded ? l10n.addExtraService : l10n.addPayment),
      ),
    );
  }

  bool isWeekendDay(DateTime day) =>
      day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
}
