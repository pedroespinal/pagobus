import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/child.dart';
import '../models/driver.dart';
import '../models/payment.dart';
import '../services/database_service.dart';
import '../services/recurring_payment_service.dart';

const _uuid = Uuid();

/// Bottom sheet to add or edit a payment for a specific [date].
/// When [isExcludedDay] is true (weekend/holiday), the entry is forced to
/// be an extraordinary/eventual service.
class AddPaymentSheet extends StatefulWidget {
  final DateTime date;
  final bool isExcludedDay;
  final List<Driver> drivers;
  final List<Child> children;
  final Payment? existing;

  const AddPaymentSheet({
    super.key,
    required this.date,
    required this.isExcludedDay,
    required this.drivers,
    this.children = const [],
    this.existing,
  });

  @override
  State<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  Driver? _selectedDriver;
  Child? _selectedChild;
  bool _paid = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _selectedDriver = widget.drivers
          .where((d) => d.id == existing.driverId)
          .cast<Driver?>()
          .firstOrNull;
      _selectedChild = widget.children
          .where((c) => c.id == existing.childId)
          .cast<Child?>()
          .firstOrNull;
      _amountController = TextEditingController(
        text: existing.amount.toStringAsFixed(2),
      );
      _noteController = TextEditingController(text: existing.note ?? '');
      _paid = existing.paid;
    } else {
      _selectedDriver = widget.drivers.firstOrNull;
      _amountController = TextEditingController(
        text: _selectedDriver == null
            ? ''
            : RecurringPaymentService.dailyRate(
                _selectedDriver!,
                widget.date,
              ).toStringAsFixed(2),
      );
      _noteController = TextEditingController();
      _selectedChild = _soleAssignedChild(_selectedDriver);
    }
  }

  /// If [driver] has exactly one assigned child, that's almost certainly who
  /// this payment is for — pre-select it so the user doesn't have to.
  Child? _soleAssignedChild(Driver? driver) {
    if (driver == null || driver.assignedChildIds.length != 1) return null;
    return widget.children
        .where((c) => driver.assignedChildIds.contains(c.id))
        .cast<Child?>()
        .firstOrNull;
  }

  /// Children selectable for [driver]: narrowed to its assigned children if
  /// it has any, otherwise every child. Always keeps the currently selected
  /// child in the list even if it falls outside that set (e.g. the driver's
  /// assignments changed after this payment was tagged), so the dropdown's
  /// value never points at a missing item.
  List<Child> _childrenForDriver(Driver? driver) {
    if (driver == null || driver.assignedChildIds.isEmpty) {
      return widget.children;
    }
    final filtered = widget.children
        .where((c) => driver.assignedChildIds.contains(c.id))
        .toList();
    final selected = _selectedChild;
    if (selected != null && !filtered.any((c) => c.id == selected.id)) {
      filtered.add(selected);
    }
    return filtered;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onDriverChanged(Driver? driver) {
    setState(() {
      _selectedDriver = driver;
      if (widget.existing == null && driver != null) {
        _amountController.text = RecurringPaymentService.dailyRate(
          driver,
          widget.date,
        ).toStringAsFixed(2);
        if (driver.assignedChildIds.isEmpty) {
          // No restriction for this driver — leave whatever was picked.
        } else if (!driver.assignedChildIds.contains(_selectedChild?.id)) {
          _selectedChild = _soleAssignedChild(driver);
        }
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedDriver == null) return;
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    final payment = Payment(
      id: widget.existing?.id ?? _uuid.v4(),
      driverId: _selectedDriver!.id,
      date: widget.date,
      amount: amount,
      paid: _paid,
      isExtra: widget.isExcludedDay || (widget.existing?.isExtra ?? false),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      childId: _selectedChild?.id,
    );
    await DatabaseService.instance.upsertPayment(payment);
    // Logging a payment for this driver/day means service was received.
    await DatabaseService.instance.setServiceRecordForDriverDate(
      _selectedDriver!.id,
      widget.date,
      received: true,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat.yMMMMd(
      Localizations.localeOf(context).languageCode,
    ).format(widget.date);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isExcludedDay ? l10n.addExtraService : l10n.addPayment,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(dateStr, style: Theme.of(context).textTheme.bodyMedium),
              if (widget.isExcludedDay) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.extraServiceHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<Driver>(
                initialValue: _selectedDriver,
                decoration: InputDecoration(labelText: l10n.driverLabel),
                items: widget.drivers
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.name)))
                    .toList(),
                onChanged: _onDriverChanged,
                validator: (v) => v == null ? l10n.requiredField : null,
              ),
              if (widget.children.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<Child?>(
                  key: ValueKey(_selectedDriver?.id),
                  initialValue: _selectedChild,
                  decoration: InputDecoration(labelText: l10n.childLabel),
                  items: [
                    DropdownMenuItem<Child?>(
                      value: null,
                      child: Text(l10n.noChildSelected),
                    ),
                    ..._childrenForDriver(_selectedDriver).map(
                      (c) => DropdownMenuItem<Child?>(
                        value: c,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (child) => setState(() => _selectedChild = child),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: l10n.amountLabel),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.requiredField;
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return l10n.invalidAmount;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: l10n.noteLabel),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_paid ? l10n.paid : l10n.unpaid),
                value: _paid,
                onChanged: (v) => setState(() => _paid = v),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: widget.drivers.isEmpty ? null : _save,
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
