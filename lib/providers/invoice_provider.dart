import 'package:flutter/foundation.dart';

import '../models/invoice.dart';
import '../services/invoice_repository.dart';

class InvoiceProvider extends ChangeNotifier {
  InvoiceProvider({required InvoiceRepository repository})
      : _repository = repository;

  final InvoiceRepository _repository;

  final List<Invoice> _invoices = <Invoice>[];
  bool _isLoading = false;
  String? _errorMessage;

  List<Invoice> get invoices => List<Invoice>.unmodifiable(_invoices);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get totalAmount =>
      _invoices.fold<double>(0, (sum, invoice) => sum + invoice.amount);

  Future<void> loadInvoices() async {
    _setLoading(true);

    try {
      final invoices = await _repository.fetchInvoices();
      _invoices
        ..clear()
        ..addAll(invoices);
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Unable to load invoices.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addInvoice({
    required String customerName,
    required double amount,
    String notes = '',
  }) async {
    try {
      final invoice = Invoice(
        customerName: customerName.trim(),
        amount: amount,
        createdAt: DateTime.now(),
        notes: notes.trim(),
      );
      final savedInvoice = await _repository.createInvoice(invoice);
      _invoices.insert(0, savedInvoice);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to save invoice.';
      notifyListeners();
      return false;
    }
  }

  Future<void> removeInvoice(int id) async {
    final index = _invoices.indexWhere((invoice) => invoice.id == id);
    if (index == -1) {
      return;
    }

    final removedInvoice = _invoices.removeAt(index);
    notifyListeners();

    try {
      await _repository.deleteInvoice(id);
      final hadError = _errorMessage != null;
      _errorMessage = null;
      if (hadError) {
        notifyListeners();
      }
    } catch (_) {
      _invoices.insert(index, removedInvoice);
      _errorMessage = 'Unable to delete invoice.';
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }
}
