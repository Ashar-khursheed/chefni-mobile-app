import 'package:flutter/material.dart';

import '../../../core/models/recipe.dart';
import '../../../core/models/session_scope.dart';
import '../../../core/models/user_session.dart';
import '../../../core/repositories/recipe_card_repository.dart';
import '../../../core/repositories/studio_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import '../../recipe_card/views/recipe_card_screen.dart';
import '../../recipe_detail/views/recipe_detail_screen.dart';
import '../../settings/views/settings_screen.dart';

class _ProfileData {
  const _ProfileData(this.recipeCards, this.videos, this.saved);

  final List<RecipeCard> recipeCards;
  final List<UserVideo> videos;
  final List<Recipe> saved;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int activeTab = 0; // 0: Recipes, 1: Reels, 2: Saved

  Future<_ProfileData> _load(BuildContext context) async {
    final services = ServiceScope.of(context);
    final results = await Future.wait([
      services.recipeCards.fetchAll(),
      services.studio.fetchMyVideos(),
      services.recipes.fetchSaved(),
    ]);
    return _ProfileData(
      results[0] as List<RecipeCard>,
      results[1] as List<UserVideo>,
      results[2] as List<Recipe>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.sessionOf(context);

    return Scaffold(
      backgroundColor: AppTheme.bgOffWhite,
      body: SafeArea(
        child: AsyncView<_ProfileData>(
          load: () => _load(context),
          builder: (context, data, reload) => RefreshIndicator(
            color: AppTheme.coralPrimary,
            onRefresh: () async => reload(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(session),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatItem('${data.recipeCards.length}', 'recipes'),
                            const SizedBox(width: 20),
                            _buildStatItem('${data.videos.length}', 'reels'),
                            const SizedBox(width: 20),
                            _buildStatItem('${data.saved.length}', 'saved'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            if (session.trialDaysRemaining != null)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.unlockBannerGradient,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${session.tier.label} · '
                                    '${session.trialDaysRemaining} days left',
                                    textAlign: TextAlign.center,
                                    style: AppTheme.display(
                                        size: 12.5, color: Colors.white),
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppTheme.chipNeutral,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    session.tier.label,
                                    style: AppTheme.display(
                                        size: 13, color: AppTheme.darkText),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.settings_outlined,
                                    color: AppTheme.darkText, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (ctx) => const SettingsScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.chipNeutral,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _buildTabItem(0, 'Recipes'),
                              _buildTabItem(1, 'Reels'),
                              _buildTabItem(2, 'Saved'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildGrid(data),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserSession session) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 100,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.tealPrimary, AppTheme.coralPrimary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: -35,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.logoGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                session.initials,
                style: AppTheme.display(size: 26, color: Colors.white),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 112, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.name.isEmpty ? 'Chefni cook' : session.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.email.isEmpty ? session.tier.label : session.email,
                style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(_ProfileData data) {
    switch (activeTab) {
      case 1:
        return _buildVideoGrid(data.videos);
      case 2:
        return _buildSavedGrid(data.saved);
      case 0:
      default:
        return _buildRecipeCardGrid(data.recipeCards);
    }
  }

  Widget _tileGrid(int count, Widget Function(int) itemBuilder) {
    if (count == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'Nothing here yet.',
            style: AppTheme.body(size: 13, color: AppTheme.mutedText),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: count,
      itemBuilder: (context, index) => itemBuilder(index),
    );
  }

  Widget _buildRecipeCardGrid(List<RecipeCard> cards) {
    return _tileGrid(cards.length, (i) {
      final card = cards[i];
      return _buildTile(
        label: card.title,
        seed: card.id,
        icon: Icons.receipt_long_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeCardScreen(cardId: card.id)),
        ),
      );
    });
  }

  Widget _buildVideoGrid(List<UserVideo> videos) {
    return _tileGrid(videos.length, (i) {
      final video = videos[i];
      return _buildTile(
        label: video.title,
        seed: video.id,
        icon: Icons.play_circle_outline,
        onTap: video.hasRecipeCard
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeCardScreen(cardId: video.recipeCardId!),
                  ),
                )
            : null,
      );
    });
  }

  Widget _buildSavedGrid(List<Recipe> saved) {
    return _tileGrid(saved.length, (i) {
      final recipe = saved[i];
      return _buildTile(
        label: recipe.title,
        seed: recipe.id.hashCode,
        icon: Icons.bookmark_outline,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: recipe.id)),
        ),
      );
    });
  }

  Widget _buildTile({
    required String label,
    required int seed,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: MediaSlot(
        radius: 16,
        icon: icon,
        seed: seed,
        label: label,
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Row(
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.darkText),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.mutedText, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTabItem(int index, String label) {
    final bool isSelected = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.darkText : AppTheme.mutedText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
