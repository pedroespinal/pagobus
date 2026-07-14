import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/child.dart';
import '../services/app_origin.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../services/holiday_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/pin_dialog.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService.instance;
  String _version = '';
  List<Map<String, String>> _customHolidays = [];
  List<Child> _children = [];
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadHolidays();
    _loadChildren();
    _loadSecurity();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  Future<void> _loadHolidays() async {
    final holidays = await HolidayService.instance.getCustomHolidays();
    if (mounted) setState(() => _customHolidays = holidays);
  }

  Future<void> _loadChildren() async {
    final children = await DatabaseService.instance.getChildren();
    if (mounted) setState(() => _children = children);
  }

  Future<void> _loadSecurity() async {
    final hasPin = await AuthService.instance.hasPin();
    final biometricEnabled = await AuthService.instance.isBiometricEnabled();
    final biometricAvailable = await AuthService.instance
        .isBiometricAvailable();
    if (mounted) {
      setState(() {
        _pinEnabled = hasPin;
        _biometricEnabled = biometricEnabled;
        _biometricAvailable = biometricAvailable;
      });
    }
  }

  Future<void> _addHoliday() async {
    final l10n = AppLocalizations.of(context)!;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addHoliday),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.nameLabel),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (label == null || label.isEmpty) return;
    await HolidayService.instance.addCustomHoliday(date, label);
    _loadHolidays();
  }

  Future<void> _removeHoliday(String dateKey) async {
    await HolidayService.instance.removeCustomHoliday(dateKey);
    _loadHolidays();
  }

  Future<void> _addChild() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addChild),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.nameLabel),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await DatabaseService.instance.upsertChild(
      Child(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name),
    );
    _loadChildren();
  }

  Future<void> _removeChild(Child child) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteChild),
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
      await DatabaseService.instance.deleteChild(child.id);
      _loadChildren();
    }
  }

  Future<void> _togglePinLock(bool enable) async {
    if (enable) {
      final pin = await promptSetNewPin(context);
      if (pin == null || !mounted) return;
      await AuthService.instance.setPin(pin);
      setState(() => _pinEnabled = true);
    } else {
      final verified = await promptVerifyPin(context);
      if (!verified || !mounted) return;
      await AuthService.instance.removePin();
      setState(() {
        _pinEnabled = false;
        _biometricEnabled = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    await AuthService.instance.setBiometricEnabled(enable);
    setState(() => _biometricEnabled = enable);
  }

  Future<void> _toggleReminder(bool enable) async {
    final l10n = AppLocalizations.of(context)!;
    if (enable) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) return;
      await _settings.setReminderEnabled(true);
      await NotificationService.instance.scheduleDailyReminder(
        time: _settings.reminderTime,
        title: l10n.reminderNotificationTitle,
        body: l10n.reminderNotificationBody,
      );
    } else {
      await _settings.setReminderEnabled(false);
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  Future<void> _pickReminderTime() async {
    final l10n = AppLocalizations.of(context)!;
    final time = await showTimePicker(
      context: context,
      initialTime: _settings.reminderTime,
    );
    if (time == null) return;
    await _settings.setReminderTime(time);
    if (_settings.reminderEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        time: time,
        title: l10n.reminderNotificationTitle,
        body: l10n.reminderNotificationBody,
      );
    }
  }

  Future<void> _exportData() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await BackupService.exportAndShare();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.exportSuccess)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importData() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importConfirmTitle),
        content: Text(l10n.importConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.importData),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      final imported = await BackupService.pickAndImport();
      if (!mounted) return;
      if (imported) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.importSuccess)));
        _loadChildren();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.importError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkForUpdates() async {
    final l10n = AppLocalizations.of(context)!;
    final info = await UpdateService.instance.checkForUpdate();
    if (!mounted) return;
    if (info == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.upToDate)));
    } else {
      await showUpdateDialog(context, info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsTitle)),
          body: AbsorbPointer(
            absorbing: _busy,
            child: Stack(
              children: [
                ListView(
                  children: [
                    ListTile(
                      title: Text(l10n.languageLabel),
                      trailing: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'es',
                            label: Text(l10n.languageSpanish),
                          ),
                          ButtonSegment(
                            value: 'en',
                            label: Text(l10n.languageEnglish),
                          ),
                        ],
                        selected: {locale},
                        onSelectionChanged: (selection) {
                          _settings.setLocale(Locale(selection.first));
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(title: Text(l10n.themeLabel)),
                    RadioListTile<ThemeMode>(
                      title: Text(l10n.themeLight),
                      value: ThemeMode.light,
                      groupValue: _settings.themeMode,
                      onChanged: (v) => _settings.setThemeMode(v!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(l10n.themeDark),
                      value: ThemeMode.dark,
                      groupValue: _settings.themeMode,
                      onChanged: (v) => _settings.setThemeMode(v!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(l10n.themeSystem),
                      value: ThemeMode.system,
                      groupValue: _settings.themeMode,
                      onChanged: (v) => _settings.setThemeMode(v!),
                    ),
                    const Divider(),
                    ListTile(title: Text(l10n.paletteLabel)),
                    RadioListTile<AppPalette>(
                      title: Text(l10n.paletteBusClassic),
                      value: AppPalette.busClassic,
                      groupValue: _settings.palette,
                      onChanged: (v) => _settings.setPalette(v!),
                    ),
                    RadioListTile<AppPalette>(
                      title: Text(l10n.paletteBlueTrust),
                      value: AppPalette.blueTrust,
                      groupValue: _settings.palette,
                      onChanged: (v) => _settings.setPalette(v!),
                    ),
                    RadioListTile<AppPalette>(
                      title: Text(l10n.paletteGreenSafe),
                      value: AppPalette.greenSafe,
                      groupValue: _settings.palette,
                      onChanged: (v) => _settings.setPalette(v!),
                    ),
                    RadioListTile<AppPalette>(
                      title: Text(l10n.palettePurpleModern),
                      value: AppPalette.purpleModern,
                      groupValue: _settings.palette,
                      onChanged: (v) => _settings.setPalette(v!),
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(l10n.currencyLabel),
                      trailing: DropdownButton<String>(
                        value: _settings.currencyCode,
                        items: currencySymbols.keys
                            .map(
                              (code) => DropdownMenuItem(
                                value: code,
                                child: Text('$code (${currencySymbols[code]})'),
                              ),
                            )
                            .toList(),
                        onChanged: (code) {
                          if (code != null) _settings.setCurrencyCode(code);
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(l10n.holidaysLabel),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addHoliday,
                      ),
                    ),
                    ..._customHolidays.map((h) {
                      final date = DateTime.parse(h['date']!);
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.event_busy),
                        title: Text(h['label'] ?? ''),
                        subtitle: Text(DateFormat.yMMMd(locale).format(date)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeHoliday(h['date']!),
                        ),
                      );
                    }),
                    const Divider(),
                    ListTile(
                      title: Text(l10n.childrenLabel),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addChild,
                      ),
                    ),
                    ..._children.map(
                      (child) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.face_outlined),
                        title: Text(child.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeChild(child),
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(title: Text(l10n.securityLabel)),
                    SwitchListTile(
                      title: Text(l10n.pinLockLabel),
                      value: _pinEnabled,
                      onChanged: _togglePinLock,
                    ),
                    if (_pinEnabled && _biometricAvailable)
                      SwitchListTile(
                        title: Text(l10n.biometricLabel),
                        value: _biometricEnabled,
                        onChanged: _toggleBiometric,
                      ),
                    const Divider(),
                    ListTile(title: Text(l10n.reminderLabel)),
                    SwitchListTile(
                      title: Text(l10n.reminderLabel),
                      value: _settings.reminderEnabled,
                      onChanged: _toggleReminder,
                    ),
                    if (_settings.reminderEnabled)
                      ListTile(
                        title: Text(l10n.reminderTimeLabel),
                        subtitle: Text(_settings.reminderTime.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: _pickReminderTime,
                      ),
                    const Divider(),
                    ListTile(title: Text(l10n.backupLabel)),
                    ListTile(
                      leading: const Icon(Icons.upload_outlined),
                      title: Text(l10n.exportData),
                      onTap: _exportData,
                    ),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: Text(l10n.importData),
                      onTap: _importData,
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(l10n.checkForUpdates),
                      leading: const Icon(Icons.system_update_alt),
                      onTap: _checkForUpdates,
                    ),
                    ListTile(
                      title: Text(l10n.versionLabel),
                      subtitle: Text('PagoBus $_version'),
                      leading: const Icon(Icons.info_outline),
                    ),
                    ListTile(
                      title: Text(l10n.appCreatedLabel),
                      subtitle: Text(
                        '${DateFormat.yMMMMd(locale).add_Hm().format(AppOrigin.createdAtUtc)} UTC',
                      ),
                      leading: const Icon(Icons.verified_outlined),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        l10n.footerCredit,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 16 + MediaQuery.of(context).padding.bottom,
                    ),
                  ],
                ),
                if (_busy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x22000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
