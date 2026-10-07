import 'package:flutter/material.dart';

import '../../../core/repositories/recipe_card_repository.dart';
import '../../../core/repositories/team_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import '../../cooking_mode/views/cooking_mode_screen.dart';
import 'haccp_screen.dart';

/// What a staff member sees: steps and timers for what's being cooked, no
/// costs or billing. This previews that mode from the owner's own account —
/// staff do not get a separate login.
class StaffViewScreen extends StatelessWidget {
  const StaffViewScreen({super.key, this.staff});

  final StaffMember? staff;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        backgroundColor: AppTheme.tintTeal,
        elevation: 0,
        foregroundColor: AppTheme.darkText,
        title: Text('Kitchen view', style: AppTheme.display(size: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Staff', style: AppTheme.display(size: 10.5)),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.tintTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              staff != null
                  ? 'Signed in as ${staff!.name} · ${staff!.roleLabel}. '
                      'Costs and billing are hidden on this account.'
                  : 'Costs and billing are hidden in this view.',
              style: AppTheme.body(size: 12.5, color: AppTheme.darkText, height: 1.5),
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: "Today's prep"),
          const SizedBox(height: 10),
          AsyncView<List<RecipeCard>>(
            load: ServiceScope.of(context).recipeCards.fetchAll,
            loadingBuilder: (_) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.coralPrimary)),
            ),
            emptyCheck: (cards) => cards.isEmpty,
            emptyBuilder: (_) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No recipe cards to prep yet.',
                style: AppTheme.body(size: 13, color: AppTheme.mutedText),
              ),
            ),
            builder: (context, cards, reload) => Column(
              children: [
                for (final card in cards.take(10)) _buildPrepRow(context, card),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.darkText,
              side: const BorderSide(color: AppTheme.inputBorder, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HaccpScreen()),
            ),
            icon: const Icon(Icons.checklist_rtl_outlined, size: 18),
            label: Text("Today's HACCP checks",
                style: AppTheme.display(size: 13.5, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrepRow(BuildContext context, RecipeCard card) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ChefniCard(
        padding: const EdgeInsets.all(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CookingModeScreen(
              recipeTitle: card.title,
              steps: card.steps,
            ),
          ),
        ),
        child: Row(
          children: [
            MediaSlot(width: 52, height: 52, radius: 11, seed: card.id),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.display(size: 13, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('${card.servings} servings',
                      style: AppTheme.body(size: 11.5, color: AppTheme.mutedText)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.chipNeutral,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('Start', style: AppTheme.display(size: 10.5)),
            ),
          ],
        ),
      ),
    );
  }
}
