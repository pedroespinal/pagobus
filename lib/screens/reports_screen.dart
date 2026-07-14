import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/child.dart';
import '../models/driver.dart';
import '../models/payment.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../utils/currency_formatter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<Driver> _drivers = [];
  List<Child> _children = [];
  List<Payment> _monthPayments = [];
  List<double> _last6MonthsTotals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final drivers = await db.getDrivers();
    final children = await db.getChildren();
    final monthStart = DateTime(_month.year, _month.month, 1);
    final monthEnd = DateTime(_month.year, _month.month + 1, 0);
    final monthPayments = await db.getPaymentsInRange(monthStart, monthEnd);

    final trend = <double>[];
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(_month.year, _month.month - i, 1);
      final start = DateTime(m.year, m.month, 1);
      final end = DateTime(m.year, m.month + 1, 0);
      final payments = await db.getPaymentsInRange(start, end);
      trend.add(payments.fold<double>(0, (sum, p) => sum + p.amount));
    }

    if (mounted) {
      setState(() {
        _drivers = drivers;
        _children = children;
        _monthPayments = monthPayments;
        _last6MonthsTotals = trend;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
    _load();
  }

  String _driverName(String driverId) {
    final match = _drivers.where((d) => d.id == driverId);
    return match.isEmpty ? '?' : match.first.name;
  }

  String _childName(String childId) {
    final match = _children.where((c) => c.id == childId);
    return match.isEmpty ? '?' : match.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final currencyCode = SettingsService.instance.currencyCode;
    final scheme = Theme.of(context).colorScheme;
    final monthFormat = DateFormat.yMMMM(locale);

    final totalPaid = _monthPayments
        .where((p) => p.paid)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final totalPending = _monthPayments
        .where((p) => !p.paid)
        .fold<double>(0, (sum, p) => sum + p.amount);

    final totalsByDriver = <String, double>{};
    for (final p in _monthPayments) {
      totalsByDriver.update(
        p.driverId,
        (v) => v + p.amount,
        ifAbsent: () => p.amount,
      );
    }
    final driverEntries = totalsByDriver.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalsByChild = <String, double>{};
    for (final p in _monthPayments) {
      final childId = p.childId;
      if (childId == null) continue;
      totalsByChild.update(
        childId,
        (v) => v + p.amount,
        ifAbsent: () => p.amount,
      );
    }
    final childEntries = totalsByChild.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                monthFormat.format(_month),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalPaid,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          formatAmount(totalPaid, currencyCode),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalPending,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          formatAmount(totalPending, currencyCode),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_monthPayments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text(l10n.noDataForReports)),
            )
          else ...[
            Text(
              l10n.totalByDriver,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _EntryBarChart(
              entries: driverEntries,
              labelFor: _driverName,
              color: scheme.primary,
            ),
            if (childEntries.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                l10n.totalByChild,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _EntryBarChart(
                entries: childEntries,
                labelFor: _childName,
                color: scheme.tertiary,
              ),
            ],
            const SizedBox(height: 32),
            Text(
              l10n.monthlyTrend,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (_last6MonthsTotals.isEmpty
                          ? 1
                          : _last6MonthsTotals.reduce(
                              (a, b) => a > b ? a : b,
                            )) *
                      1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= 6) {
                            return const SizedBox.shrink();
                          }
                          final m = DateTime(
                            _month.year,
                            _month.month - (5 - index),
                            1,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat.MMM(locale).format(m),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var i = 0; i < _last6MonthsTotals.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: _last6MonthsTotals[i],
                            color: scheme.secondary,
                            width: 24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bar chart for a list of (id, total) entries, labeling each bar via
/// [labelFor]. Used for both the "total by driver" and "total by child"
/// breakdowns, which are structurally identical.
class _EntryBarChart extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final String Function(String id) labelFor;
  final Color color;

  const _EntryBarChart({
    required this.entries,
    required this.labelFor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  final name = labelFor(entries[index].key);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name.length > 8 ? '${name.substring(0, 8)}…' : name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < entries.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: entries[i].value,
                    color: color,
                    width: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
