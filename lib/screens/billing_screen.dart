import 'package:flutter/material.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  static const List<_MenuItem> _menuItems = [
    _MenuItem(name: 'Pani Puri', price: 30),
    _MenuItem(name: 'Masala Dosa', price: 80),
    _MenuItem(name: 'Veg Sandwich', price: 60),
    _MenuItem(name: 'Tea', price: 15),
    _MenuItem(name: 'Samosa', price: 20),
    _MenuItem(name: 'Cold Coffee', price: 50),
  ];

  final List<_SelectedItem> _selectedItems = [];
  double _totalAmount = 0;

  void _addItem(_MenuItem item) {
    setState(() {
      final index = _selectedItems.indexWhere(
        (selectedItem) => selectedItem.item.name == item.name,
      );

      if (index >= 0) {
        _selectedItems[index].quantity++;
      } else {
        _selectedItems.add(_SelectedItem(item: item));
      }

      _totalAmount += item.price;
    });
  }

  void _clearTotal() {
    setState(() {
      _selectedItems.clear();
      _totalAmount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.22,
                ),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];

                  return _MenuButton(
                    item: item,
                    onTap: () => _addItem(item),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedItems.isNotEmpty) ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _selectedItems.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 12,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        itemBuilder: (context, index) {
                          final selectedItem = _selectedItems[index];

                          return _SelectedItemRow(selectedItem: selectedItem);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total amount',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rs ${_totalAmount.toStringAsFixed(0)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 56,
                        child: FilledButton.tonal(
                          onPressed: _totalAmount == 0 ? null : _clearTotal,
                          child: const Text('New Bill'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedItemRow extends StatelessWidget {
  const _SelectedItemRow({required this.selectedItem});

  final _SelectedItem selectedItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            selectedItem.item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'x${selectedItem.quantity}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Rs ${selectedItem.subtotal.toStringAsFixed(0)}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.item,
    required this.onTap,
  });

  final _MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  item.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Text(
              'Rs ${item.price.toStringAsFixed(0)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.name,
    required this.price,
  });

  final String name;
  final double price;
}

class _SelectedItem {
  _SelectedItem({
    required this.item,
  });

  final _MenuItem item;
  int quantity = 1;

  double get subtotal => item.price * quantity;
}
