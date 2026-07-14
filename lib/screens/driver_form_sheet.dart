import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/driver.dart';
import '../services/database_service.dart';
import '../widgets/weekday_selector.dart';

const _uuid = Uuid();

class DriverFormSheet extends StatefulWidget {
  final Driver? existing;

  const DriverFormSheet({super.key, this.existing});

  @override
  State<DriverFormSheet> createState() => _DriverFormSheetState();
}

class _DriverFormSheetState extends State<DriverFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _phoneController;
  late final TextEditingController _amountController;
  late PaymentFrequency _frequency;
  late Set<int> _serviceWeekdays;
  bool _showWeekdayError = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _companyController = TextEditingController(text: existing?.company ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _amountController = TextEditingController(
      text: existing?.defaultAmount.toStringAsFixed(2) ?? '',
    );
    _frequency = existing?.defaultFrequency ?? PaymentFrequency.daily;
    _serviceWeekdays = Set<int>.from(
      existing?.serviceWeekdays ?? defaultServiceWeekdays,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState!.validate();
    final weekdaysValid = _serviceWeekdays.isNotEmpty;
    setState(() => _showWeekdayError = !weekdaysValid);
    if (!formValid || !weekdaysValid) return;

    final driver = Driver(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      company: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      defaultAmount: double.parse(_amountController.text.replaceAll(',', '.')),
      defaultFrequency: _frequency,
      serviceWeekdays: _serviceWeekdays,
    );
    await DatabaseService.instance.upsertDriver(driver);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                widget.existing == null ? l10n.addDriver : l10n.editDriver,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.nameLabel),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(labelText: l10n.companyLabel),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.phoneLabel),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: l10n.defaultAmountLabel),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.requiredField;
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return l10n.invalidAmount;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentFrequency>(
                initialValue: _frequency,
                decoration: InputDecoration(
                  labelText: l10n.defaultFrequencyLabel,
                ),
                items: [
                  DropdownMenuItem(
                    value: PaymentFrequency.daily,
                    child: Text(l10n.frequencyDaily),
                  ),
                  DropdownMenuItem(
                    value: PaymentFrequency.weekly,
                    child: Text(l10n.frequencyWeekly),
                  ),
                  DropdownMenuItem(
                    value: PaymentFrequency.monthly,
                    child: Text(l10n.frequencyMonthly),
                  ),
                ],
                onChanged: (v) => setState(() => _frequency = v ?? _frequency),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.serviceWeekdaysLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.serviceWeekdaysHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              WeekdaySelector(
                selected: _serviceWeekdays,
                onChanged: (days) => setState(() {
                  _serviceWeekdays = days;
                  _showWeekdayError = false;
                }),
              ),
              if (_showWeekdayError)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.selectAtLeastOneDay,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _save, child: Text(l10n.save)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
