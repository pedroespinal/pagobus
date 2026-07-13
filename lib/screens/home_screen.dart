import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'calendar_screen.dart';
import 'driver_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService.instance.checkForUpdate();
    if (info != null && mounted) {
      await showUpdateDialog(context, info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screens = [
      const CalendarScreen(),
      const DriverListScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      // Rebuilt (not IndexedStack) on purpose: each tab reloads its data
      // fresh from the database every time it becomes visible, so adding a
      // driver in the Drivers tab is immediately reflected in the Calendar.
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.directions_bus_outlined),
            selectedIcon: const Icon(Icons.directions_bus),
            label: l10n.navDrivers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
