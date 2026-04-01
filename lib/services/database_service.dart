import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  static Database? _database;
  static const String billsTable = 'bills';

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
      version: 6,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await _createInvoicesTable(db);
        await ensureBillsTable(db);
        await _createMenuItemsTable(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await ensureBillsTable(db);
        }
        if (oldVersion < 3) {
          await _createMenuItemsTable(db);
        }
        if (oldVersion < 4) {
          await _addMenuItemCategoryColumn(db);
        }
        if (oldVersion < 5) {
          await _addMenuItemSubcategoryColumn(db);
        }
      },
      onOpen: (Database db) async {
        await ensureBillsTable(db);
        await _createMenuItemsTable(db);
        await _addMenuItemCategoryColumn(db);
        await _addMenuItemSubcategoryColumn(db);
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
      CREATE TABLE IF NOT EXISTS $billsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        items TEXT NOT NULL,
        total_amount REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bills_timestamp ON $billsTable(timestamp DESC)',
    );
  }

  Future<void> ensureBillsTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [billsTable],
    );

    if (tables.isEmpty) {
      await _createBillsTable(db);
      return;
    }

    final columns = await db.rawQuery('PRAGMA table_info($billsTable)');
    final columnNames = columns
        .map((column) => (column['name'] as String?) ?? '')
        .toSet();
    final hasRequiredColumns = columnNames.contains('id') &&
        columnNames.contains('items') &&
        columnNames.contains('timestamp') &&
        columnNames.contains('total_amount');

    if (!hasRequiredColumns) {
      await _rebuildBillsTable(db, columnNames: columnNames);
      return;
    }
  }

  Future<void> _rebuildBillsTable(
    Database db, {
    required Set<String> columnNames,
  }) async {
    await db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS bills_repair');
      await txn.execute('''
        CREATE TABLE bills_repair(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          items TEXT NOT NULL,
          total_amount REAL NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');

      final hasItems = columnNames.contains('items');
      final hasTimestamp = columnNames.contains('timestamp');
      final totalExpression = columnNames.contains('total_amount')
          ? 'total_amount'
          : columnNames.contains('total')
              ? 'total'
              : '0';

      if (hasItems && hasTimestamp) {
        await txn.execute('''
          INSERT INTO bills_repair (id, items, total_amount, timestamp)
          SELECT id, items, $totalExpression, timestamp
          FROM $billsTable
        ''');
      }

      await txn.execute('DROP TABLE IF EXISTS $billsTable');
      await txn.execute('ALTER TABLE bills_repair RENAME TO $billsTable');
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_bills_timestamp ON $billsTable(timestamp DESC)',
      );
    });
  }

  Future<void> _createMenuItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS menu_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        subcategory TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_menu_items_name ON menu_items(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_menu_items_category_name ON menu_items(category, name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_menu_items_category_subcategory_name ON menu_items(category, subcategory, name)',
    );
  }

  Future<void> _addMenuItemCategoryColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(menu_items)');
    final hasCategory = columns.any(
      (column) => (column['name'] as String?) == 'category',
    );

    if (!hasCategory) {
      await db.execute(
        "ALTER TABLE menu_items ADD COLUMN category TEXT NOT NULL DEFAULT ''",
      );
    }

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_menu_items_category_name ON menu_items(category, name)',
    );
  }

  Future<void> _addMenuItemSubcategoryColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(menu_items)');
    final hasSubcategory = columns.any(
      (column) => (column['name'] as String?) == 'subcategory',
    );

    if (!hasSubcategory) {
      await db.execute(
        "ALTER TABLE menu_items ADD COLUMN subcategory TEXT NOT NULL DEFAULT ''",
      );
    }

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_menu_items_category_subcategory_name ON menu_items(category, subcategory, name)',
    );
  }
}
