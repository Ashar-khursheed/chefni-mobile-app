import 'package:flutter/material.dart';

import '../../../core/models/session_scope.dart';
import '../../../core/models/user_session.dart';
import '../../../core/repositories/recipe_card_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/pdf_exporter.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import '../../restaurant_pro/views/white_label_screen.dart';

/// Picks recipe cards and exports them as one branded, print-ready PDF
/// cookbook — Chefni's watermark unless white-label is turned on.
class CookbookExportScreen extends StatefulWidget {
  const CookbookExportScreen({super.key});

  @override
  State<CookbookExportScreen> createState() => _CookbookExportScreenState();
}

class _CookbookExportScreenState extends State<CookbookExportScreen> {
  final _titleController = TextEditingController();
  final Set<int> _selected = {};
  bool _includeCosts = true;
  bool _exporting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _export(List<RecipeCard> allCards, UserSession session) async {
    if (_selected.isEmpty || _exporting) return;
    setState(() => _exporting = true);

    try {
      final chosen = allCards.where((c) => _selected.contains(c.id)).toList();
      String? brandName;
      if (session.tier == SubscriptionTier.restaurantPro) {
        final branding = await ServiceScope.of(context).branding.fetch();
        if (branding.whiteLabelEnabled) brandName = branding.brandName;
      }

      final title = _titleController.text.trim().isEmpty
          ? "${session.name}'s Recipe Collection"
          : _titleController.text.trim();

      final bytes = await RecipePdfExporter.buildCookbookPdf(
        cookbookTitle: title,
        chefName: session.name.isEmpty ? 'Chefni cook' : session.name,
        recipes: chosen,
        includeCosts: _includeCosts,
        brandName: brandName,
      );
      await RecipePdfExporter.share(bytes, '${title.replaceAll(' ', '_')}.pdf');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.sessionOf(context);

    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        backgroundColor: AppTheme.bgShell,
        elevation: 0,
        foregroundColor: AppTheme.darkText,
        title: Text('Export cookbook', style: AppTheme.display(size: 17)),
      ),
      body: AsyncView<List<RecipeCard>>(
        load: ServiceScope.of(context).recipeCards.fetchAll,
        emptyCheck: (cards) => cards.isEmpty,
        emptyBuilder: (_) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Upload a video or write a recipe first — there is nothing to '
              'export yet.',
              textAlign: TextAlign.center,
              style: AppTheme.body(size: 13.5, color: AppTheme.mutedText, height: 1.5),
            ),
          ),
        ),
        builder: (context, cards, reload) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                children: [
                  Text('Your recipes as a PDF', style: AppTheme.display(size: 19)),
                  const SizedBox(height: 6),
                  Text(
                    'Pick recipes and export a print-ready cookbook.',
                    style: AppTheme.body(size: 13, color: AppTheme.mutedText),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Cookbook title',
                      hintText: "${session.name}'s Recipe Collection",
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Include costs per serving',
                            style: AppTheme.body(size: 13.5)),
                      ),
                      Switch(
                        value: _includeCosts,
                        onChanged: (v) => setState(() => _includeCosts = v),
                      ),
                    ],
                  ),
                  if (session.tier != SubscriptionTier.restaurantPro)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _lockedBrandingRow(),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recipes', style: AppTheme.display(size: 15)),
                      Text('${_selected.length} selected',
                          style: AppTheme.body(size: 12.5, color: AppTheme.mutedText)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final card in cards) _buildRow(card),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ChefniPrimaryButton(
                label: _exporting
                    ? 'Preparing…'
                    : _selected.isEmpty
                        ? 'Select recipes to export'
                        : 'Export PDF',
                onPressed: _exporting || _selected.isEmpty
                    ? null
                    : () => _export(cards, session),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lockedBrandingRow() {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WhiteLabelScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.chipNeutral,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppTheme.inputBorder, style: BorderStyle.solid),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 16, color: AppTheme.mutedText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Replace Chefni branding with your own — Restaurant Pro',
                  style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(RecipeCard card) {
    final selected = _selected.contains(card.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ChefniCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () => setState(() {
          if (selected) {
            _selected.remove(card.id);
          } else {
            _selected.add(card.id);
          }
        }),
        child: Row(
          children: [
            ChefniCheckbox(checked: selected),
            const SizedBox(width: 10),
            Expanded(
              child: Text(card.title,
                  style: AppTheme.display(size: 13, weight: FontWeight.w700)),
            ),
            Text('${card.servings} servings',
                style: AppTheme.body(size: 11.5, color: AppTheme.mutedText)),
          ],
        ),
      ),
    );
  }
}
