import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/driver.dart';
import '../services/database_service.dart';
import 'driver_detail_screen.dart';
import 'driver_form_sheet.dart';

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key});

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  List<Driver> _drivers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final drivers = await DatabaseService.instance.getDrivers();
    if (mounted) setState(() => _drivers = drivers);
  }

  Future<void> _openForm({Driver? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DriverFormSheet(existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _confirmDelete(Driver driver) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteDriver),
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
      await DatabaseService.instance.deleteDriver(driver.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.driversTitle)),
      body: _drivers.isEmpty
          ? Center(child: Text(l10n.noDrivers))
          : ListView.builder(
              itemCount: _drivers.length,
              itemBuilder: (context, index) {
                final driver = _drivers[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.directions_bus),
                  ),
                  title: Text(driver.name),
                  subtitle: Text(driver.company ?? ''),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DriverDetailScreen(driver: driver),
                      ),
                    );
                    _load();
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openForm(existing: driver),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(driver),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text(l10n.addDriver),
      ),
    );
  }
}
