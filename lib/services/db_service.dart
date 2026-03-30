import 'dart:convert';

import 'database_service.dart';

class BillRecord {
  const BillRecord({
    this.id,
    required this.items,
    required this.totalAmount,
    required this.timestamp,
  });

  final int? id;
  final List<Map<String, Object?>> items;
  final double totalAmount;
  final DateTime timestamp;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'items': jsonEncode(items),
      'total_amount': totalAmount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BillRecord.fromMap(Map<String, Object?> map) {
    final decodedItems = jsonDecode(map['items'] as String? ?? '[]');

    return BillRecord(
      id: map['id'] as int?,
      items: (decodedItems as List<dynamic>)
          .map(
            (item) => Map<String, Object?>.from(
              item as Map,
            ),
          )
          .toList(growable: false),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class DailyBillSummary {
  const DailyBillSummary({
    required this.totalSales,
    required this.billCount,
  });

  final double totalSales;
  final int billCount;
}

class MenuItemRecord {
  const MenuItemRecord({
    this.id,
    required this.name,
    required this.price,
    this.category = '',
    this.subcategory = '',
  });

  final int? id;
  final String name;
  final double price;
  final String category;
  final String subcategory;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'subcategory': subcategory,
    };
  }

  factory MenuItemRecord.fromMap(Map<String, Object?> map) {
    return MenuItemRecord(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      category: map['category'] as String? ?? '',
      subcategory: map['subcategory'] as String? ?? '',
    );
  }
}

class DbService {
  DbService._();

  static final DbService instance = DbService._();
  static const int _businessDayStartHour = 6;

  Future<int> saveBill({
    required List<Map<String, Object?>> items,
    required double totalAmount,
    DateTime? timestamp,
  }) async {
    final db = await DatabaseService.instance.database;

    return db.insert(
      'bills',
      BillRecord(
        items: items,
        totalAmount: totalAmount,
        timestamp: timestamp ?? DateTime.now(),
      ).toMap(),
    );
  }

  Future<List<BillRecord>> fetchBills() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'bills',
      orderBy: 'timestamp DESC',
    );

    return rows.map(BillRecord.fromMap).toList(growable: false);
  }

  Future<DailyBillSummary> fetchTodaySummary({DateTime? now}) async {
    final db = await DatabaseService.instance.database;
    final currentTime = now ?? DateTime.now();
    var businessDayDate = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );

    if (currentTime.hour < _businessDayStartHour) {
      businessDayDate = businessDayDate.subtract(const Duration(days: 1));
    }

    final startOfBusinessDay = DateTime(
      businessDayDate.year,
      businessDayDate.month,
      businessDayDate.day,
      _businessDayStartHour,
    );
    final startOfNextBusinessDay = startOfBusinessDay.add(const Duration(days: 1));

    final rows = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS bill_count,
        COALESCE(SUM(total_amount), 0) AS total_sales
      FROM bills
      WHERE timestamp >= ? AND timestamp < ?
      ''',
      [
        startOfBusinessDay.toIso8601String(),
        startOfNextBusinessDay.toIso8601String(),
      ],
    );

    final summaryRow = rows.first;

    return DailyBillSummary(
      totalSales: (summaryRow['total_sales'] as num?)?.toDouble() ?? 0,
      billCount: (summaryRow['bill_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<BillRecord?> fetchBillById(int id) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return BillRecord.fromMap(rows.first);
  }

  Future<List<MenuItemRecord>> getAllMenuItems() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'menu_items',
      orderBy:
          'category COLLATE NOCASE ASC, subcategory COLLATE NOCASE ASC, name COLLATE NOCASE ASC',
    );

    return rows.map(MenuItemRecord.fromMap).toList(growable: false);
  }

  Future<int> addMenuItem({
    required String name,
    required double price,
    String category = '',
    String subcategory = '',
  }) async {
    final db = await DatabaseService.instance.database;

    return db.insert(
      'menu_items',
      MenuItemRecord(
        name: name,
        price: price,
        category: category,
        subcategory: subcategory,
      ).toMap(),
    );
  }

  Future<List<MenuItemRecord>> fetchMenuItemsByCategory(String category) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'menu_items',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'subcategory COLLATE NOCASE ASC, name COLLATE NOCASE ASC',
    );

    return rows.map(MenuItemRecord.fromMap).toList(growable: false);
  }

  Future<Map<String, List<MenuItemRecord>>> groupMenuItemsByCategory() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'menu_items',
      orderBy:
          'category COLLATE NOCASE ASC, subcategory COLLATE NOCASE ASC, name COLLATE NOCASE ASC',
    );

    final groupedItems = <String, List<MenuItemRecord>>{};

    for (final row in rows) {
      final item = MenuItemRecord.fromMap(row);
      groupedItems.putIfAbsent(item.category, () => <MenuItemRecord>[]).add(item);
    }

    return groupedItems;
  }

  Future<void> deleteMenuItem(int id) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'menu_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteBill(int id) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
