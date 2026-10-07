import 'package:flutter/material.dart';
import '../../../core/repositories/recipe_card_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/recipe_calculator.dart';
import '../../../core/utils/pdf_exporter.dart';
import '../../cooking_mode/views/cooking_mode_screen.dart';

/// Default demo recipe shown when the calculator is opened standalone (from
/// the FAB or Settings) rather than from a real, AI-generated recipe card.
const List<Map<String, dynamic>> _demoIngredients = [
  {'name': 'Chicken / Mutton', 'quantity': 1000.0, 'unit': 'g', 'category': 'Base Protein', 'cost_pkr': 1200.0},
  {'name': 'Cooking Oil / Ghee', 'quantity': 4.0, 'unit': 'tbsp', 'category': 'Fats', 'cost_pkr': 80.0},
  {'name': 'Red Chilli & Spice Mix', 'quantity': 2.5, 'unit': 'tbsp', 'category': 'Spices', 'cost_pkr': 50.0},
  {'name': 'Salt', 'quantity': 1.5, 'unit': 'tsp', 'category': 'Spices', 'cost_pkr': 10.0},
  {'name': 'Yogurt / Cream', 'quantity': 200.0, 'unit': 'g', 'category': 'Dairy', 'cost_pkr': 90.0},
  {'name': 'Water', 'quantity': 250.0, 'unit': 'ml', 'category': 'Liquid', 'cost_pkr': 0.0},
];

const List<String> _demoSteps = [
  'Heat oil in pan over medium flame for 3 minutes.',
  'Add meat and sauté for 10 minutes until golden brown.',
  'Add tomatoes, ginger, and Karahi Spice Mix.',
  'Cover and simmer on low heat for 15 minutes.',
  'Garnish with green chillies and ginger juliennes.',
];

class CalculatorScreen extends StatefulWidget {
  /// When opened from a real recipe card, scaling and costing work off its
  /// actual ingredients instead of the standalone demo recipe.
  const CalculatorScreen({super.key, this.recipeCard});

  final RecipeCard? recipeCard;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final double baseWeightGrams;
  late double targetWeightGrams;
  late final int baseServings;
  late int targetServings;
  late final String recipeTitle;
  late final String chefName;
  late final List<String> recipeSteps;
  late final List<Map<String, dynamic>> rawRecipeIngredients;

  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    final card = widget.recipeCard;
    if (card != null) {
      recipeTitle = card.title;
      chefName = 'Chefni AI';
      recipeSteps = card.steps;
      baseServings = card.servings;
      targetServings = card.servings;
      rawRecipeIngredients = card.ingredients
          .map((ing) => {
                'name': ing.name,
                'quantity': ing.quantity,
                'unit': ing.unit,
                'category': ing.category ?? 'General',
                'cost_pkr': ing.effectiveCost,
              })
          .toList();
      final baseProtein = rawRecipeIngredients.isNotEmpty
          ? (rawRecipeIngredients.first['quantity'] as num).toDouble()
          : 1000.0;
      baseWeightGrams = baseProtein > 0 ? baseProtein : 1000.0;
      targetWeightGrams = baseWeightGrams;
    } else {
      recipeTitle = 'Chefni Special Karahi';
      chefName = 'Chef Rabia Nasar';
      recipeSteps = _demoSteps;
      baseServings = 4;
      targetServings = 4;
      rawRecipeIngredients = _demoIngredients;
      baseWeightGrams = 1000.0;
      targetWeightGrams = 250.0;
    }
    _weightController = TextEditingController(text: targetWeightGrams.toStringAsFixed(0));
  }

  bool _exportingPdf = false;

  Future<void> _exportPdfRecipeCard(List<ScaledIngredient> scaledList) async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);

    final ingredientsData = scaledList.map((item) => {
      'name': item.name,
      'quantity': item.scaledQuantity,
      'unit': item.unit,
    }).toList();

    try {
      final bytes = await RecipePdfExporter.buildRecipeCardPdf(
        title: recipeTitle,
        chefName: chefName,
        servings: targetServings,
        baseWeightGrams: targetWeightGrams,
        ingredients: ingredientsData,
        steps: recipeSteps,
      );
      await RecipePdfExporter.share(bytes, '${recipeTitle.replaceAll(' ', '_')}.pdf');
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaledList = RecipeCalculatorEngine.scaleByBaseWeight(
      rawIngredients: rawRecipeIngredients,
      baseWeightGrams: baseWeightGrams,
      targetWeightGrams: targetWeightGrams,
    );

    final double totalCost = scaledList.fold(0.0, (sum, item) => sum + item.estimatedCostPkr);
    final double costPerServing = targetServings > 0 ? totalCost / targetServings : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        title: const Text('Portion Calculator'),
        backgroundColor: AppTheme.bgWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // RECIPE HEADER CARD
            Card(
              elevation: 2,
              shadowColor: Colors.black12,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCoralLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.calculate, color: AppTheme.coralPrimary, size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(recipeTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                              const SizedBox(height: 4),
                              Text(
                                'Original baseline: ${baseWeightGrams.toStringAsFixed(0)}g / $baseServings servings',
                                style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.coralPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => CookingModeScreen(
                                    recipeTitle: recipeTitle,
                                    steps: recipeSteps,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.restaurant, size: 16),
                            label: const Text('Cooking Mode 🍳', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.skyBlueText),
                              foregroundColor: AppTheme.skyBlueText,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _exportingPdf
                                ? null
                                : () => _exportPdfRecipeCard(scaledList),
                            icon: _exportingPdf
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.picture_as_pdf, size: 16),
                            label: Text(_exportingPdf ? 'Preparing…' : 'Export PDF 📄',
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SCALE INPUT CONTROLS
            const Text(
              '1. Scale by Protein Weight (Grams)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.skyBlueText),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Meat Weight',
                      suffixText: 'g',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppTheme.bgSkyBlueLight.withValues(alpha: 0.4),
                    ),
                    onChanged: (val) {
                      final double? parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() => targetWeightGrams = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Wrap(
                  spacing: 6,
                  children: [250, 500, 1000].map((w) {
                    final bool isSelected = targetWeightGrams == w.toDouble();
                    return ActionChip(
                      label: Text('${w}g'),
                      backgroundColor: isSelected ? AppTheme.coralPrimary : AppTheme.bgSkyBlueLight,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.darkText, fontWeight: FontWeight.bold),
                      onPressed: () {
                        setState(() {
                          targetWeightGrams = w.toDouble();
                          _weightController.text = w.toString();
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // REAL-TIME SCALED INGREDIENTS LIST
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Scaled Ingredients Matrix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkText)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCoralLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Ratio: ${(targetWeightGrams / baseWeightGrams).toStringAsFixed(2)}x',
                    style: const TextStyle(color: AppTheme.coralPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: scaledList.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final item = scaledList[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.bgCoralLight,
                      child: Text('${index + 1}', style: const TextStyle(color: AppTheme.coralPrimary, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(item.name, style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.bold)),
                    subtitle: Text(item.category, style: const TextStyle(color: AppTheme.mutedText, fontSize: 11)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.scaledQuantity} ${item.unit}',
                          style: const TextStyle(color: AppTheme.coralPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text('Rs. ${item.estimatedCostPkr}', style: const TextStyle(color: AppTheme.mutedText, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // COSTING SUMMARY BOX
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCoralLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.coralPrimary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Batch Cost', style: TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                      Text('Rs. ${totalCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Cost / Serving ($targetServings Servings)', style: const TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                      Text('Rs. ${costPerServing.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.skyBlueText)),
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
