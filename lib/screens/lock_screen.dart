import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinController = TextEditingController();
  String? _error;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final biometricEnabled = await AuthService.instance.isBiometricEnabled();
    final biometricAvailable = await AuthService.instance.isBiometricAvailable();
    if (mounted) {
      setState(() => _biometricAvailable = biometricEnabled && biometricAvailable);
    }
    if (_biometricAvailable) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await AuthService.instance.authenticateWithBiometrics(l10n.unlockPagoBus);
    if (ok && mounted) widget.onUnlocked();
  }

  Future<void> _submitPin() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await AuthService.instance.verifyPin(_pinController.text);
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = l10n.wrongPin;
        _pinController.clear();
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bus_filled,
                    size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(l10n.unlockPagoBus,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  autofocus: !_biometricAvailable,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: l10n.pinLabel,
                    errorText: _error,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _submitPin(),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _submitPin,
                  child: Text(l10n.unlock),
                ),
                if (_biometricAvailable) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(l10n.useBiometric),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
