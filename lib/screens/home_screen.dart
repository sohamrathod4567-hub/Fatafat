import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/invoice_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/invoice_list_item.dart';
import 'create_invoice_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        centerTitle: false,
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          final invoices = provider.invoices;

          if (provider.isLoading && invoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _SummaryCard(totalAmount: provider.totalAmount),
              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Material(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      dense: true,
                      title: Text(provider.errorMessage!),
                      trailing: IconButton(
                        onPressed: provider.clearError,
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: invoices.isEmpty
                    ? const EmptyState(
                        title: 'No invoices yet',
                        message: 'Add your first bill and it will stay available offline.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = invoices[index];
                          return InvoiceListItem(
                            key: ValueKey(invoice.id ?? index),
                            invoice: invoice,
                            onDelete: invoice.id == null
                                ? null
                                : () => provider.removeInvoice(invoice.id!),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const CreateInvoiceScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Bill'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalAmount});

  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total billed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs ${totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.receipt_long_rounded,
                color: theme.colorScheme.onPrimary,
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
