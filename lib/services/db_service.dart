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

class DbService {
  DbService._();

  static final DbService instance = DbService._();

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

  Future<void> deleteBill(int id) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
