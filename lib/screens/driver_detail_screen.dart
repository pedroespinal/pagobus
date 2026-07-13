import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/driver.dart';
import '../models/payment.dart';
import '../services/database_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final currency = NumberFormat.simpleCurrency(locale: locale);
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
                          currency.format(totalPaid),
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
                          currency.format(totalPending),
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
                          currency.format(payment.amount) +
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
    );
  }
}
