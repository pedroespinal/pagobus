import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/driver.dart';
import '../models/payment.dart';
import '../models/service_record.dart';
import '../services/attendance_service.dart';
import '../services/database_service.dart';
import '../services/recurring_payment_service.dart';
import '../services/settings_service.dart';
import '../utils/currency_formatter.dart';

class DriverDetailScreen extends StatefulWidget {
  final Driver driver;

  const DriverDetailScreen({super.key, required this.driver});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Payment> _payments = [];
  List<ServiceRecord> _attendance = [];
  DateTime _attendanceMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadPayments();
    _loadAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    final payments = await DatabaseService.instance.getPaymentsForDriver(
      widget.driver.id,
    );
    if (mounted) setState(() => _payments = payments);
  }

  Future<void> _loadAttendance() async {
    // Auto-generate this month's expected service days (defaulting to
    // "received") so the user only has to flip the ones that were missed.
    await AttendanceService.ensureRecordsForMonth(
      widget.driver,
      _attendanceMonth,
    );
    final records = await DatabaseService.instance.getServiceRecordsInRange(
      widget.driver.id,
      DateTime(_attendanceMonth.year, _attendanceMonth.month, 1),
      DateTime(_attendanceMonth.year, _attendanceMonth.month + 1, 0),
    );
    if (mounted) setState(() => _attendance = records);
  }

  void _changeAttendanceMonth(int delta) {
    setState(() {
      _attendanceMonth = DateTime(
        _attendanceMonth.year,
        _attendanceMonth.month + delta,
        1,
      );
    });
    _loadAttendance();
  }

  Future<void> _togglePaid(Payment payment) async {
    await DatabaseService.instance.upsertPayment(
      payment.copyWith(paid: !payment.paid),
    );
    _loadPayments();
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
      _loadPayments();
    }
  }

  Future<void> _generatePayments() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.generatePaymentsConfirmTitle),
        content: Text(l10n.generatePaymentsConfirm(widget.driver.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final created = await RecurringPaymentService.generateForMonth(
      widget.driver,
      DateTime.now(),
    );
    await _loadPayments();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created > 0
              ? l10n.generatePaymentsDone(created)
              : l10n.generatePaymentsNone,
        ),
      ),
    );
  }

  Future<void> _toggleAttendance(ServiceRecord record) async {
    if (record.received) {
      // Marking as not-received requires a reason.
      final reason = await _promptAbsenceReason(initialValue: record.reason);
      if (reason == null) return; // cancelled
      await DatabaseService.instance.upsertServiceRecord(
        record.copyWith(received: false, reason: reason),
      );
    } else {
      await DatabaseService.instance.upsertServiceRecord(
        record.copyWith(received: true, clearReason: true),
      );
    }
    _loadAttendance();
  }

  Future<void> _editReason(ServiceRecord record) async {
    final reason = await _promptAbsenceReason(initialValue: record.reason);
    if (reason == null) return;
    await DatabaseService.instance.upsertServiceRecord(
      record.copyWith(reason: reason),
    );
    _loadAttendance();
  }

  Future<String?> _promptAbsenceReason({String? initialValue}) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialValue ?? '');
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notReceived),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.reasonLabel,
              hintText: l10n.reasonHint,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.reasonRequired : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab(
    AppLocalizations l10n,
    String locale,
    String currencyCode,
    DateFormat dateFormat,
    double bottomPadding,
  ) {
    final totalPaid = _payments
        .where((p) => p.paid)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final totalPending = _payments
        .where((p) => !p.paid)
        .fold<double>(0, (sum, p) => sum + p.amount);

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
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
                Expanded(
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
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _payments.isEmpty
              ? Center(child: Text(l10n.noPaymentsForDay))
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return ListTile(
                      leading: Icon(
                        payment.paid ? Icons.check_circle : Icons.pending,
                        color: payment.paid ? Colors.green : Colors.orange,
                      ),
                      title: Text(dateFormat.format(payment.date)),
                      subtitle: Text(
                        formatAmount(payment.amount, currencyCode) +
                            (payment.isExtra ? ' · ${l10n.holidayLabel}' : ''),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(payment.paid ? Icons.undo : Icons.check),
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
    );
  }

  Widget _buildAttendanceTab(
    AppLocalizations l10n,
    String locale,
    DateFormat dateFormat,
    double bottomPadding,
  ) {
    final monthFormat = DateFormat.yMMMM(locale);
    final receivedCount = _attendance.where((r) => r.received).length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeAttendanceMonth(-1),
            ),
            Text(
              monthFormat.format(_attendanceMonth),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeAttendanceMonth(1),
            ),
          ],
        ),
        if (_attendance.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.attendanceMonthSummary(receivedCount, _attendance.length),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: _attendance.isEmpty
              ? Center(child: Text(l10n.noAttendanceRecords))
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  itemCount: _attendance.length,
                  itemBuilder: (context, index) {
                    final record = _attendance[index];
                    return ListTile(
                      leading: Icon(
                        record.received ? Icons.check_circle : Icons.cancel,
                        color: record.received ? Colors.green : Colors.red,
                      ),
                      title: Text(dateFormat.format(record.date)),
                      subtitle: record.received
                          ? Text(l10n.received)
                          : Text(
                              record.reason ?? '',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                      onTap: !record.received
                          ? () => _editReason(record)
                          : null,
                      trailing: Switch(
                        value: record.received,
                        onChanged: (_) => _toggleAttendance(record),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final currencyCode = SettingsService.instance.currencyCode;
    final dateFormat = DateFormat.yMMMd(locale);
    final bottomPadding = 96 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.driver.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.paymentsTabLabel),
            Tab(text: l10n.attendanceLabel),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPaymentsTab(
              l10n,
              locale,
              currencyCode,
              dateFormat,
              bottomPadding,
            ),
            _buildAttendanceTab(l10n, locale, dateFormat, bottomPadding),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _generatePayments,
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.generatePayments),
            )
          : null,
    );
  }
}
