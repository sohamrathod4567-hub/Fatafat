import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = p.join(databasesPath, 'billing_app.db');

    return openDatabase(
      path,
      version: 2,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await _createInvoicesTable(db);
        await _createBillsTable(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await _createBillsTable(db);
        }
      },
      onOpen: (Database db) async {
        await _createBillsTable(db);
      },
    );
  }

  Future<void> _createInvoicesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_invoices_created_at ON invoices(created_at DESC)',
    );
  }

  Future<void> _createBillsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bills(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        items TEXT NOT NULL,
        total_amount REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bills_timestamp ON bills(timestamp DESC)',
    );
  }
}
