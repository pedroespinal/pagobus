import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Row of toggleable chips for Monday(1)..Sunday(7), matching DateTime's
/// weekday numbering, so the user can pick which days a driver normally
/// provides service.
class WeekdaySelector extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  const WeekdaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      DateTime.monday: l10n.weekdayMonShort,
      DateTime.tuesday: l10n.weekdayTueShort,
      DateTime.wednesday: l10n.weekdayWedShort,
      DateTime.thursday: l10n.weekdayThuShort,
      DateTime.friday: l10n.weekdayFriShort,
      DateTime.saturday: l10n.weekdaySatShort,
      DateTime.sunday: l10n.weekdaySunShort,
    };
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      children: labels.entries.map((entry) {
        final isSelected = selected.contains(entry.key);
        return ChoiceChip(
          label: Text(entry.value),
          selected: isSelected,
          selectedColor: scheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? scheme.onPrimary : scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          onSelected: (value) {
            final next = Set<int>.from(selected);
            if (value) {
              next.add(entry.key);
            } else {
              next.remove(entry.key);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}
