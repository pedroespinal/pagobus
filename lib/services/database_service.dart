import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/child.dart';
import '../models/driver.dart';
import '../models/payment.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static const int schemaVersion = 2;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pagobus.db');
    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE drivers (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            company TEXT,
            phone TEXT,
            defaultAmount REAL NOT NULL,
            defaultFrequency TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE children (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE payments (
            id TEXT PRIMARY KEY,
            driverId TEXT NOT NULL,
            date TEXT NOT NULL,
            amount REAL NOT NULL,
            paid INTEGER NOT NULL,
            isExtra INTEGER NOT NULL,
            note TEXT,
            childId TEXT,
            FOREIGN KEY (driverId) REFERENCES drivers (id) ON DELETE CASCADE,
            FOREIGN KEY (childId) REFERENCES children (id) ON DELETE SET NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_payments_date ON payments (date)');
        await db.execute(
            'CREATE INDEX idx_payments_driver ON payments (driverId)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS children (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL
            )
          ''');
          await db.execute('ALTER TABLE payments ADD COLUMN childId TEXT');
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // --- Drivers ---

  Future<List<Driver>> getDrivers() async {
    final db = await database;
    final rows = await db.query('drivers', orderBy: 'name COLLATE NOCASE');
    return rows.map(Driver.fromMap).toList();
  }

  Future<void> upsertDriver(Driver driver) async {
    final db = await database;
    await db.insert(
      'drivers',
      driver.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDriver(String driverId) async {
    final db = await database;
    await db.delete('payments', where: 'driverId = ?', whereArgs: [driverId]);
    await db.delete('drivers', where: 'id = ?', whereArgs: [driverId]);
  }

  // --- Children ---

  Future<List<Child>> getChildren() async {
    final db = await database;
    final rows = await db.query('children', orderBy: 'name COLLATE NOCASE');
    return rows.map(Child.fromMap).toList();
  }

  Future<void> upsertChild(Child child) async {
    final db = await database;
    await db.insert(
      'children',
      child.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteChild(String childId) async {
    final db = await database;
    await db.delete('children', where: 'id = ?', whereArgs: [childId]);
  }

  // --- Payments ---

  Future<List<Payment>> getPaymentsForDriver(String driverId) async {
    final db = await database;
    final rows = await db.query(
      'payments',
      where: 'driverId = ?',
      whereArgs: [driverId],
      orderBy: 'date DESC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> getPaymentsForDate(DateTime date) async {
    final db = await database;
    final rows = await db.query(
      'payments',
      where: 'date = ?',
      whereArgs: [Payment.dateKey(date)],
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> getPaymentsInRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final rows = await db.query(
      'payments',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [Payment.dateKey(start), Payment.dateKey(end)],
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final rows = await db.query('payments', orderBy: 'date DESC');
    return rows.map(Payment.fromMap).toList();
  }

  Future<void> upsertPayment(Payment payment) async {
    final db = await database;
    await db.insert(
      'payments',
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePayment(String paymentId) async {
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
  }

  /// Wipes all app data and replaces it with the given drivers/children/payments.
  /// Used by data import/restore.
  Future<void> replaceAllData({
    required List<Driver> drivers,
    required List<Child> children,
    required List<Payment> payments,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('children');
      await txn.delete('drivers');
      for (final driver in drivers) {
        await txn.insert('drivers', driver.toMap());
      }
      for (final child in children) {
        await txn.insert('children', child.toMap());
      }
      for (final payment in payments) {
        await txn.insert('payments', payment.toMap());
      }
    });
  }
}
