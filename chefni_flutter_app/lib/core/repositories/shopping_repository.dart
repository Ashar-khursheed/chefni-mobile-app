import '../network/api_client.dart';

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = '',
    this.checked = false,
  });

  final int id;
  final String name;
  final String category;
  final String quantity;
  final bool checked;

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? 'Other',
        quantity: json['quantity'] as String? ?? '',
        checked: json['is_checked'] as bool? ?? false,
      );
}

class ShoppingList {
  const ShoppingList({
    required this.items,
    required this.totalCount,
    required this.checkedCount,
  });

  final List<ShoppingItem> items;
  final int totalCount;
  final int checkedCount;

  static const empty = ShoppingList(items: [], totalCount: 0, checkedCount: 0);

  /// Items grouped by source recipe, preserving server order.
  Map<String, List<ShoppingItem>> get grouped {
    final map = <String, List<ShoppingItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }
}

class ShoppingRepository {
  ShoppingRepository(this._api);

  final ApiClient _api;

  Future<ShoppingList> fetch() async {
    final json = await _api.get('/shopping-list');
    return ShoppingList(
      items: (json['data'] as List)
          .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      checkedCount: (json['checked_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> addItem(String name, {String? category}) async {
    await _api.post('/shopping-list', body: {
      'name': name,
      if (category != null) 'category': category,
    });
  }

  /// Returns how many lines were newly added (duplicates are skipped).
  Future<int> addFromRecipe(String recipeId, List<String> lines) async {
    final json = await _api.post('/shopping-list/from-recipe', body: {
      'recipe_slug': recipeId,
      'lines': lines,
    });
    return (json['added'] as num?)?.toInt() ?? 0;
  }

  Future<void> toggle(int id) => _api.post('/shopping-list/$id/toggle');

  Future<void> remove(int id) => _api.delete('/shopping-list/$id');

  Future<void> clearChecked() => _api.delete('/shopping-list/checked');
}
