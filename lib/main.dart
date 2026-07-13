import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.instance.init();
  runApp(const PagoBusApp());
}

class PagoBusApp extends StatefulWidget {
  const PagoBusApp({super.key});

  @override
  State<PagoBusApp> createState() => _PagoBusAppState();
}

class _PagoBusAppState extends State<PagoBusApp> with WidgetsBindingObserver {
  final _settings = SettingsService.instance;
  bool _loaded = false;
  bool _hasPin = false;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
    _settings.addListener(_onSettingsChanged);
  }

  Future<void> _bootstrap() async {
    await _settings.load();
    final hasPin = await AuthService.instance.hasPin();
    if (mounted) {
      setState(() {
        _hasPin = hasPin;
        _locked = hasPin;
        _loaded = true;
      });
    }
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _hasPin) {
      _locked = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      home: _locked
          ? LockScreen(onUnlocked: () => setState(() => _locked = false))
          : const HomeScreen(),
    );
  }
}
