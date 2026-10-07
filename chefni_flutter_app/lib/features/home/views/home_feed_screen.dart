import 'package:flutter/material.dart';

import '../../../core/models/recipe.dart';
import '../../../core/models/session_scope.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_logo_widget.dart';
import '../../../core/widgets/chefni_ui.dart';
import '../../discover/views/discover_screen.dart';
import '../../notifications/views/notifications_screen.dart';
import '../../recipe_detail/views/recipe_detail_screen.dart';
import '../../shopping_list/views/shopping_list_screen.dart';
import '../../subscription/views/paywall_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  String _cuisine = 'All';

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);
    final session = SessionScope.sessionOf(context);

    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      body: SafeArea(
        bottom: false,
        child: AsyncView<_HomeData>(
          key: ValueKey(_cuisine),
          load: () async {
            final results = await Future.wait([
              services.recipes.fetchRecipes(cuisine: _cuisine),
              services.recipes.fetchCuisines(),
            ]);
            return _HomeData(
              recipes: results[0] as List<Recipe>,
              cuisines: results[1] as List<String>,
            );
          },
          builder: (context, data, reload) => RefreshIndicator(
            color: AppTheme.coralPrimary,
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                _buildHeader(session.name),
                const SizedBox(height: 14),
                _buildCreditTracker(session),
                const SizedBox(height: 14),
                _buildSearchBar(),
                const SizedBox(height: 14),
                _buildMyKitchenRow(),
                const SizedBox(height: 18),
                _buildCuisineChips(data.cuisines),
                if (data.recipes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Text(
                      'No recipes in $_cuisine yet.',
                      textAlign: TextAlign.center,
                      style: AppTheme.body(size: 14, color: AppTheme.mutedText),
                    ),
                  )
                else ...[
                  const SizedBox(height: 18),
                  _buildRecipeGrid(data.recipes, reload),
                ],
                if (session.showUpgradePrompts) ...[
                  const SizedBox(height: 14),
                  _buildSponsoredCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRecipe(Recipe recipe, VoidCallback reload) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: recipe.id)),
    );
    // Saved state may have changed while the detail screen was open.
    reload();
  }

  Future<void> _toggleSave(Recipe recipe, VoidCallback reload) async {
    try {
      await ServiceScope.of(context).recipes.toggleSave(recipe.id);
      reload();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 38),
        const ChefniLogoWidget(width: 108, showTagline: false),
        ChefniCircleButton(
          icon: Icons.notifications_none,
          showDot: true,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
      ],
    );
  }

  /// The trial/credit state is the first thing the spec wants a creator to see.
  Widget _buildCreditTracker(UserSession session) {
    final remaining = session.uploadQuotaRemaining;
    final unlimited = remaining == null;
    final total = session.uploadQuotaTotal ?? 0;
    final used = unlimited ? 0 : (total - remaining).clamp(0, total);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.coralPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.coralGlow(0.28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Credit Tracker',
                    style: AppTheme.display(size: 14, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Upgrade Pro',
                    style: AppTheme.display(
                      size: 11,
                      weight: FontWeight.w800,
                      color: AppTheme.coralPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  unlimited ? '∞' : '$remaining',
                  style: AppTheme.display(size: 20, color: Colors.white),
                ),
                const SizedBox(width: 4),
                Text(
                  unlimited ? 'Unlimited extractions' : '/ $total Credits Available',
                  style: AppTheme.body(size: 12.5, color: Colors.white70),
                ),
              ],
            ),
            if (!unlimited) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : used / total,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ChefniCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DiscoverScreen()),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppTheme.mutedText),
          const SizedBox(width: 10),
          Text(
            'Search recipes, cuisines, chefs…',
            style: AppTheme.body(size: 14.5, color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildMyKitchenRow() {
    return ChefniCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.tintCoral,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.lock_outline, size: 18, color: AppTheme.coralPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Kitchen',
                    style: AppTheme.display(size: 13.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Shopping list and recipes from your own videos — private to you',
                  style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.mutedText),
        ],
      ),
    );
  }

  Widget _buildCuisineChips(List<String> cuisines) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cuisines.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => ChefniChip(
          label: cuisines[i],
          selected: cuisines[i] == _cuisine,
          onTap: () => setState(() => _cuisine = cuisines[i]),
        ),
      ),
    );
  }

  Widget _buildRecipeGrid(List<Recipe> recipes, VoidCallback reload) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: recipes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, i) => _buildRecipeTile(recipes[i], reload),
    );
  }

  Widget _buildRecipeTile(Recipe recipe, VoidCallback reload) {
    return ChefniCard(
      padding: EdgeInsets.zero,
      onTap: () => _openRecipe(recipe, reload),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: MediaSlot(
                  height: 104,
                  width: double.infinity,
                  radius: 0,
                  seed: recipe.id.hashCode,
                ),
              ),
              const Positioned(
                right: 6,
                bottom: 6,
                child: ChefniLogoWidget(width: 42, showTagline: false),
              ),
              Positioned(
                left: 6,
                top: 6,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _toggleSave(recipe, reload),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      recipe.isSaved ? Icons.favorite : Icons.favorite_border,
                      size: 14,
                      color: AppTheme.coralPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.display(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: AppTheme.coralPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${recipe.cuisine} · ${recipe.cookMinutes} min',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(size: 10.5, color: AppTheme.mutedText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${recipe.calories} cal / serving',
                    style: AppTheme.body(size: 10.5, color: AppTheme.mutedText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsoredCard() {
    return ChefniCard(
      padding: const EdgeInsets.all(10),
      border: Border.all(color: AppTheme.cardBorder, width: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MediaSlot(
              width: 88, height: 88, radius: 14, icon: Icons.storefront, seed: 3),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.chipNeutral,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'SPONSORED',
                    style: AppTheme.display(
                      size: 9.5,
                      weight: FontWeight.w700,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Al-Falah Spices — fresh Nihari masala',
                    style: AppTheme.display(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('Restock your pantry in one tap',
                    style: AppTheme.body(size: 11.5, color: AppTheme.mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeData {
  const _HomeData({required this.recipes, required this.cuisines});

  final List<Recipe> recipes;
  final List<String> cuisines;
}
