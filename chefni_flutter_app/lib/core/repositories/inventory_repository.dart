import '../network/api_client.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isExpiring,
    required this.isLowStock,
    this.daysToExpiry,
    this.storeId,
    this.unitCost,
    this.minThreshold,
  });

  final int id;
  final String name;
  final String quantity;
  final String unit;
  final bool isExpiring;
  final bool isLowStock;
  final int? daysToExpiry;
  final int? storeId;
  final double? unitCost;
  final double? minThreshold;

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        quantity: json['quantity']?.toString() ?? '',
        unit: json['unit'] as String? ?? '',
        isExpiring: json['is_expiring'] as bool? ?? false,
        isLowStock: json['is_low_stock'] as bool? ?? false,
        daysToExpiry: (json['days_to_expiry'] as num?)?.toInt(),
        storeId: (json['store_id'] as num?)?.toInt(),
        unitCost: (json['unit_cost'] as num?)?.toDouble(),
        minThreshold: (json['min_threshold'] as num?)?.toDouble(),
      );

  String get expiryLabel {
    if (daysToExpiry == null) return 'No expiry';
    if (daysToExpiry! < 0) return 'Expired';
    if (daysToExpiry == 0) return 'Today';
    return 'In $daysToExpiry days';
  }

  String get stockLabel => unit.isEmpty ? quantity : '$quantity $unit';
}

class RecipeRequirement {
  const RecipeRequirement({required this.name, required this.inStock});

  final String name;
  final bool inStock;

  factory RecipeRequirement.fromJson(Map<String, dynamic> json) =>
      RecipeRequirement(
        name: json['name'] as String? ?? '',
        inStock: json['in_stock'] as bool? ?? false,
      );
}

class RecipeAvailability {
  const RecipeAvailability({
    required this.canCook,
    required this.missingCount,
    required this.requirements,
  });

  final bool canCook;
  final int missingCount;
  final List<RecipeRequirement> requirements;

  List<RecipeRequirement> get missing =>
      requirements.where((r) => !r.inStock).toList();
}

class InventoryRepository {
  InventoryRepository(this._api);

  final ApiClient _api;

  Future<List<InventoryItem>> fetchItems({int? storeId}) async {
    final json = await _api.get('/inventory', query: {
      if (storeId != null) 'store_id': '$storeId',
    });
    return (json['data'] as List)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addItem({
    required String name,
    required String quantity,
    String unit = '',
    DateTime? expiryDate,
    int? storeId,
  }) async {
    await _api.post('/inventory', body: {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      if (expiryDate != null)
        'expiry_date': expiryDate.toIso8601String().split('T').first,
      if (storeId != null) 'store_id': storeId,
    });
  }

  Future<void> removeItem(int id) => _api.delete('/inventory/$id');

  /// Server-side check of a recipe against the user's pantry.
  Future<RecipeAvailability> checkRecipe(String recipeId) async {
    final json = await _api.get('/inventory/check/$recipeId');
    return RecipeAvailability(
      canCook: json['can_cook'] as bool? ?? false,
      missingCount: (json['missing_count'] as num?)?.toInt() ?? 0,
      requirements: (json['requirements'] as List)
          .map((e) => RecipeRequirement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
