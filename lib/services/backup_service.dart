import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/child.dart';
import '../models/driver.dart';
import '../models/payment.dart';
import 'database_service.dart';

/// Exports/imports the full local database (drivers, children, payments) as
/// a single JSON file, so the user can back it up or move it to a new phone.
class BackupService {
  static const int _formatVersion = 1;

  static Future<void> exportAndShare() async {
    final db = DatabaseService.instance;
    final drivers = await db.getDrivers();
    final children = await db.getChildren();
    final payments = await db.getAllPayments();

    final data = {
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'drivers': drivers.map((d) => d.toMap()).toList(),
      'children': children.map((c) => c.toMap()).toList(),
      'payments': payments.map((p) => p.toMap()).toList(),
    };

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/pagobus_backup_$timestamp.json');
    await file.writeAsString(jsonEncode(data));

    await Share.shareXFiles([XFile(file.path)], text: 'PagoBus backup');
  }

  /// Lets the user pick a previously exported JSON file and restores it,
  /// replacing all current data. Returns true if a file was picked and
  /// successfully imported.
  static Future<bool> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return false;

    final file = File(result.files.single.path!);
    final raw = await file.readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;

    final drivers = (data['drivers'] as List<dynamic>)
        .map((m) => Driver.fromMap(Map<String, Object?>.from(m as Map)))
        .toList();
    final children = (data['children'] as List<dynamic>? ?? [])
        .map((m) => Child.fromMap(Map<String, Object?>.from(m as Map)))
        .toList();
    final payments = (data['payments'] as List<dynamic>)
        .map((m) => Payment.fromMap(Map<String, Object?>.from(m as Map)))
        .toList();

    await DatabaseService.instance.replaceAllData(
      drivers: drivers,
      children: children,
      payments: payments,
    );
    return true;
  }
}
