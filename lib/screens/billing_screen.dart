import 'package:flutter/material.dart';

import '../services/db_service.dart';
import 'menu_screen.dart';
import 'summary_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  static const int _tableCount = 5;

  final List<MenuItemRecord> _menuItems = <MenuItemRecord>[];
  final Map<String, List<MenuItemRecord>> _menuItemsByCategory =
      <String, List<MenuItemRecord>>{};
  final List<_SelectedItem> _selectedItems = [];
  final Map<int, _TableBillState> _tableBills = <int, _TableBillState>{};
  double _totalAmount = 0;
  bool _isSavingBill = false;
  bool _isLoadingMenu = true;
  String? _selectedCategory;
  int _activeTable = 1;

  @override
  void initState() {
    super.initState();
    for (var tableNumber = 1; tableNumber <= _tableCount; tableNumber++) {
      _tableBills[tableNumber] = const _TableBillState();
    }
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    try {
      final items = await DbService.instance.getAllMenuItems();

      if (!mounted) {
        return;
      }

      setState(() {
        _menuItems
          ..clear()
          ..addAll(items);
        _menuItemsByCategory
          ..clear()
          ..addAll(_groupItemsByCategory(items));
        if (_selectedCategory == null || !_menuItemsByCategory.containsKey(_selectedCategory)) {
          _selectedCategory = _menuItemsByCategory.keys.isEmpty
              ? null
              : _menuItemsByCategory.keys.first;
        }
        _isLoadingMenu = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMenu = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load menu items.')),
      );
    }
  }

  Map<String, List<MenuItemRecord>> _groupItemsByCategory(List<MenuItemRecord> items) {
    final groupedItems = <String, List<MenuItemRecord>>{};

    for (final item in items) {
      final category = item.category.trim().isEmpty ? 'Uncategorized' : item.category.trim();
      groupedItems.putIfAbsent(category, () => <MenuItemRecord>[]).add(item);
    }

    return groupedItems;
  }

  List<MenuItemRecord> get _visibleMenuItems {
    final selectedCategory = _selectedCategory;
    if (selectedCategory == null) {
      return _menuItems;
    }

    return _menuItemsByCategory[selectedCategory] ?? const <MenuItemRecord>[];
  }

  bool _isSameMenuItem(MenuItemRecord first, MenuItemRecord second) {
    if (first.id != null && second.id != null) {
      return first.id == second.id;
    }

    return first.category == second.category &&
        first.subcategory == second.subcategory &&
        first.name == second.name &&
        first.price == second.price;
  }

  double _calculateTotalAmount() {
    return _selectedItems.fold<double>(
      0,
      (sum, selectedItem) => sum + selectedItem.subtotal,
    );
  }

  void _saveCurrentTableState() {
    _tableBills[_activeTable] = _TableBillState(
      items: _selectedItems
          .map((selectedItem) => selectedItem.copy())
          .toList(growable: false),
      totalAmount: _totalAmount,
    );
  }

  void _loadTableState(int tableNumber) {
    final tableState = _tableBills[tableNumber] ?? const _TableBillState();
    _selectedItems
      ..clear()
      ..addAll(
        tableState.items.map((selectedItem) => selectedItem.copy()),
      );
    _totalAmount = tableState.totalAmount;
  }

  void _switchTable(int tableNumber) {
    if (_isSavingBill || _activeTable == tableNumber) {
      return;
    }

    setState(() {
      _saveCurrentTableState();
      _activeTable = tableNumber;
      _loadTableState(tableNumber);
    });
  }

  void _addItem(MenuItemRecord item) {
    if (_isSavingBill) {
      return;
    }

    setState(() {
      final index = _selectedItems.indexWhere(
        (selectedItem) => _isSameMenuItem(selectedItem.item, item),
      );

      if (index >= 0) {
        _selectedItems[index].quantity++;
      } else {
        _selectedItems.add(_SelectedItem(item: item));
      }

      _totalAmount = _calculateTotalAmount();
    });
  }

  void _increaseSelectedItemQuantity(_SelectedItem selectedItem) {
    if (_isSavingBill) {
      return;
    }

    setState(() {
      selectedItem.quantity++;
      _totalAmount = _calculateTotalAmount();
    });
  }

  void _decreaseSelectedItemQuantity(_SelectedItem selectedItem) {
    if (_isSavingBill) {
      return;
    }

    setState(() {
      selectedItem.quantity--;

      if (selectedItem.quantity <= 0) {
        _selectedItems.remove(selectedItem);
      }

      _totalAmount = _calculateTotalAmount();
    });
  }

  void _removeSelectedItem(_SelectedItem selectedItem) {
    if (_isSavingBill) {
      return;
    }

    setState(() {
      _selectedItems.remove(selectedItem);
      _totalAmount = _calculateTotalAmount();
    });
  }

  void _cancelBill() {
    if (_isSavingBill) {
      return;
    }

    setState(() {
      _selectedItems.clear();
      _totalAmount = 0;
      _tableBills[_activeTable] = const _TableBillState();
    });
  }

  Future<void> _saveCurrentBillAndClear() async {
    if (_isSavingBill || _selectedItems.isEmpty || _totalAmount <= 0) {
      return;
    }

    final billSnapshot = _selectedItems
        .map(
          (selectedItem) => <String, Object?>{
            'name': selectedItem.item.name,
            'price': selectedItem.item.price,
            'quantity': selectedItem.quantity,
            'subtotal': selectedItem.subtotal,
          },
        )
        .toList(growable: false);
    final totalAmountSnapshot = _totalAmount;
    final timestamp = DateTime.now();

    setState(() {
      _isSavingBill = true;
    });

    try {
      await DbService.instance.saveBill(
        items: billSnapshot,
        totalAmount: totalAmountSnapshot,
        timestamp: timestamp,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedItems.clear();
        _totalAmount = 0;
        _isSavingBill = false;
        _tableBills[_activeTable] = const _TableBillState();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingBill = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the bill. Your current bill is still here.'),
        ),
      );
    }
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
              child: _isLoadingMenu
                  ? const Center(child: CircularProgressIndicator())
                  : _menuItems.isEmpty
                      ? Center(
                          child: Text(
                            'No menu items available.',
                            style: theme.textTheme.titleMedium,
                          ),
                        )
                      : Column(
                          children: [
                            SizedBox(
                              height: 56,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                                scrollDirection: Axis.horizontal,
                                itemCount: _tableCount,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final tableNumber = index + 1;
                                  final isActive = tableNumber == _activeTable;

                                  return SizedBox(
                                    width: 108,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: isActive
                                            ? const Color(0xFF111111)
                                            : const Color(0xFFF3F3F3),
                                        foregroundColor: isActive
                                            ? Colors.white
                                            : const Color(0xFF111111),
                                        side: BorderSide(
                                          color: isActive
                                              ? const Color(0xFF111111)
                                              : const Color(0xFF1F1F1F),
                                          width: isActive ? 2 : 1.4,
                                        ),
                                        elevation: isActive ? 1 : 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: () => _switchTable(tableNumber),
                                      child: Text(
                                        'Table $tableNumber',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              height: 56,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                                scrollDirection: Axis.horizontal,
                                itemCount: _menuItemsByCategory.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final category = _menuItemsByCategory.keys.elementAt(index);
                                  final isSelected = category == _selectedCategory;

                                  return SizedBox(
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: isSelected
                                            ? const Color(0xFF111111)
                                            : const Color(0xFFEAEAEA),
                                        foregroundColor: isSelected
                                            ? Colors.white
                                            : const Color(0xFF111111),
                                        padding: const EdgeInsets.symmetric(horizontal: 18),
                                      ),
                                      onPressed: () {
                                        if (_selectedCategory == category) {
                                          return;
                                        }

                                        setState(() {
                                          _selectedCategory = category;
                                        });
                                      },
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  mainAxisExtent: 150,
                                ),
                                itemCount: _visibleMenuItems.length,
                                itemBuilder: (context, index) {
                                  final item = _visibleMenuItems[index];

                                  return _MenuButton(
                                    item: item,
                                    onTap: _isSavingBill ? null : () => _addItem(item),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFDFD),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedItems.isNotEmpty) ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 144),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _selectedItems.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 12,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        itemBuilder: (context, index) {
                          final selectedItem = _selectedItems[index];

                          return _SelectedItemRow(
                            selectedItem: selectedItem,
                            onIncrease: _isSavingBill
                                ? null
                                : () => _increaseSelectedItemQuantity(selectedItem),
                            onDecrease: _isSavingBill
                                ? null
                                : () => _decreaseSelectedItemQuantity(selectedItem),
                            onDelete: _isSavingBill
                                ? null
                                : () => _removeSelectedItem(selectedItem),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB00020),
                              backgroundColor: const Color(0xFFFFF5F6),
                              side: const BorderSide(
                                color: Color(0xFFB00020),
                                width: 1.6,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _selectedItems.isEmpty || _isSavingBill
                                ? null
                                : _cancelBill,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Cancel Bill',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF1F1F1F),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Total',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: const Color(0xFF111111),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Expanded(
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Rs ${_totalAmount.toStringAsFixed(0)}',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 28,
                                            color: const Color(0xFF000000),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0B7A20),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _totalAmount == 0 || _isSavingBill
                                ? null
                                : _saveCurrentBillAndClear,
                            child: _isSavingBill
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Settle Bill',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const MenuScreen(),
                                ),
                              );
                              await _loadMenuItems();
                            },
                            child: const Text('Menu'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SummaryScreen(),
                                ),
                              );
                            },
                            child: const Text('View Today'),
                          ),
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
  const _SelectedItemRow({
    required this.selectedItem,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });

  final _SelectedItem selectedItem;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback? onDelete;

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
        const SizedBox(width: 8),
        _QuantityButton(
          icon: Icons.remove,
          onPressed: onDecrease,
        ),
        Container(
          width: 44,
          alignment: Alignment.center,
          child: Text(
            '${selectedItem.quantity}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF111111),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        _QuantityButton(
          icon: Icons.add,
          onPressed: onIncrease,
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          iconSize: 24,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          color: const Color(0xFF111111),
          tooltip: 'Remove item',
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 78,
          child: Text(
            'Rs ${selectedItem.subtotal.toStringAsFixed(0)}',
            textAlign: TextAlign.right,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: const Color(0xFF000000),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 22,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFECECEC),
        foregroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.item,
    required this.onTap,
  });

  final MenuItemRecord item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  height: 1.05,
                  color: const Color(0xFF111111),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rs ${item.price.toStringAsFixed(0)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 30,
                color: const Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedItem {
  _SelectedItem({
    required this.item,
    this.quantity = 1,
  });

  final MenuItemRecord item;
  int quantity;

  double get subtotal => item.price * quantity;

  _SelectedItem copy() {
    return _SelectedItem(
      item: item,
      quantity: quantity,
    );
  }
}

class _TableBillState {
  const _TableBillState({
    this.items = const <_SelectedItem>[],
    this.totalAmount = 0,
  });

  final List<_SelectedItem> items;
  final double totalAmount;
}
