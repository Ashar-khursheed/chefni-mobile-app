class ScaledIngredient {
  final String name;
  final double baseQuantity;
  final double scaledQuantity;
  final String unit;
  final String category;
  final double estimatedCostPkr;

  ScaledIngredient({
    required this.name,
    required this.baseQuantity,
    required this.scaledQuantity,
    required this.unit,
    required this.category,
    required this.estimatedCostPkr,
  });
}

class RecipeCalculatorEngine {
  /// Calculate dynamic ingredient quantities scaled by target base-ingredient weight (e.g., 1000g -> 250g)
  static List<ScaledIngredient> scaleByBaseWeight({
    required List<Map<String, dynamic>> rawIngredients,
    required double baseWeightGrams,
    required double targetWeightGrams,
    double unitPriceMultiplier = 1.0,
  }) {
    if (baseWeightGrams <= 0) return [];
    final double ratio = targetWeightGrams / baseWeightGrams;

    return rawIngredients.map((item) {
      final double baseQty = (item['quantity'] as num).toDouble();
      final double scaledQty = baseQty * ratio;
      final double baseCost = (item['cost_pkr'] as num? ?? 50.0).toDouble();

      return ScaledIngredient(
        name: item['name'] as String,
        baseQuantity: baseQty,
        scaledQuantity: double.parse(scaledQty.toStringAsFixed(2)),
        unit: item['unit'] as String,
        category: item['category'] as String? ?? 'General',
        estimatedCostPkr: double.parse((baseCost * ratio * unitPriceMultiplier).toStringAsFixed(2)),
      );
    }).toList();
  }

  /// Calculate dynamic ingredient quantities scaled by target servings count (e.g., 4 servings -> 10 servings)
  static List<ScaledIngredient> scaleByServings({
    required List<Map<String, dynamic>> rawIngredients,
    required int baseServings,
    required int targetServings,
  }) {
    if (baseServings <= 0) return [];
    final double ratio = targetServings / baseServings;

    return rawIngredients.map((item) {
      final double baseQty = (item['quantity'] as num).toDouble();
      final double scaledQty = baseQty * ratio;
      final double baseCost = (item['cost_pkr'] as num? ?? 50.0).toDouble();

      return ScaledIngredient(
        name: item['name'] as String,
        baseQuantity: baseQty,
        scaledQuantity: double.parse(scaledQty.toStringAsFixed(2)),
        unit: item['unit'] as String,
        category: item['category'] as String? ?? 'General',
        estimatedCostPkr: double.parse((baseCost * ratio).toStringAsFixed(2)),
      );
    }).toList();
  }
}
