import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/repositories/recipe_card_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/social_share_engine.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import '../../cooking_mode/views/cooking_mode_screen.dart';
import '../../recipe_calculator/views/calculator_screen.dart';

/// An AI-generated recipe card: ingredients, steps, and a cost breakdown whose
/// figures are the model's estimates until the user overrides them.
class RecipeCardScreen extends StatefulWidget {
  const RecipeCardScreen({super.key, required this.cardId});

  final int cardId;

  @override
  State<RecipeCardScreen> createState() => _RecipeCardScreenState();
}

class _RecipeCardScreenState extends State<RecipeCardScreen> {
  RecipeCard? _card;

  /// Edits held locally until saved. Keyed by ingredient id; a null value means
  /// "revert this row to the AI estimate".
  final Map<int, double?> _pendingCosts = {};

  bool _saving = false;

  bool get _hasUnsaved => _pendingCosts.isNotEmpty;

  double _effectiveCostFor(RecipeCardIngredient ingredient) {
    if (!_pendingCosts.containsKey(ingredient.id)) return ingredient.effectiveCost;
    return _pendingCosts[ingredient.id] ?? ingredient.aiEstimatedCost ?? 0;
  }

  /// Recomputed locally so the total moves as the user types, without a round trip.
  double get _liveTotal {
    final card = _card;
    if (card == null) return 0;
    return card.ingredients.fold<double>(0, (sum, i) => sum + _effectiveCostFor(i));
  }

  Future<void> _saveCosts() async {
    if (!_hasUnsaved || _saving) return;

    setState(() => _saving = true);

    try {
      final updated = await ServiceScope.of(context)
          .recipeCards
          .updateCosts(widget.cardId, Map.of(_pendingCosts));

      if (!mounted) return;
      setState(() {
        _card = updated;
        _pendingCosts.clear();
        _saving = false;
      });
      _toast('Costs saved.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showApiError(context, e);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.body(size: 13.5, color: Colors.white)),
        backgroundColor: AppTheme.darkText,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _share(RecipeCard card) async {
    await SocialShareEngine.shareRecipeCard(
      title: card.title,
      recipeId: card.id.toString(),
      totalCost: card.formatCost(_liveTotal),
      servings: card.servings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      body: SafeArea(
        bottom: false,
        child: AsyncView<RecipeCard>(
          load: () => ServiceScope.of(context).recipeCards.fetch(widget.cardId),
          builder: (context, card, reload) {
            // Keep the fetched card unless local edits are in flight.
            _card ??= card;
            final current = _card!;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    _buildHeader(current),
                    const SizedBox(height: 18),
                    _buildMeta(current),
                    if (current.summary != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        current.summary!,
                        style: AppTheme.body(
                            size: 13.5, color: AppTheme.mutedText, height: 1.5),
                      ),
                    ],
                    if (current.confidence.caution != null) ...[
                      const SizedBox(height: 16),
                      _buildNotice(
                        current.confidence.caution!,
                        AppTheme.accentGold,
                        Icons.info_outline,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildCardPanel(current),
                    const SizedBox(height: 24),
                    _buildCostSection(current),
                    const SizedBox(height: 26),
                    _buildCostMatrixSection(current),
                    const SizedBox(height: 26),
                    _buildStepsSection(current),
                  ],
                ),
                if (_hasUnsaved) _buildSaveBar(current),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(RecipeCard card) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChefniCircleButton(
          icon: Icons.arrow_back,
          size: 38,
          iconSize: 19,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.title, style: AppTheme.display(size: 20)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 13, color: AppTheme.tealDeep),
                  const SizedBox(width: 5),
                  Text(
                    'Generated from your video',
                    style: AppTheme.body(size: 11.5, color: AppTheme.tealDeep),
                  ),
                ],
              ),
            ],
          ),
        ),
        ChefniCircleButton(
          icon: Icons.ios_share,
          size: 38,
          iconSize: 18,
          onTap: () => _share(card),
        ),
      ],
    );
  }

  Widget _buildMeta(RecipeCard card) {
    final chips = <String>[
      if (card.cuisine != null) card.cuisine!,
      if (card.prepTimeMins != null) '${card.prepTimeMins} min prep',
      if (card.cookTimeMins != null) '${card.cookTimeMins} min cook',
      '${card.servings} servings',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((c) => ChefniTag(label: c)).toList(),
    );
  }

  // ── The printed recipe card ─────────────────────────────────────────────

  /// The client's card: ingredients, method and costs read side by side.
  /// Three columns need roughly 400dp to stay legible, so below that the same
  /// three become tabs rather than shrinking into unreadable text.
  Widget _buildCardPanel(RecipeCard card) {
    final total = _liveTotal;
    final perServing = total / (card.servings < 1 ? 1 : card.servings);

    return ChefniCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              children: [
                Text(
                  'Recipe Card',
                  style: AppTheme.body(size: 12.5, color: AppTheme.darkText),
                ),
                const SizedBox(height: 2),
                Text(
                  card.title,
                  textAlign: TextAlign.center,
                  style: AppTheme.display(
                    size: 20,
                    color: AppTheme.coralPrimaryDark,
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth < 400
                ? _buildCardTabs(card)
                : _buildCardColumns(card),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _buildCardFooterCell('SERVINGS', '${card.servings}')),
                const VerticalDivider(width: 1, color: AppTheme.cardBorder),
                Expanded(
                  child: _buildCardFooterCell(
                    'PER SERVING',
                    card.formatCost(perServing),
                    accent: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardColumns(RecipeCard card) {
    const headers = ['Ingredients', 'Steps', 'Costing'];
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppTheme.tintCoral,
            border: Border.symmetric(
              horizontal: BorderSide(color: AppTheme.cardBorder),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < headers.length; i++) ...[
                  Expanded(
                    flex: i == 2 ? 95 : 115,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                      child: Text(
                        headers[i],
                        textAlign: TextAlign.center,
                        style: AppTheme.display(
                          size: 10.5,
                          weight: FontWeight.w800,
                          color: AppTheme.coralPrimaryDark,
                        ),
                      ),
                    ),
                  ),
                  if (i < 2) const VerticalDivider(width: 1, color: AppTheme.cardBorder),
                ],
              ],
            ),
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 115, child: _buildCardIngredients(card)),
              const VerticalDivider(width: 1, color: AppTheme.cardBorder),
              Expanded(flex: 115, child: _buildCardSteps(card)),
              const VerticalDivider(width: 1, color: AppTheme.cardBorder),
              Expanded(flex: 95, child: _buildCardCosting(card)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardTabs(RecipeCard card) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.tintCoral,
              border: Border.symmetric(
                horizontal: BorderSide(color: AppTheme.cardBorder),
              ),
            ),
            child: TabBar(
              indicatorColor: AppTheme.coralPrimary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppTheme.coralPrimaryDark,
              unselectedLabelColor: AppTheme.mutedText,
              labelStyle: AppTheme.display(size: 11.5, weight: FontWeight.w800),
              unselectedLabelStyle:
                  AppTheme.display(size: 11.5, weight: FontWeight.w700),
              tabs: const [
                Tab(height: 38, text: 'Ingredients'),
                Tab(height: 38, text: 'Steps'),
                Tab(height: 38, text: 'Costing'),
              ],
            ),
          ),
          SizedBox(
            height: 210,
            child: TabBarView(
              children: [
                SingleChildScrollView(child: _buildCardIngredients(card, dense: false)),
                SingleChildScrollView(child: _buildCardSteps(card, dense: false)),
                SingleChildScrollView(child: _buildCardCosting(card, dense: false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardIngredients(RecipeCard card, {bool dense = true}) {
    final size = dense ? 9.5 : 12.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 13, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final ing in card.ingredients)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: EdgeInsets.only(top: dense ? 5 : 6),
                    decoration: const BoxDecoration(
                      color: AppTheme.coralPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${ing.quantityLabel} ${ing.name}',
                      style: AppTheme.body(size: size, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardSteps(RecipeCard card, {bool dense = true}) {
    final size = dense ? 9.5 : 12.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 13, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < card.steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}.',
                    style: AppTheme.display(
                      size: size,
                      weight: FontWeight.w800,
                      color: AppTheme.coralPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      card.steps[i],
                      style: AppTheme.body(size: size, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardCosting(RecipeCard card, {bool dense = true}) {
    final size = dense ? 9.5 : 12.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 13, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final ing in card.ingredients)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ing.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(size: size, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _costFigure(card, ing),
                    style: AppTheme.display(size: size, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Divider(height: 1, color: AppTheme.cardBorder),
          ),
          const SizedBox(height: 6),
          Text(
            'TOTAL ${card.currency}',
            style: AppTheme.body(
              size: 8.5,
              weight: FontWeight.w700,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            _liveTotal.toStringAsFixed(0),
            style: AppTheme.display(size: 15, color: AppTheme.coralPrimaryDark),
          ),
        ],
      ),
    );
  }

  /// The figure the costing column shows for a row — a pending edit wins over
  /// the saved value, so the total and the rows never disagree.
  String _costFigure(RecipeCard card, RecipeCardIngredient ingredient) {
    final pending = _pendingCosts.containsKey(ingredient.id)
        ? _pendingCosts[ingredient.id]
        : null;
    final value = pending ?? ingredient.effectiveCost;
    return value.toStringAsFixed(0);
  }

  Widget _buildCardFooterCell(String label, String value, {bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            style: AppTheme.body(
              size: 8.5,
              weight: FontWeight.w700,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.display(
              size: 15,
              color: accent ? AppTheme.coralPrimaryDark : AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Cost breakdown ──────────────────────────────────────────────────────

  Widget _buildCostSection(RecipeCard card) {
    final total = _liveTotal;
    final perServing = total / (card.servings < 1 ? 1 : card.servings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Cost breakdown'),
        const SizedBox(height: 12),

        // The disclaimer is the whole point of this screen — the figures below
        // are guesses, and the user is invited to correct them.
        _buildNotice(
          'These costs are AI estimates and may well be wrong. Tap any price to '
          'set your own.',
          AppTheme.accentGold,
          Icons.edit_outlined,
        ),
        const SizedBox(height: 14),

        ChefniCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < card.ingredients.length; i++) ...[
                _buildIngredientRow(card, card.ingredients[i]),
                if (i < card.ingredients.length - 1)
                  const Divider(height: 1, color: AppTheme.hairline, indent: 14, endIndent: 14),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.tintTeal,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTheme.display(size: 15)),
                  Text(card.formatCost(total),
                      style: AppTheme.display(size: 19, color: AppTheme.tealDeep)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Per serving',
                      style: AppTheme.body(size: 12.5, color: AppTheme.mutedText)),
                  Text(card.formatCost(perServing),
                      style: AppTheme.display(size: 13.5, weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                card.userEditedCost || _hasUnsaved
                    ? 'Includes your own price edits.'
                    : 'Entirely AI-estimated — edit any row to correct it.',
                textAlign: TextAlign.center,
                style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Full cost matrix: labor, overhead, packaging and gross margin ──────

  Widget _buildCostMatrixSection(RecipeCard card) {
    final ingredientsCost = _liveTotal;
    final trueTotal = ingredientsCost + card.laborCost + card.overheadCost + card.packagingCost;
    final rows = <({String label, double cost, Color color})>[
      (label: 'Raw ingredients', cost: ingredientsCost, color: AppTheme.coralPrimary),
      (label: 'Labor', cost: card.laborCost, color: AppTheme.tealPrimary),
      (label: 'Overhead', cost: card.overheadCost, color: AppTheme.accentGold),
      (label: 'Packaging', cost: card.packagingCost, color: AppTheme.mutedText),
    ];
    final margin = card.sellingPrice != null && card.sellingPrice! > 0
        ? ((card.sellingPrice! - trueTotal) / card.sellingPrice! * 100)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'Full cost matrix'),
            TextButton.icon(
              onPressed: () => _openCostMatrixEditor(card),
              icon: const Icon(Icons.tune, size: 15),
              label: Text('Edit', style: AppTheme.display(size: 12.5, weight: FontWeight.w700)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.tealDeep),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final row in rows) ...[
          ChefniCard(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: row.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(row.label,
                            style: AppTheme.display(size: 12.5, weight: FontWeight.w700)),
                      ],
                    ),
                    Text(card.formatCost(row.cost), style: AppTheme.display(size: 13)),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: trueTotal <= 0 ? 0 : (row.cost / trueTotal).clamp(0, 1),
                    minHeight: 5,
                    backgroundColor: AppTheme.chipNeutral,
                    valueColor: AlwaysStoppedAnimation(row.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
        ],
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkText,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _matrixSummaryRow('TOTAL COST', card.formatCost(trueTotal)),
              const SizedBox(height: 10),
              _matrixSummaryRow(
                'MENU PRICE',
                card.sellingPrice != null ? card.formatCost(card.sellingPrice!) : 'Not set',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Divider(height: 1, color: Colors.white24),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GROSS MARGIN',
                        style: AppTheme.display(size: 10, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        margin != null
                            ? '${card.formatCost(card.sellingPrice! - trueTotal)} profit'
                            : 'Set a menu price to see margin',
                        style: AppTheme.body(size: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                  Text(
                    margin != null ? '${margin.toStringAsFixed(1)}%' : '—',
                    style: AppTheme.display(size: 27, color: const Color(0xFF7FE3A0)),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (card.sellingPrice != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgWhite,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppTheme.inputBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Menu price per serving',
                    style: AppTheme.body(size: 12, color: AppTheme.mutedText)),
                Text(
                  card.formatCost(card.sellingPrice! / (card.servings < 1 ? 1 : card.servings)),
                  style: AppTheme.display(size: 13, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _matrixSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.display(size: 10, color: Colors.white70)),
        Text(value, style: AppTheme.display(size: 18, color: Colors.white)),
      ],
    );
  }

  Future<void> _openCostMatrixEditor(RecipeCard card) async {
    final laborController = TextEditingController(text: card.laborCost.toStringAsFixed(0));
    final overheadController = TextEditingController(text: card.overheadCost.toStringAsFixed(0));
    final packagingController = TextEditingController(text: card.packagingCost.toStringAsFixed(0));
    final sellingController =
        TextEditingController(text: card.sellingPrice?.toStringAsFixed(0) ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: AppTheme.bgWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit cost matrix', style: AppTheme.display(size: 16)),
                const SizedBox(height: 16),
                _matrixField(laborController, 'Labor (${card.currency})'),
                const SizedBox(height: 10),
                _matrixField(overheadController, 'Overhead (${card.currency})'),
                const SizedBox(height: 10),
                _matrixField(packagingController, 'Packaging (${card.currency})'),
                const SizedBox(height: 10),
                _matrixField(sellingController, 'Menu price — whole dish (${card.currency})'),
                const SizedBox(height: 18),
                ChefniPrimaryButton(
                  label: 'Save costing',
                  onPressed: () => Navigator.pop(sheetContext, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != true || !mounted) return;

    final labor = double.tryParse(laborController.text.trim()) ?? 0;
    final overhead = double.tryParse(overheadController.text.trim()) ?? 0;
    final packaging = double.tryParse(packagingController.text.trim()) ?? 0;
    final sellingPrice = double.tryParse(sellingController.text.trim());

    laborController.dispose();
    overheadController.dispose();
    packagingController.dispose();
    sellingController.dispose();

    try {
      final updated = await ServiceScope.of(context).recipeCards.updateCostMatrix(
            card.id,
            laborCost: labor,
            overheadCost: overhead,
            packagingCost: packaging,
            sellingPrice: sellingPrice,
          );
      if (!mounted) return;
      setState(() => _card = updated);
      _toast('Costing saved.');
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Widget _matrixField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildIngredientRow(RecipeCard card, RecipeCardIngredient ingredient) {
    final edited = _pendingCosts.containsKey(ingredient.id);
    final overridden = edited
        ? _pendingCosts[ingredient.id] != null
        : ingredient.isUserOverridden;
    final cost = _effectiveCostFor(ingredient);

    return InkWell(
      onTap: () => _openCostEditor(card, ingredient),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ingredient.name,
                      style: AppTheme.display(size: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    ingredient.quantityLabel +
                        (ingredient.category != null ? ' · ${ingredient.category}' : ''),
                    style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  card.formatCost(cost),
                  style: AppTheme.display(
                    size: 14,
                    color: overridden ? AppTheme.successDeep : AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  overridden ? 'your price' : 'AI estimate',
                  style: AppTheme.body(
                    size: 10.5,
                    color: overridden ? AppTheme.successGreen : AppTheme.mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined, size: 15, color: AppTheme.mutedText),
          ],
        ),
      ),
    );
  }

  Future<void> _openCostEditor(
    RecipeCard card,
    RecipeCardIngredient ingredient,
  ) async {
    final controller = TextEditingController(
      text: _effectiveCostFor(ingredient).toStringAsFixed(0),
    );

    final result = await showModalBottomSheet<_CostEdit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: AppTheme.bgWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ingredient.name, style: AppTheme.display(size: 16)),
              const SizedBox(height: 4),
              Text(
                '${ingredient.quantityLabel} · AI estimated '
                '${card.formatCost(ingredient.aiEstimatedCost ?? 0)}',
                style: AppTheme.body(size: 12.5, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: '${card.currency}  ',
                  prefixStyle: AppTheme.display(size: 15, color: AppTheme.mutedText),
                  filled: true,
                  fillColor: AppTheme.bgShell,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.tealPrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ChefniPrimaryButton(
                label: 'Use this price',
                onPressed: () {
                  final value = double.tryParse(controller.text.trim());
                  if (value == null || value < 0) return;
                  Navigator.pop(sheetContext, _CostEdit(value));
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext, const _CostEdit(null)),
                  child: Text(
                    'Revert to AI estimate',
                    style: AppTheme.display(size: 13, color: AppTheme.mutedText),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    controller.dispose();

    if (result == null || !mounted) return;

    setState(() {
      // A revert on a row the AI priced and the user never touched is a no-op.
      if (result.value == null && !ingredient.isUserOverridden) {
        _pendingCosts.remove(ingredient.id);
      } else {
        _pendingCosts[ingredient.id] = result.value;
      }
    });
  }

  // ── Steps ───────────────────────────────────────────────────────────────

  Widget _buildStepsSection(RecipeCard card) {
    if (card.steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Method'),
        const SizedBox(height: 12),
        for (var i = 0; i < card.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppTheme.tintCoral,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: AppTheme.display(size: 11.5, color: AppTheme.coralPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    card.steps[i],
                    style: AppTheme.body(size: 13.5, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ChefniPrimaryButton(
                label: 'Start cook mode',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CookingModeScreen(
                      recipeTitle: card.title,
                      steps: card.steps,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.tealDeep,
                  side: const BorderSide(color: AppTheme.tealPrimary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CalculatorScreen(recipeCard: card),
                  ),
                ),
                icon: const Icon(Icons.calculate_outlined, size: 17),
                label: Text('Scale & cost',
                    style: AppTheme.display(size: 13, weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Save bar ────────────────────────────────────────────────────────────

  Widget _buildSaveBar(RecipeCard card) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: AppTheme.bgWhite,
          border: Border(top: BorderSide(color: AppTheme.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_pendingCosts.length} price'
                  '${_pendingCosts.length == 1 ? '' : 's'} edited',
                  style: AppTheme.body(size: 12.5, color: AppTheme.mutedText),
                ),
              ),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _pendingCosts.clear()),
                child: Text(
                  'Discard',
                  style: AppTheme.display(size: 13, color: AppTheme.mutedText),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: _saving ? null : _saveCosts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.coralPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Save',
                        style: AppTheme.display(size: 13.5, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotice(String message, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTheme.body(size: 12.5, color: AppTheme.darkText, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Result of the cost sheet: a new price, or null meaning "revert to AI".
class _CostEdit {
  const _CostEdit(this.value);

  final double? value;
}
