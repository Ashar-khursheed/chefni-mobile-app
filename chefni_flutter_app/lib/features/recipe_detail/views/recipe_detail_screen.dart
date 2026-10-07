import 'package:flutter/material.dart';

import '../../../core/models/recipe.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import '../../cooking_mode/views/cooking_mode_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _tabIndex = 0;
  int? _servings;
  final Set<int> _checked = {};
  bool? _savedOverride;
  bool _isAddingToList = false;

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);

    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      body: AsyncView<Recipe>(
        load: () => services.recipes.fetchRecipe(widget.recipeId),
        builder: (context, recipe, reload) {
          _servings ??= recipe.servingsBase;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHero(recipe),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recipe.tags.map((t) => ChefniTag(label: t)).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(recipe.title, style: AppTheme.display(size: 23)),
                    const SizedBox(height: 10),
                    _buildChefRow(recipe),
                    const SizedBox(height: 18),
                    _buildStatsStrip(recipe),
                    const SizedBox(height: 20),
                    ChefniSegmented(
                      labels: const ['Ingredients', 'Steps', 'Nutrition'],
                      selectedIndex: _tabIndex,
                      onChanged: (i) => setState(() => _tabIndex = i),
                    ),
                    const SizedBox(height: 20),
                    if (_tabIndex == 0) _buildIngredients(recipe),
                    if (_tabIndex == 1) _buildSteps(recipe),
                    if (_tabIndex == 2) _buildNutrition(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleSave(Recipe recipe) async {
    try {
      final saved = await ServiceScope.of(context).recipes.toggleSave(recipe.id);
      if (mounted) setState(() => _savedOverride = saved);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _addAllToShoppingList(Recipe recipe) async {
    setState(() => _isAddingToList = true);
    try {
      final lines = recipe.ingredients
          .map((line) => recipe.scaledIngredient(line, _servings!))
          .toList();
      final added =
          await ServiceScope.of(context).shopping.addFromRecipe(recipe.id, lines);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'Those ingredients are already on your list'
                : '$added items added to your shopping list',
            style: AppTheme.body(size: 13.5, color: Colors.white),
          ),
          backgroundColor: AppTheme.darkText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _isAddingToList = false);
    }
  }

  Widget _buildHero(Recipe recipe) {
    final isSaved = _savedOverride ?? recipe.isSaved;
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MediaSlot(
            radius: 0,
            seed: recipe.id.hashCode,
            label: 'Recipe video',
            icon: Icons.play_circle_outline,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Color(0x80000000), Color(0x00000000)],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 14,
            child: ChefniCircleButton(
              icon: Icons.arrow_back_ios_new,
              size: 38,
              iconSize: 16,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 14,
            child: ChefniCircleButton(
              icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
              size: 38,
              iconSize: 18,
              iconColor: isSaved ? AppTheme.coralPrimary : AppTheme.darkText,
              onTap: () => _toggleSave(recipe),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, size: 18, color: AppTheme.coralPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Watch cooking video · ${recipe.cookMinutes} min',
                    style: AppTheme.display(size: 12.5, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChefRow(Recipe recipe) {
    final initials = recipe.chef
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            gradient: AppTheme.logoGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(initials,
              style: AppTheme.display(size: 10, color: Colors.white)),
        ),
        const SizedBox(width: 8),
        Text(recipe.chef,
            style: AppTheme.display(size: 13, weight: FontWeight.w700)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '· ${recipe.likes} likes · ${recipe.comments} comments',
            style: AppTheme.body(size: 13, color: AppTheme.mutedText),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsStrip(Recipe recipe) {
    Widget cell(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value, style: AppTheme.display(size: 15)),
              const SizedBox(height: 2),
              Text(label, style: AppTheme.body(size: 11, color: AppTheme.mutedText)),
            ],
          ),
        );

    const divider = SizedBox(
      height: 32,
      child: VerticalDivider(width: 1, thickness: 1, color: AppTheme.hairline),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.tintCoral,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            cell('${recipe.prepMinutes} min', 'Prep'),
            divider,
            cell('${recipe.cookMinutes} min', 'Cook'),
            divider,
            cell(recipe.difficulty, 'Level'),
            divider,
            cell('${recipe.calories}', 'Cal / srv'),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredients(Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Servings',
                style: AppTheme.body(size: 13.5, color: AppTheme.mutedText)),
            Row(
              children: [
                _stepperButton(Icons.remove, () {
                  if (_servings! > 1) setState(() => _servings = _servings! - 1);
                }),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text('$_servings', style: AppTheme.display(size: 15)),
                ),
                _stepperButton(
                    Icons.add, () => setState(() => _servings = _servings! + 1)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(recipe.ingredients.length, (i) {
          final checked = _checked.contains(i);
          final line = recipe.scaledIngredient(recipe.ingredients[i], _servings!);
          return InkWell(
            onTap: () => setState(() {
              checked ? _checked.remove(i) : _checked.add(i);
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.hairline)),
              ),
              child: Row(
                children: [
                  ChefniCheckbox(checked: checked),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      line,
                      style: AppTheme.body(
                        size: 14.5,
                        color: checked ? AppTheme.mutedText : AppTheme.darkText,
                      ).copyWith(
                        decoration: checked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 18),
        _isAddingToList
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: CircularProgressIndicator(
                      color: AppTheme.tealPrimary, strokeWidth: 2.5),
                ),
              )
            : ChefniPrimaryButton(
                label: 'Add all to shopping list',
                color: AppTheme.tealPrimary,
                glow: false,
                onPressed: () => _addAllToShoppingList(recipe),
              ),
      ],
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppTheme.bgWhite,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.cardBorder, width: 1.5),
        ),
        child: Icon(icon, size: 16, color: AppTheme.darkText),
      ),
    );
  }

  Widget _buildSteps(Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(recipe.steps.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppTheme.coralPrimary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}',
                      style: AppTheme.display(size: 13, color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(recipe.steps[i],
                        style: AppTheme.body(size: 14.5, height: 1.55)),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        ChefniPrimaryButton(
          label: 'Start cook mode',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CookingModeScreen(
                  recipeTitle: recipe.title,
                  steps: recipe.steps,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNutrition() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 34, color: AppTheme.mutedText),
          const SizedBox(height: 10),
          Text('Coming in Phase 2', style: AppTheme.display(size: 15)),
          const SizedBox(height: 6),
          Text(
            'Full nutrition breakdown — calories, macros and allergens — is on the roadmap.',
            textAlign: TextAlign.center,
            style: AppTheme.body(size: 13, color: AppTheme.mutedText, height: 1.5),
          ),
        ],
      ),
    );
  }
}
