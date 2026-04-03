import 'package:flutter/material.dart';

import '../services/db_service.dart';

const String _rupeeSymbol = '\u20B9';
const String _bullet = '\u2022';
const String _upArrow = '\u2191';
const String _downArrow = '\u2193';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DailyInsightsSummary _summary = const DailyInsightsSummary(
    totalSales: 0,
    billCount: 0,
    yesterdayTotalSales: 0,
    bestSellingItem: null,
    peakTimeLabel: 'No rush yet',
    recentBills: <RecentBillSummary>[],
  );
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await DbService.instance.fetchDailyInsights();

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _summary = const DailyInsightsSummary(
          totalSales: 0,
          billCount: 0,
          yesterdayTotalSales: 0,
          bestSellingItem: null,
          peakTimeLabel: 'No rush yet',
          recentBills: <RecentBillSummary>[],
        );
        _isLoading = false;
        _errorMessage = 'Could not load today\'s summary.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comparison = _buildComparison(_summary);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today Summary'),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSummary,
                  child: SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                          children: [
                            _PrimarySection(
                              totalSales: _summary.totalSales,
                              billCount: _summary.billCount,
                              yesterdayTotalSales: _summary.yesterdayTotalSales,
                              comparisonLabel: comparison.label,
                              comparisonColor: comparison.color,
                            ),
                            const SizedBox(height: 18),
                            _InsightSection(
                              bestSellingItem: _summary.bestSellingItem,
                              peakTimeLabel: _summary.peakTimeLabel,
                            ),
                            const SizedBox(height: 18),
                            _RecentActivitySection(recentBills: _summary.recentBills),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _PrimarySection extends StatelessWidget {
  const _PrimarySection({
    required this.totalSales,
    required this.billCount,
    required this.yesterdayTotalSales,
    required this.comparisonLabel,
    required this.comparisonColor,
  });

  final double totalSales;
  final int billCount;
  final double yesterdayTotalSales;
  final String comparisonLabel;
  final Color comparisonColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Today',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF4A4A4A),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$_rupeeSymbol${totalSales.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF111111),
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$billCount bill${billCount == 1 ? '' : 's'} today',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF4A4A4A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Yesterday: $_rupeeSymbol${yesterdayTotalSales.toStringAsFixed(0)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              comparisonLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                color: comparisonColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.bestSellingItem,
    required this.peakTimeLabel,
  });

  final BestSellingItemSummary? bestSellingItem;
  final String peakTimeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bestSellerLabel = bestSellingItem == null
        ? 'No sales yet'
        : '${bestSellingItem!.name} $_bullet ${bestSellingItem!.quantitySold} sold';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.2),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Insights',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 14),
          _InsightRow(
            label: 'Best Seller',
            value: bestSellerLabel,
          ),
          const SizedBox(height: 12),
          _InsightRow(
            label: 'Peak Time',
            value: peakTimeLabel,
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF555555),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFF111111),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.recentBills});

  final List<RecentBillSummary> recentBills;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.2),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 14),
          if (recentBills.isEmpty)
            Text(
              'No bills yet today.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF555555),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...recentBills.map(
              (bill) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '$_rupeeSymbol${bill.totalAmount.toStringAsFixed(0)} $_bullet ${bill.itemCount} item${bill.itemCount == 1 ? '' : 's'} $_bullet ${_formatTime(bill.timestamp)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

_ComparisonViewModel _buildComparison(DailyInsightsSummary summary) {
  final yesterday = summary.yesterdayTotalSales;
  final today = summary.totalSales;

  if (yesterday <= 0) {
    if (today <= 0) {
      return const _ComparisonViewModel(
        label: '0%',
        color: Color(0xFF444444),
      );
    }

    return const _ComparisonViewModel(
      label: '$_upArrow New',
      color: Color(0xFF0B7A20),
    );
  }

  final percentChange = ((today - yesterday) / yesterday) * 100;
  final roundedPercent = percentChange.abs().toStringAsFixed(0);

  if (percentChange > 0) {
    return _ComparisonViewModel(
      label: '$_upArrow +$roundedPercent%',
      color: const Color(0xFF0B7A20),
    );
  }

  if (percentChange < 0) {
    return _ComparisonViewModel(
      label: '$_downArrow -$roundedPercent%',
      color: const Color(0xFFB00020),
    );
  }

  return const _ComparisonViewModel(
    label: '0%',
    color: Color(0xFF444444),
  );
}

String _formatTime(DateTime timestamp) {
  final local = timestamp.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

class _ComparisonViewModel {
  const _ComparisonViewModel({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}
