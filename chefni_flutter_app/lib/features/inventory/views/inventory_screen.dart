import 'package:flutter/material.dart';

import '../../../core/models/session_scope.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/repositories/inventory_repository.dart';
import '../../../core/repositories/store_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import '../../ads_monetization/widgets/ad_banner_widget.dart';
import 'store_switcher_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, this.checkRecipeId});

  /// When set, the screen also reports whether this recipe can be cooked
  /// from what is currently in the pantry.
  final String? checkRecipeId;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _viewKey = GlobalKey<AsyncViewState<_InventoryData>>();
  Store? _selectedStore;

  void _reload() => _viewKey.currentState?.reload();

  Future<void> _switchStore() async {
    final picked = await Navigator.of(context).push<Store>(
      MaterialPageRoute(
        builder: (_) => StoreSwitcherScreen(selectedStoreId: _selectedStore?.id),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedStore = picked);
    _reload();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      _reload();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _promptAddItem() async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Add pantry item', style: AppTheme.display(size: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Item name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(hintText: 'Quantity (e.g. 500g)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    final name = nameController.text.trim();
    if (confirmed != true || name.isEmpty || !mounted) return;

    await _run(
      () => ServiceScope.of(context).inventory.addItem(
            name: name,
            quantity: qtyController.text.trim().isEmpty
                ? '1'
                : qtyController.text.trim(),
            storeId: _selectedStore?.id,
          ),
    );
  }

  Future<void> _addMissingToShoppingList(RecipeAvailability availability) async {
    final recipeId = widget.checkRecipeId;
    if (recipeId == null) return;

    await _run(() async {
      final added = await ServiceScope.of(context).shopping.addFromRecipe(
            recipeId,
            availability.missing.map((r) => r.name).toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'Those items are already on your list'
                : '$added missing items added to your shopping list',
            style: AppTheme.body(size: 13.5, color: Colors.white),
          ),
          backgroundColor: AppTheme.darkText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);
    final session = SessionScope.sessionOf(context);

    final isRestaurantPro = session.tier == SubscriptionTier.restaurantPro;

    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        title: Text(
          _selectedStore?.name ?? 'My kitchen inventory',
          style: AppTheme.display(size: 19),
        ),
        actions: [
          if (isRestaurantPro)
            IconButton(
              icon: const Icon(Icons.storefront_outlined, size: 21),
              tooltip: 'Switch location',
              onPressed: _switchStore,
            ),
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            onPressed: _promptAddItem,
          ),
        ],
      ),
      body: AsyncView<_InventoryData>(
        key: _viewKey,
        load: () async {
          final items =
              await services.inventory.fetchItems(storeId: _selectedStore?.id);
          RecipeAvailability? availability;
          if (widget.checkRecipeId != null) {
            availability =
                await services.inventory.checkRecipe(widget.checkRecipeId!);
          }
          return _InventoryData(items: items, availability: availability);
        },
        builder: (context, data, reload) => RefreshIndicator(
          color: AppTheme.coralPrimary,
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              _buildIntroCard(),
              if (data.availability != null) ...[
                const SizedBox(height: 20),
                _buildAvailabilityCard(data.availability!),
              ],
              const SizedBox(height: 22),
              Text('Pantry stock', style: AppTheme.display(size: 17)),
              const SizedBox(height: 12),
              if (data.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    'Your pantry is empty. Tap + to add what you have at home.',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(size: 13.5, color: AppTheme.mutedText),
                  ),
                )
              else
                ...data.items.map(_buildPantryRow),
              if (session.showUpgradePrompts) ...[
                const SizedBox(height: 20),
                const ChefniAdBannerWidget(slotLocation: 'inventory_footer'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.tintTeal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppTheme.tealDeep, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Track what you have at home. Chefni checks each recipe against your '
              'pantry and builds a shopping list for anything missing.',
              style: AppTheme.body(size: 12.5, color: AppTheme.tealDeep, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard(RecipeAvailability availability) {
    return ChefniCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Can I cook this?', style: AppTheme.display(size: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: availability.canCook
                      ? AppTheme.tintGreen
                      : AppTheme.tintCoral,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  availability.canCook
                      ? 'Ready'
                      : '${availability.missingCount} missing',
                  style: AppTheme.display(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: availability.canCook
                        ? AppTheme.successDeep
                        : AppTheme.coralPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...availability.requirements.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(
                    r.inStock ? Icons.check_circle : Icons.cancel_outlined,
                    size: 16,
                    color: r.inStock ? AppTheme.successGreen : AppTheme.coralPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.name, style: AppTheme.body(size: 13.5))),
                ],
              ),
            ),
          ),
          if (!availability.canCook) ...[
            const SizedBox(height: 14),
            ChefniPrimaryButton(
              label: 'Add ${availability.missingCount} missing items to list',
              color: AppTheme.tealPrimary,
              glow: false,
              onPressed: () => _addMissingToShoppingList(availability),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPantryRow(InventoryItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppTheme.alertRed,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 18),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
        ),
        onDismissed: (_) => _run(
          () => ServiceScope.of(context).inventory.removeItem(item.id),
        ),
        child: ChefniCard(
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: AppTheme.display(size: 13.5, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('In stock: ${item.stockLabel}',
                        style: AppTheme.body(size: 11.5, color: AppTheme.mutedText)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:
                      item.isExpiring ? AppTheme.tintCoral : AppTheme.chipNeutral,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.expiryLabel,
                  style: AppTheme.display(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color:
                        item.isExpiring ? AppTheme.coralPrimary : AppTheme.mutedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryData {
  const _InventoryData({required this.items, this.availability});

  final List<InventoryItem> items;
  final RecipeAvailability? availability;
}
