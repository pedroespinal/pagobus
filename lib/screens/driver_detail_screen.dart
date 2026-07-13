import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/driver.dart';
import '../models/payment.dart';
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

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final payments =
        await DatabaseService.instance.getPaymentsForDriver(widget.driver.id);
    if (mounted) setState(() => _payments = payments);
  }

  Future<void> _togglePaid(Payment payment) async {
    await DatabaseService.instance.upsertPayment(payment.copyWith(paid: !payment.paid));
    _load();
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
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(created > 0
          ? l10n.generatePaymentsDone(created)
          : l10n.generatePaymentsNone),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final currencyCode = SettingsService.instance.currencyCode;
    final dateFormat = DateFormat.yMMMd(locale);

    final totalPaid = _payments
        .where((p) => p.paid)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final totalPending = _payments
        .where((p) => !p.paid)
        .fold<double>(0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(title: Text(widget.driver.name)),
      body: Column(
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
                        Text(l10n.totalPaid,
                            style: Theme.of(context).textTheme.labelLarge),
                        Text(
                          formatAmount(totalPaid, currencyCode),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.totalPending,
                            style: Theme.of(context).textTheme.labelLarge),
                        Text(
                          formatAmount(totalPending, currencyCode),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
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
                        trailing: IconButton(
                          icon: Icon(payment.paid ? Icons.undo : Icons.check),
                          tooltip:
                              payment.paid ? l10n.markAsUnpaid : l10n.markAsPaid,
                          onPressed: () => _togglePaid(payment),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generatePayments,
        icon: const Icon(Icons.auto_awesome),
        label: Text(l10n.generatePayments),
      ),
    );
  }
}
