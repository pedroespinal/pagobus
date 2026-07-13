import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/app_origin.dart';
import '../services/holiday_service.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadHolidays();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  Future<void> _loadHolidays() async {
    final holidays = await HolidayService.instance.getCustomHolidays();
    if (mounted) setState(() => _customHolidays = holidays);
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

  Future<void> _checkForUpdates() async {
    final l10n = AppLocalizations.of(context)!;
    final info = await UpdateService.instance.checkForUpdate();
    if (!mounted) return;
    if (info == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.upToDate)));
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
          body: ListView(
            children: [
              ListTile(
                title: Text(l10n.languageLabel),
                trailing: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'es', label: Text(l10n.languageSpanish)),
                    ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.footerCredit,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
