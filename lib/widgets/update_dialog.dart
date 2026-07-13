import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/update_service.dart';

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
  final l10n = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.directions_bus_filled, size: 36),
      title: Text(l10n.updateAvailableTitle),
      content: Text(l10n.updateAvailableBody(info.version)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.updateLater),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final uri = Uri.parse(info.downloadUrl);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          child: Text(l10n.updateNow),
        ),
      ],
    ),
  );
}
