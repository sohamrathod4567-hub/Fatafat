import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/menu_models.dart';

class MenuLoader {
  const MenuLoader();

  static const String _menuAssetPath = 'assets/menu.json';

  Future<List<Category>> loadMenu() async {
    final rawJson = await rootBundle.loadString(_menuAssetPath);
    final decoded = jsonDecode(rawJson);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Menu JSON root must be an object.');
    }

    final rawCategories = decoded['categories'];
    if (rawCategories is! List) {
      throw const FormatException('Menu JSON is missing categories.');
    }

    final categories = <Category>[];
    for (final category in rawCategories) {
      try {
        if (category is Map<String, dynamic>) {
          final parsed = Category.fromJson(category);
          if (parsed.items.isNotEmpty) {
            categories.add(parsed);
          }
        } else if (category is Map) {
          final parsed = Category.fromJson(Map<String, dynamic>.from(category));
          if (parsed.items.isNotEmpty) {
            categories.add(parsed);
          }
        }
      } on FormatException {
        continue;
      }
    }

    if (categories.isEmpty) {
      throw const FormatException('No valid menu categories found.');
    }

    return List<Category>.unmodifiable(categories);
  }
}
