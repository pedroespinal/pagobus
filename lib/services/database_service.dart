import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/driver.dart';
import '../models/payment.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

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
      version: 1,
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
          CREATE TABLE payments (
            id TEXT PRIMARY KEY,
            driverId TEXT NOT NULL,
            date TEXT NOT NULL,
            amount REAL NOT NULL,
            paid INTEGER NOT NULL,
            isExtra INTEGER NOT NULL,
            note TEXT,
            FOREIGN KEY (driverId) REFERENCES drivers (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX idx_payments_date ON payments (date)');
        await db.execute(
            'CREATE INDEX idx_payments_driver ON payments (driverId)');
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
}
