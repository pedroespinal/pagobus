import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

/// Prompts the user to create a new PIN (entered twice to confirm).
/// Returns the new PIN, or null if cancelled / it didn't match.
Future<String?> promptSetNewPin(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final pinController = TextEditingController();
  final confirmController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.setPinTitle),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              decoration: InputDecoration(labelText: l10n.pinLabel),
              validator: (v) =>
                  (v == null || v.length < 4) ? l10n.pinTooShort : null,
            ),
            TextFormField(
              controller: confirmController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              decoration: InputDecoration(labelText: l10n.confirmPinLabel),
              validator: (v) => v != pinController.text
                  ? l10n.pinMismatch
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(pinController.text);
            }
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  return result;
}

/// Prompts the user to enter their existing PIN to confirm a sensitive
/// action (like disabling the lock). Returns true if it matched.
Future<bool> promptVerifyPin(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  String? error;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.enterPinTitle),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          decoration: InputDecoration(
            labelText: l10n.pinLabel,
            errorText: error,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await AuthService.instance.verifyPin(controller.text);
              if (!context.mounted) return;
              if (ok) {
                Navigator.of(context).pop(true);
              } else {
                setState(() => error = l10n.wrongPin);
              }
            },
            child: Text(l10n.unlock),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
