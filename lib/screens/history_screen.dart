import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../services/db_service.dart';
import 'bill_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<BillRecord> _bills = const <BillRecord>[];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    loadBills();
  }

  Future<void> loadBills() async {
    try {
      final bills = await DbService.instance.getAllBills();
      if (!mounted) {
        return;
      }

      setState(() {
        _bills = bills;
        _isLoading = false;
        _hasError = false;
      });
    } catch (error, stackTrace) {
      debugPrint('History load failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _refreshBills() async {
    await loadBills();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load bill history.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _bills.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No past bills yet.',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshBills,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _bills.length,
                        itemBuilder: (context, index) {
                          final bill = _bills[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _bills.length - 1 ? 0 : 12,
                            ),
                            child: _HistoryBillCard(bill: bill),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _HistoryBillCard extends StatelessWidget {
  const _HistoryBillCard({required this.bill});

  final BillRecord bill;

  int get _itemCount {
    return bill.items.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final billId = bill.id;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: billId == null
            ? null
            : () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => BillDetailScreen(billId: billId),
                  ),
                );
              },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs ${bill.totalAmount.toStringAsFixed(0)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_itemCount item${_itemCount == 1 ? '' : 's'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(bill.timestamp),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(bill.timestamp),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime timestamp) {
  final local = timestamp.toLocal();
  final month = _monthName(local.month);
  return '${local.day} $month ${local.year}';
}

String _formatTime(DateTime timestamp) {
  final local = timestamp.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _monthName(int month) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[month - 1];
}
