import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/recipe.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import '../../recipe_detail/views/recipe_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String _query = '';
  final String _cuisine = 'All';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Debounced so typing does not fire a request per keystroke.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);

    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discover', style: AppTheme.display(size: 24)),
                  const SizedBox(height: 14),
                  ChefniCard(
                    radius: 16,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 18, color: AppTheme.mutedText),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              hintText: 'Search recipes, cuisines, chefs…',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            style: AppTheme.body(size: 14.5),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            child: const Icon(Icons.close,
                                size: 18, color: AppTheme.mutedText),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: AsyncView<List<Recipe>>(
                key: ValueKey('$_cuisine|$_query'),
                load: () => services.recipes
                    .fetchRecipes(cuisine: _cuisine, search: _query),
                builder: (context, recipes, reload) {
                  if (recipes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          _query.isEmpty
                              ? 'No recipes in $_cuisine yet.'
                              : 'No recipes match "$_query"',
                          textAlign: TextAlign.center,
                          style:
                              AppTheme.body(size: 14, color: AppTheme.mutedText),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppTheme.coralPrimary,
                    onRefresh: () async => reload(),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.74,
                      ),
                      itemCount: recipes.length,
                      itemBuilder: (_, i) => _buildGridCard(recipes[i], reload),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(Recipe recipe, VoidCallback reload) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
          ),
        );
        reload();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: MediaSlot(
              radius: 16,
              seed: recipe.id.hashCode,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            recipe.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTheme.display(size: 13.5, weight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 2),
          Text(
            '${recipe.cuisine} · ${recipe.cookMinutes} min',
            style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }
}
