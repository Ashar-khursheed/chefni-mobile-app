import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/repositories/store_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';

/// Locations a Restaurant Pro account operates — inventory is scoped to
/// whichever one is selected here. Single-location accounts see just their
/// one default kitchen and never need this screen.
class StoreSwitcherScreen extends StatefulWidget {
  const StoreSwitcherScreen({super.key, this.selectedStoreId});

  final int? selectedStoreId;

  @override
  State<StoreSwitcherScreen> createState() => _StoreSwitcherScreenState();
}

class _StoreSwitcherScreenState extends State<StoreSwitcherScreen> {
  final _viewKey = GlobalKey<AsyncViewState<List<Store>>>();

  Future<void> _addStore() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Add a location', style: AppTheme.display(size: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Location name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(hintText: 'Address (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    final name = nameController.text.trim();
    if (confirmed != true || name.isEmpty || !mounted) return;

    try {
      await ServiceScope.of(context).stores.add(
            name: name,
            address: addressController.text.trim(),
          );
      _viewKey.currentState?.reload();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        backgroundColor: AppTheme.bgShell,
        elevation: 0,
        foregroundColor: AppTheme.darkText,
        title: Text('My locations', style: AppTheme.display(size: 18)),
      ),
      body: AsyncView<List<Store>>(
        key: _viewKey,
        load: ServiceScope.of(context).stores.fetchAll,
        builder: (context, stores, reload) => RefreshIndicator(
          color: AppTheme.coralPrimary,
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              for (final store in stores) _buildRow(store),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.darkText,
                  side: const BorderSide(color: AppTheme.inputBorder, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _addStore,
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add a location',
                    style: AppTheme.display(size: 13.5, weight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(Store store) {
    final selected = store.id == widget.selectedStoreId;
    final lowCount = store.lowStockCount ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ChefniCard(
        padding: const EdgeInsets.all(14),
        border: selected ? Border.all(color: AppTheme.coralPrimary, width: 2) : null,
        onTap: () => Navigator.of(context).pop(store),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.tintTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.storefront_outlined,
                  color: AppTheme.tealDeep, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name,
                      style: AppTheme.display(size: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (store.address != null) store.address!,
                      if (store.itemCount != null) '${store.itemCount} items',
                    ].join(' · '),
                    style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: lowCount == 0 ? AppTheme.tintGreen : AppTheme.tintCoral,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                lowCount == 0 ? '0 low' : '$lowCount low',
                style: AppTheme.display(
                  size: 10,
                  weight: FontWeight.w700,
                  color: lowCount == 0 ? AppTheme.successDeep : AppTheme.alertRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
