class MenuItem {
  const MenuItem({
    required this.name,
    required this.price,
  });

  final String name;
  final double price;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    final rawPrice = json['price'];

    final name = rawName is String ? rawName.trim() : '';
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse('$rawPrice') ?? 0;

    if (name.isEmpty || price <= 0) {
      throw const FormatException('Invalid menu item data.');
    }

    return MenuItem(
      name: name,
      price: price,
    );
  }
}

class Category {
  const Category({
    required this.name,
    required this.items,
  });

  final String name;
  final List<MenuItem> items;

  factory Category.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    final rawItems = json['items'];
    final name = rawName is String ? rawName.trim() : '';

    if (name.isEmpty) {
      throw const FormatException('Invalid category name.');
    }

    final parsedItems = <MenuItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          try {
            parsedItems.add(MenuItem.fromJson(item));
          } on FormatException {
            continue;
          }
        } else if (item is Map) {
          try {
            parsedItems.add(MenuItem.fromJson(Map<String, dynamic>.from(item)));
          } on FormatException {
            continue;
          }
        }
      }
    }

    return Category(
      name: name,
      items: List<MenuItem>.unmodifiable(parsedItems),
    );
  }
}
