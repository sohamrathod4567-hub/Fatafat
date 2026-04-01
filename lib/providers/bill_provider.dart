import 'package:flutter/foundation.dart';

import '../services/db_service.dart';

class BillProvider extends ChangeNotifier {
  final List<BillRecord> _bills = <BillRecord>[];
  DailyInsightsSummary _dailyInsights = const DailyInsightsSummary(
    totalSales: 0,
    billCount: 0,
    yesterdayTotalSales: 0,
    bestSellingItem: null,
    peakTimeLabel: 'No rush yet',
    recentBills: <RecentBillSummary>[],
  );
  bool _isLoadingBills = false;
  bool _isLoadingSummary = false;
  String? _historyErrorMessage;
  String? _summaryErrorMessage;

  List<BillRecord> get bills => List<BillRecord>.unmodifiable(_bills);
  DailyInsightsSummary get dailyInsights => _dailyInsights;
  bool get isLoadingBills => _isLoadingBills;
  bool get isLoadingSummary => _isLoadingSummary;
  String? get historyErrorMessage => _historyErrorMessage;
  String? get summaryErrorMessage => _summaryErrorMessage;

  Future<void> refreshAll({DateTime? now}) async {
    await Future.wait<void>([
      loadBills(),
      loadDailyInsights(now: now),
    ]);
  }

  Future<void> loadBills() async {
    _setBillsLoading(true);

    try {
      final bills = await DbService.instance.getAllBills();
      _bills
        ..clear()
        ..addAll(bills);
      _historyErrorMessage = null;
    } catch (_) {
      _historyErrorMessage = 'Could not load bill history.';
    } finally {
      _setBillsLoading(false);
    }
  }

  Future<void> loadDailyInsights({DateTime? now}) async {
    _setSummaryLoading(true);

    try {
      _dailyInsights = await DbService.instance.fetchDailyInsights(now: now);
      _summaryErrorMessage = null;
    } catch (_) {
      _summaryErrorMessage = 'Could not load today\'s summary.';
    } finally {
      _setSummaryLoading(false);
    }
  }

  void _setBillsLoading(bool value) {
    if (_isLoadingBills == value) {
      return;
    }

    _isLoadingBills = value;
    notifyListeners();
  }

  void _setSummaryLoading(bool value) {
    if (_isLoadingSummary == value) {
      return;
    }

    _isLoadingSummary = value;
    notifyListeners();
  }
}
