import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PagoBusApp());
}

class PagoBusApp extends StatefulWidget {
  const PagoBusApp({super.key});

  @override
  State<PagoBusApp> createState() => _PagoBusAppState();
}

class _PagoBusAppState extends State<PagoBusApp> {
  final _settings = SettingsService.instance;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _settings.load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
    _settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'PagoBus',
      debugShowCheckedModeBanner: false,
      locale: _settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _settings.themeMode,
      theme: AppTheme.light(_settings.palette),
      darkTheme: AppTheme.dark(_settings.palette),
      home: const HomeScreen(),
    );
  }
}
