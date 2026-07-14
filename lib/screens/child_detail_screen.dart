import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/child.dart';
import '../models/driver.dart';
import '../models/payment.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../utils/currency_formatter.dart';

class ChildDetailScreen extends StatefulWidget {
  final Child child;

  const ChildDetailScreen({super.key, required this.child});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  List<Payment> _payments = [];
  List<Driver> _drivers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final payments = await DatabaseService.instance.getPaymentsForChild(
      widget.child.id,
    );
    final drivers = await DatabaseService.instance.getDrivers();
    if (mounted) {
      setState(() {
        _payments = payments;
        _drivers = drivers;
      });
    }
  }

  Future<void> _togglePaid(Payment payment) async {
    await DatabaseService.instance.upsertPayment(
      payment.copyWith(paid: !payment.paid),
    );
    _load();
  }

  String _driverName(String driverId) {
    final match = _drivers.where((d) => d.id == driverId);
    return match.isEmpty ? '' : match.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final currencyCode = SettingsService.instance.currencyCode;
    final dateFormat = DateFormat.yMMMd(locale);
    final bottomPadding = 24 + MediaQuery.of(context).padding.bottom;

    final totalPaid = _payments
        .where((p) => p.paid)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final totalPending = _payments
        .where((p) => !p.paid)
        .fold<double>(0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(title: Text(widget.child.name)),
      body: SafeArea(
        top: false,
        child: Column(
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
                  ? Center(child: Text(l10n.noPaymentsForChild))
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
                          title: Text(
                            '${dateFormat.format(payment.date)} · ${_driverName(payment.driverId)}',
                          ),
                          subtitle: Text(
                            formatAmount(payment.amount, currencyCode) +
                                (payment.isExtra
                                    ? ' · ${l10n.holidayLabel}'
                                    : ''),
                          ),
                          trailing: IconButton(
                            icon: Icon(payment.paid ? Icons.undo : Icons.check),
                            tooltip: payment.paid
                                ? l10n.markAsUnpaid
                                : l10n.markAsPaid,
                            onPressed: () => _togglePaid(payment),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
