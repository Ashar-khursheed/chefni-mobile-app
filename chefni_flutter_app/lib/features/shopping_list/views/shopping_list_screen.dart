import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/repositories/shopping_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _viewKey = GlobalKey<AsyncViewState<ShoppingList>>();

  void _reload() => _viewKey.currentState?.reload();

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      _reload();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _promptAddItem() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Add item', style: AppTheme.display(size: 17)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 2 lemons'),
          onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;
    await _run(() => ServiceScope.of(context).shopping.addItem(name));
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);

    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        title: Text('Shopping list', style: AppTheme.display(size: 19)),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: AsyncView<ShoppingList>(
        key: _viewKey,
        load: services.shopping.fetch,
        emptyCheck: (list) => list.items.isEmpty,
        emptyBuilder: (_) => _buildEmptyState(),
        builder: (context, list, reload) => RefreshIndicator(
          color: AppTheme.coralPrimary,
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Text(
                '${list.checkedCount} of ${list.totalCount} items collected',
                style: AppTheme.body(size: 13, color: AppTheme.mutedText),
              ),
              for (final entry in list.grouped.entries) ...[
                const SizedBox(height: 20),
                Text(
                  entry.key.toUpperCase(),
                  style: AppTheme.display(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppTheme.mutedText,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgWhite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (int i = 0; i < entry.value.length; i++)
                        _buildRow(
                          entry.value[i],
                          isLast: i == entry.value.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              _buildAddButton(),
              if (list.checkedCount > 0) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _run(
                    () => ServiceScope.of(context).shopping.clearChecked(),
                  ),
                  child: Text(
                    'Clear ${list.checkedCount} collected',
                    style: AppTheme.display(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(ShoppingItem item, {required bool isLast}) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.alertRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
      onDismissed: (_) => _run(
        () => ServiceScope.of(context).shopping.remove(item.id),
      ),
      child: InkWell(
        onTap: () => _run(
          () => ServiceScope.of(context).shopping.toggle(item.id),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: AppTheme.hairline)),
          ),
          child: Row(
            children: [
              ChefniCheckbox(checked: item.checked),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: AppTheme.body(
                    size: 14,
                    color: item.checked ? AppTheme.mutedText : AppTheme.darkText,
                  ).copyWith(
                    decoration: item.checked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (item.quantity.isNotEmpty)
                Text(item.quantity,
                    style: AppTheme.body(size: 12.5, color: AppTheme.mutedText)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _promptAddItem,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.tealPrimary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Text(
          '+ Add item',
          textAlign: TextAlign.center,
          style: AppTheme.display(
            size: 14,
            weight: FontWeight.w700,
            color: AppTheme.tealPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_basket_outlined,
                size: 44, color: AppTheme.mutedText),
            const SizedBox(height: 14),
            Text('Your list is empty', style: AppTheme.display(size: 17)),
            const SizedBox(height: 6),
            Text(
              'Open a recipe and tap "Add all to shopping list" to start building your list.',
              textAlign: TextAlign.center,
              style: AppTheme.body(size: 13.5, color: AppTheme.mutedText, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: ChefniPrimaryButton(
                label: 'Add an item',
                color: AppTheme.tealPrimary,
                glow: false,
                onPressed: _promptAddItem,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
