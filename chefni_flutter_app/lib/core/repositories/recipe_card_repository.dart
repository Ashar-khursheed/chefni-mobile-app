import '../network/api_client.dart';

/// How much of the card the transcript actually supported.
enum ExtractionConfidence { high, medium, low }

extension ExtractionConfidenceX on ExtractionConfidence {
  static ExtractionConfidence fromApi(String? value) {
    switch (value) {
      case 'high':
        return ExtractionConfidence.high;
      case 'low':
        return ExtractionConfidence.low;
      case 'medium':
      default:
        return ExtractionConfidence.medium;
    }
  }

  /// Shown when the card may be mostly reconstruction rather than transcription.
  String? get caution {
    switch (this) {
      case ExtractionConfidence.high:
        return null;
      case ExtractionConfidence.medium:
        return 'Some quantities were inferred — check them against your recipe.';
      case ExtractionConfidence.low:
        return 'The video said little about quantities, so much of this card was '
            'inferred. Review it closely before relying on it.';
    }
  }
}

class RecipeCardIngredient {
  const RecipeCardIngredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.effectiveCost,
    required this.isUserOverridden,
    this.category,
    this.aiEstimatedCost,
    this.userCost,
  });

  final int id;
  final String name;
  final double quantity;
  final String unit;
  final String? category;

  /// The model's guess, kept so an edit can be reverted.
  final double? aiEstimatedCost;

  /// The user's override, when they have set one.
  final double? userCost;

  /// Override where present, AI estimate otherwise.
  final double effectiveCost;
  final bool isUserOverridden;

  factory RecipeCardIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeCardIngredient(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? '',
        category: json['category'] as String?,
        aiEstimatedCost: (json['ai_estimated_cost'] as num?)?.toDouble(),
        userCost: (json['user_cost'] as num?)?.toDouble(),
        effectiveCost: (json['effective_cost'] as num?)?.toDouble() ?? 0,
        isUserOverridden: json['is_user_overridden'] as bool? ?? false,
      );

  /// "1000 g" — trailing zeros dropped so whole numbers read cleanly.
  String get quantityLabel {
    final value = quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(2);
    return '$value $unit';
  }
}

class RecipeCard {
  const RecipeCard({
    required this.id,
    required this.title,
    required this.servings,
    required this.currency,
    required this.costIsAiEstimate,
    required this.userEditedCost,
    required this.confidence,
    required this.totalCost,
    required this.costPerServing,
    required this.steps,
    required this.ingredients,
    required this.laborCost,
    required this.overheadCost,
    required this.packagingCost,
    required this.trueTotalCost,
    required this.trueCostPerServing,
    this.sellingPrice,
    this.grossMarginPct,
    this.userVideoId,
    this.summary,
    this.cuisine,
    this.prepTimeMins,
    this.cookTimeMins,
    this.createdAt,
  });

  final int id;
  final int? userVideoId;
  final String title;
  final String? summary;
  final String? cuisine;
  final int? prepTimeMins;
  final int? cookTimeMins;
  final int servings;
  final String currency;

  /// True while every cost is still the model's own estimate.
  final bool costIsAiEstimate;
  final bool userEditedCost;

  final ExtractionConfidence confidence;
  final double totalCost;
  final double costPerServing;
  final List<String> steps;
  final List<RecipeCardIngredient> ingredients;
  final DateTime? createdAt;

  /// The full cost matrix — labor, overhead and packaging sit on the card
  /// itself (not per-ingredient), and a selling price turns the total into a
  /// gross margin.
  final double laborCost;
  final double overheadCost;
  final double packagingCost;
  final double? sellingPrice;
  final double trueTotalCost;
  final double trueCostPerServing;

  /// Null until a selling price is set — there is no margin without one.
  final double? grossMarginPct;

  factory RecipeCard.fromJson(Map<String, dynamic> json) => RecipeCard(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userVideoId: (json['user_video_id'] as num?)?.toInt(),
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String?,
        cuisine: json['cuisine'] as String?,
        prepTimeMins: (json['prep_time_mins'] as num?)?.toInt(),
        cookTimeMins: (json['cook_time_mins'] as num?)?.toInt(),
        servings: (json['servings'] as num?)?.toInt() ?? 1,
        currency: json['currency'] as String? ?? 'PKR',
        costIsAiEstimate: json['cost_is_ai_estimate'] as bool? ?? true,
        userEditedCost: json['user_edited_cost'] as bool? ?? false,
        confidence:
            ExtractionConfidenceX.fromApi(json['extraction_confidence'] as String?),
        totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
        costPerServing: (json['cost_per_serving'] as num?)?.toDouble() ?? 0,
        steps: (json['steps'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        ingredients: (json['ingredients'] as List?)
                ?.map((e) => RecipeCardIngredient.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        laborCost: (json['labor_cost'] as num?)?.toDouble() ?? 0,
        overheadCost: (json['overhead_cost'] as num?)?.toDouble() ?? 0,
        packagingCost: (json['packaging_cost'] as num?)?.toDouble() ?? 0,
        sellingPrice: (json['selling_price'] as num?)?.toDouble(),
        trueTotalCost: (json['true_total_cost'] as num?)?.toDouble() ?? 0,
        trueCostPerServing: (json['true_cost_per_serving'] as num?)?.toDouble() ?? 0,
        grossMarginPct: (json['gross_margin_pct'] as num?)?.toDouble(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  int? get totalTimeMins {
    if (prepTimeMins == null && cookTimeMins == null) return null;
    return (prepTimeMins ?? 0) + (cookTimeMins ?? 0);
  }

  String formatCost(double amount) => '$currency ${amount.toStringAsFixed(0)}';
}

class RecipeCardRepository {
  RecipeCardRepository(this._api);

  final ApiClient _api;

  Future<List<RecipeCard>> fetchAll() async {
    final json = await _api.get('/recipe-cards');
    return (json['data'] as List)
        .map((e) => RecipeCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecipeCard> fetch(int id) async {
    final json = await _api.get('/recipe-cards/$id');
    return RecipeCard.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Saves per-ingredient cost overrides. A null value reverts that ingredient
  /// to the AI's original estimate rather than setting it to zero.
  Future<RecipeCard> updateCosts(int id, Map<int, double?> costs) async {
    final json = await _api.patch(
      '/recipe-cards/$id/costs',
      body: {
        'costs': costs.entries
            .map((e) => {'ingredient_id': e.key, 'user_cost': e.value})
            .toList(),
      },
    );
    return RecipeCard.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<RecipeCard> updateDetails(int id, {String? title, int? servings}) async {
    final json = await _api.patch('/recipe-cards/$id', body: {
      if (title != null) 'title': title,
      if (servings != null) 'servings': servings,
    });
    return RecipeCard.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Labor, overhead, packaging and the menu's selling price — the rest of
  /// the full cost matrix, beyond per-ingredient costs.
  Future<RecipeCard> updateCostMatrix(
    int id, {
    required double laborCost,
    required double overheadCost,
    required double packagingCost,
    double? sellingPrice,
  }) async {
    final json = await _api.patch('/recipe-cards/$id', body: {
      'labor_cost': laborCost,
      'overhead_cost': overheadCost,
      'packaging_cost': packagingCost,
      if (sellingPrice != null) 'selling_price': sellingPrice,
    });
    return RecipeCard.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/recipe-cards/$id');
}
