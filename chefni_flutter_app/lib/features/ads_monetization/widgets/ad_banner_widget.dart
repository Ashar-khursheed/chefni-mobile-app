import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chefni_ui.dart';

/// Sponsored slot. Styled as the prototype's dashed "SPONSORED" card so ads
/// read as clearly distinct from editorial content.
class ChefniAdBannerWidget extends StatelessWidget {
  const ChefniAdBannerWidget({
    super.key,
    required this.slotLocation,
    this.isAdminEnabled = true,
    this.headline = 'Al-Falah Spices — fresh Nihari masala',
    this.subline = 'Restock your pantry in one tap',
    this.onTap,
  });

  final String slotLocation;
  final bool isAdminEnabled;
  final String headline;
  final String subline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!isAdminEnabled) return const SizedBox.shrink();

    return ChefniCard(
      padding: const EdgeInsets.all(10),
      border: Border.all(color: AppTheme.cardBorder, width: 1),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MediaSlot(
            width: 72,
            height: 72,
            radius: 12,
            icon: Icons.storefront,
            seed: 3,
          ),
          const SizedBox(width: 12),
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
                Text(
                  headline,
                  style: AppTheme.display(size: 13.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subline,
                  style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
