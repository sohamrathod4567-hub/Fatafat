import '../models/invoice.dart';
import 'database_service.dart';

class InvoiceRepository {
  Future<List<Invoice>> fetchInvoices() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'invoices',
      orderBy: 'created_at DESC',
    );

    return rows.map(Invoice.fromMap).toList(growable: false);
  }

  Future<Invoice> createInvoice(Invoice invoice) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert('invoices', invoice.toMap());
    return invoice.copyWith(id: id);
  }

  Future<void> deleteInvoice(int id) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
