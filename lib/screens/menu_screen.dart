import 'package:flutter/material.dart';

import '../services/db_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final List<MenuItemRecord> _items = <MenuItemRecord>[];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _subcategoryController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await DbService.instance.getAllMenuItems();

      if (!mounted) {
        return;
      }

      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load menu items.')),
      );
    }
  }

  Future<void> _addItem() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });

    try {
      final category = _categoryController.text.trim();
      final subcategory = _subcategoryController.text.trim();
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final id = await DbService.instance.addMenuItem(
        category: category,
        subcategory: subcategory,
        name: name,
        price: price,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items.add(
          MenuItemRecord(
            id: id,
            category: category,
            subcategory: subcategory,
            name: name,
            price: price,
          ),
        );
        _items.sort((first, second) {
          final categoryCompare =
              first.category.toLowerCase().compareTo(second.category.toLowerCase());
          if (categoryCompare != 0) {
            return categoryCompare;
          }

          final subcategoryCompare = first.subcategory
              .toLowerCase()
              .compareTo(second.subcategory.toLowerCase());
          if (subcategoryCompare != 0) {
            return subcategoryCompare;
          }

          return first.name.toLowerCase().compareTo(second.name.toLowerCase());
        });
        _categoryController.clear();
        _subcategoryController.clear();
        _nameController.clear();
        _priceController.clear();
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add the item.')),
      );
    }
  }

  Future<void> _deleteItem(MenuItemRecord item) async {
    final id = item.id;
    if (id == null) {
      return;
    }

    final index = _items.indexWhere((currentItem) => currentItem.id == id);
    if (index == -1) {
      return;
    }

    final removedItem = _items[index];
    setState(() {
      _items.removeAt(index);
    });

    try {
      await DbService.instance.deleteMenuItem(id);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _items.insert(index, removedItem);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the item.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _categoryController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subcategoryController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Subcategory (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Item name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter item name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: 'Rs ',
                      ),
                      onFieldSubmitted: (_) => _addItem(),
                      validator: (value) {
                        final price = double.tryParse(value?.trim() ?? '');
                        if (price == null || price <= 0) {
                          return 'Enter valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _addItem,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                            'No menu items yet.',
                            style: theme.textTheme.titleMedium,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _items[index];

                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: ListTile(
                                title: Text(item.name),
                                subtitle: Text(
                                  [
                                    item.category,
                                    if (item.subcategory.isNotEmpty) item.subcategory,
                                    'Rs ${item.price.toStringAsFixed(0)}',
                                  ].join(' | '),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Delete item',
                                  onPressed: () => _deleteItem(item),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
