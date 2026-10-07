import 'package:flutter_test/flutter_test.dart';
import 'package:chefni_flutter_app/core/utils/recipe_calculator.dart';

void main() {
  group('Chefni Recipe Dynamic Scaling Engine Unit Tests', () {
    final rawIngredients = [
      {'name': 'Mutton Meat', 'quantity': 1000.0, 'unit': 'g', 'category': 'Base', 'cost_pkr': 1200.0},
      {'name': 'Karahi Spices', 'quantity': 4.0, 'unit': 'tbsp', 'category': 'Spices', 'cost_pkr': 80.0},
      {'name': 'Salt', 'quantity': 2.0, 'unit': 'tsp', 'category': 'Spices', 'cost_pkr': 10.0},
    ];

    test('Scaling 1000g base down to 250g calculates exact 0.25x ratio', () {
      final scaled = RecipeCalculatorEngine.scaleByBaseWeight(
        rawIngredients: rawIngredients,
        baseWeightGrams: 1000.0,
        targetWeightGrams: 250.0,
      );

      expect(scaled.length, 3);
      expect(scaled[0].scaledQuantity, 250.0); // 1000g * 0.25 = 250g
      expect(scaled[1].scaledQuantity, 1.0);   // 4 tbsp * 0.25 = 1 tbsp
      expect(scaled[2].scaledQuantity, 0.5);   // 2 tsp * 0.25 = 0.5 tsp
    });

    test('Scaling 4 servings to 10 servings calculates exact 2.5x ratio', () {
      final scaled = RecipeCalculatorEngine.scaleByServings(
        rawIngredients: rawIngredients,
        baseServings: 4,
        targetServings: 10,
      );

      expect(scaled[0].scaledQuantity, 2500.0); // 1000g * 2.5 = 2500g
      expect(scaled[1].scaledQuantity, 10.0);   // 4 tbsp * 2.5 = 10 tbsp
    });
  });
}
