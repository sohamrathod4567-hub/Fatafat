import 'dart:convert';

import 'package:flutter/foundation.dart';

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

  Map<String, Object?> toInsertMap() {
    return <String, Object?>{
      'items': jsonEncode(items),
      'total_amount': totalAmount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BillRecord.fromMap(Map<String, Object?> map) {
    final rawItems = map['items'] as String? ?? '[]';
    late final List<Map<String, Object?>> parsedItems;

    try {
      final decodedItems = jsonDecode(rawItems);
      if (decodedItems is List) {
        parsedItems = decodedItems
            .whereType<Map>()
            .map((item) => Map<String, Object?>.from(item))
            .toList(growable: false);
      } else {
        parsedItems = const <Map<String, Object?>>[];
      }
    } catch (_) {
      parsedItems = const <Map<String, Object?>>[];
    }

    return BillRecord(
      id: map['id'] as int?,
      items: parsedItems,
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

class BestSellingItemSummary {
  const BestSellingItemSummary({
    required this.name,
    required this.quantitySold,
  });

  final String name;
  final int quantitySold;
}

class RecentBillSummary {
  const RecentBillSummary({
    required this.id,
    required this.totalAmount,
    required this.itemCount,
    required this.timestamp,
  });

  final int id;
  final double totalAmount;
  final int itemCount;
  final DateTime timestamp;
}

class DailyInsightsSummary {
  const DailyInsightsSummary({
    required this.totalSales,
    required this.billCount,
    required this.yesterdayTotalSales,
    required this.bestSellingItem,
    required this.peakTimeLabel,
    required this.recentBills,
  });

  final double totalSales;
  final int billCount;
  final double yesterdayTotalSales;
  final BestSellingItemSummary? bestSellingItem;
  final String peakTimeLabel;
  final List<RecentBillSummary> recentBills;
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
  static const Map<String, double> _knownMenuPriceByName = <String, double>{
    'margherita': 190,
    'veg cheese pizza': 220,
    'italian pizza': 230,
    'paneer pizza': 240,
    'barbecue pizza': 250,
    'exotic pizza': 280,
    'arrabiata pasta': 250,
    'alfredo pasta': 270,
    'pesto pasta': 290,
    'pink sauce pasta': 300,
    'korean garlic rice': 240,
    'mexican rice': 280,
    'pesto rice': 290,
    'burnt garlic rice': 300,
    'peri peri cottage cheese rice': 340,
    'lazeez rice': 350,
    'special zesto rice': 370,
    'regular burger': 140,
    'veg cheese burger': 190,
    'vegetable sandwich': 100,
    'vegetable cheese sandwich': 120,
    'open toast': 120,
    'masala cheese toast': 130,
    'barbeque tosties': 120,
    'chilly garlic toast': 130,
    'chilly cheese toast': 140,
    'garlic bread': 100,
    'cheese garlic bread': 150,
    'cheese chilly garlic bread': 160,
    'bruschetta': 160,
    'paneer tikka bruschetta': 180,
    'mexican paneer': 270,
    'pesto paneer': 280,
    'burnt garlic paneer': 280,
    'peri peri paneer': 300,
    'cheese nachos': 200,
    'mexican nachos': 240,
    'loaded nachos': 260,
    'mexican soup': 120,
    'cream of veg': 150,
    'tea': 20,
    'hot chocolate': 40,
    'coffee': 100,
    'oreo shake': 100,
    'cold chocolate': 100,
    'cold coffee': 110,
    'french vanilla': 110,
    'caramel coffee': 110,
  };

  Future<int> saveBill({
    required List<Map<String, Object?>> items,
    required double totalAmount,
    DateTime? timestamp,
  }) async {
    return insertBill(
      items: items,
      totalAmount: totalAmount,
      timestamp: timestamp,
    );
  }

  Future<int> insertBill({
    required List<Map<String, Object?>> items,
    required double totalAmount,
    DateTime? timestamp,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Cannot save an empty bill.');
    }

    final db = await DatabaseService.instance.database;
    await DatabaseService.instance.ensureBillsTable(db);
    final billRecord = BillRecord(
      items: items,
      totalAmount: totalAmount,
      timestamp: timestamp ?? DateTime.now(),
    );
    final insertedId = await db.insert(
      'bills',
      billRecord.toInsertMap(),
    );

    debugPrint(
      'Bill saved: id=$insertedId total=${billRecord.totalAmount} items=${billRecord.items.length} timestamp=${billRecord.timestamp.toIso8601String()}',
    );

    return insertedId;
  }

  Future<List<BillRecord>> fetchBills({int? limit}) async {
    return getAllBills(limit: limit);
  }

  Future<List<BillRecord>> getAllBills({int? limit}) async {
    final db = await DatabaseService.instance.database;
    await DatabaseService.instance.ensureBillsTable(db);
    final rows = await db.query(
      'bills',
      columns: ['id', 'items', 'total_amount', 'timestamp'],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    final bills = rows.map(BillRecord.fromMap).toList(growable: false);
    debugPrint('Bills fetched: count=${bills.length}');
    return bills;
  }

  Future<List<BillRecord>> getTodayBills({DateTime? now}) async {
    final bills =
        await _fetchBillsInRange(_businessDayRange(now ?? DateTime.now()));
    debugPrint('Today bills fetched: count=${bills.length}');
    return bills;
  }

  Future<DailyBillSummary> fetchTodaySummary({DateTime? now}) async {
    final todayBills = await getTodayBills(now: now);

    return DailyBillSummary(
      totalSales: todayBills.fold<double>(
        0,
        (sum, bill) => sum + bill.totalAmount,
      ),
      billCount: todayBills.length,
    );
  }

  Future<DailyInsightsSummary> fetchDailyInsights({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final todayRange = _businessDayRange(currentTime);
    final yesterdayRange = _BusinessDayRange(
      start: todayRange.start.subtract(const Duration(days: 1)),
      end: todayRange.start,
    );

    final todayBills = await getTodayBills(now: currentTime);
    final yesterdayTotalSales = await _fetchTotalSalesInRange(yesterdayRange);
    final bestSellingItem = _calculateBestSellingItem(todayBills);
    final peakTimeLabel = _calculatePeakTimeLabel(todayBills);

    return DailyInsightsSummary(
      totalSales: todayBills.fold<double>(
        0,
        (sum, bill) => sum + bill.totalAmount,
      ),
      billCount: todayBills.length,
      yesterdayTotalSales: yesterdayTotalSales,
      bestSellingItem: bestSellingItem,
      peakTimeLabel: peakTimeLabel,
      recentBills: todayBills
          .take(5)
          .where((bill) => bill.id != null)
          .map(
            (bill) => RecentBillSummary(
              id: bill.id!,
              totalAmount: bill.totalAmount,
              itemCount: bill.items.fold<int>(
                0,
                (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
              ),
              timestamp: bill.timestamp,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<BillRecord?> fetchBillById(int id) async {
    final db = await DatabaseService.instance.database;
    await DatabaseService.instance.ensureBillsTable(db);
    final rows = await db.query(
      'bills',
      columns: ['id', 'items', 'total_amount', 'timestamp'],
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
    await _applyKnownMenuPriceCorrections(db);
    final rows = await db.query(
      'menu_items',
      orderBy:
          'category COLLATE NOCASE ASC, subcategory COLLATE NOCASE ASC, name COLLATE NOCASE ASC',
    );

    return rows.map(MenuItemRecord.fromMap).toList(growable: false);
  }

  Future<List<MenuItemRecord>> getAllMenuItemsSortedBySales() async {
    final items = await getAllMenuItems();
    final soldQuantitiesByName = await _fetchSoldQuantitiesByItemName();
    final rankedItems = items.toList();

    rankedItems.sort((first, second) {
      final firstSoldCount = soldQuantitiesByName[first.name.trim()] ?? 0;
      final secondSoldCount = soldQuantitiesByName[second.name.trim()] ?? 0;
      final soldCountComparison = secondSoldCount.compareTo(firstSoldCount);
      if (soldCountComparison != 0) {
        return soldCountComparison;
      }

      final categoryComparison = first.category.toLowerCase().compareTo(
            second.category.toLowerCase(),
          );
      if (categoryComparison != 0) {
        return categoryComparison;
      }

      final subcategoryComparison = first.subcategory.toLowerCase().compareTo(
            second.subcategory.toLowerCase(),
          );
      if (subcategoryComparison != 0) {
        return subcategoryComparison;
      }

      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    return rankedItems;
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
      groupedItems
          .putIfAbsent(item.category, () => <MenuItemRecord>[])
          .add(item);
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

  Future<List<BillRecord>> _fetchBillsInRange(_BusinessDayRange range) async {
    final db = await DatabaseService.instance.database;
    await DatabaseService.instance.ensureBillsTable(db);
    final rows = await db.query(
      'bills',
      columns: ['id', 'items', 'total_amount', 'timestamp'],
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        range.start.toIso8601String(),
        range.end.toIso8601String(),
      ],
      orderBy: 'timestamp DESC',
    );

    return rows.map(BillRecord.fromMap).toList(growable: false);
  }

  Future<double> _fetchTotalSalesInRange(_BusinessDayRange range) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS total_sales
      FROM bills
      WHERE timestamp >= ? AND timestamp < ?
      ''',
      [
        range.start.toIso8601String(),
        range.end.toIso8601String(),
      ],
    );

    return (rows.first['total_sales'] as num?)?.toDouble() ?? 0;
  }

  _BusinessDayRange _businessDayRange(DateTime currentTime) {
    var businessDayDate = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );

    if (currentTime.hour < _businessDayStartHour) {
      businessDayDate = businessDayDate.subtract(const Duration(days: 1));
    }

    final start = DateTime(
      businessDayDate.year,
      businessDayDate.month,
      businessDayDate.day,
      _businessDayStartHour,
    );

    return _BusinessDayRange(
      start: start,
      end: start.add(const Duration(days: 1)),
    );
  }

  BestSellingItemSummary? _calculateBestSellingItem(List<BillRecord> bills) {
    final quantitiesByName = _sumItemQuantitiesByName(bills);

    if (quantitiesByName.isEmpty) {
      return null;
    }

    var bestName = '';
    var bestQuantity = -1;
    for (final entry in quantitiesByName.entries) {
      if (entry.value > bestQuantity) {
        bestName = entry.key;
        bestQuantity = entry.value;
      }
    }

    return BestSellingItemSummary(
      name: bestName,
      quantitySold: bestQuantity,
    );
  }

  String _calculatePeakTimeLabel(List<BillRecord> bills) {
    if (bills.isEmpty) {
      return 'No rush yet';
    }

    final hourlyCounts = List<int>.filled(24, 0);
    for (final bill in bills) {
      hourlyCounts[bill.timestamp.toLocal().hour]++;
    }

    var bestStartHour = _businessDayStartHour;
    var bestCount = -1;

    for (var hour = 0; hour < 24; hour++) {
      final windowCount = hourlyCounts[hour] + hourlyCounts[(hour + 1) % 24];
      if (windowCount > bestCount) {
        bestCount = windowCount;
        bestStartHour = hour;
      }
    }

    final endHour = (bestStartHour + 2) % 24;
    return '${_formatHour(bestStartHour)}-${_formatHour(endHour)}';
  }

  String _formatHour(int hour) {
    final normalizedHour = hour % 24;
    final hour12 = normalizedHour % 12 == 0 ? 12 : normalizedHour % 12;
    final suffix = normalizedHour >= 12 ? 'PM' : 'AM';
    return '$hour12 $suffix';
  }

  Future<Map<String, int>> _fetchSoldQuantitiesByItemName() async {
    final bills = await getAllBills();
    return _sumItemQuantitiesByName(bills);
  }

  Map<String, int> _sumItemQuantitiesByName(List<BillRecord> bills) {
    final quantitiesByName = <String, int>{};

    for (final bill in bills) {
      for (final item in bill.items) {
        final name = (item['name'] as String?)?.trim() ?? '';
        if (name.isEmpty) {
          continue;
        }

        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        if (quantity <= 0) {
          continue;
        }

        quantitiesByName.update(
          name,
          (current) => current + quantity,
          ifAbsent: () => quantity,
        );
      }
    }

    return quantitiesByName;
  }

  Future<void> _applyKnownMenuPriceCorrections(Database db) async {
    for (final entry in _knownMenuPriceByName.entries) {
      await db.rawUpdate(
        '''
        UPDATE menu_items
        SET price = ?
        WHERE LOWER(TRIM(name)) = ?
          AND price != ?
        ''',
        <Object>[entry.value, entry.key, entry.value],
      );
    }
  }
}

class _BusinessDayRange {
  const _BusinessDayRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}
