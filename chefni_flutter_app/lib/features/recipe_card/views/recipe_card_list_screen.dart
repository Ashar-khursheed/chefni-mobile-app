import 'package:flutter/material.dart';

import '../../../core/repositories/recipe_card_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import 'recipe_card_screen.dart';

/// Every recipe card Chefni has generated from this account's videos.
class RecipeCardListScreen extends StatelessWidget {
  const RecipeCardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        backgroundColor: AppTheme.bgShell,
        elevation: 0,
        foregroundColor: AppTheme.darkText,
        title: Text('My recipe cards', style: AppTheme.display(size: 18)),
      ),
      body: AsyncView<List<RecipeCard>>(
        load: ServiceScope.of(context).recipeCards.fetchAll,
        emptyCheck: (cards) => cards.isEmpty,
        emptyBuilder: (_) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 42, color: AppTheme.mutedText),
                const SizedBox(height: 14),
                Text('No recipe cards yet', style: AppTheme.display(size: 16)),
                const SizedBox(height: 8),
                Text(
                  'Upload a cooking video and Chefni will build a recipe card '
                  'from what you say while cooking.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                      size: 13, color: AppTheme.mutedText, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        builder: (context, cards, reload) => RefreshIndicator(
          color: AppTheme.coralPrimary,
          onRefresh: () async => reload(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _buildRow(context, cards[i], reload),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, RecipeCard card, VoidCallback reload) {
    return ChefniCard(
      padding: const EdgeInsets.all(14),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RecipeCardScreen(cardId: card.id)),
        );
        // Cost edits change the totals shown here.
        reload();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaSlot(
            width: 56,
            height: 56,
            radius: 14,
            seed: card.id,
            icon: Icons.restaurant_menu,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(size: 14.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    '${card.servings} servings',
                    if (card.totalTimeMins != null) '${card.totalTimeMins} min',
                    '${card.ingredients.length} ingredients',
                  ].join(' · '),
                  style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      card.formatCost(card.totalCost),
                      style: AppTheme.display(size: 13, color: AppTheme.tealDeep),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      card.userEditedCost ? 'your prices' : 'AI estimate',
                      style: AppTheme.body(
                        size: 11,
                        color: card.userEditedCost
                            ? AppTheme.successGreen
                            : AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
