import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared primitives extracted from the Chefni prototype so screens stay
/// consistent: same radii, shadows, chip shapes and empty-media treatment.

/// White rounded card with the prototype's soft elevation.
class ChefniCard extends StatelessWidget {
  const ChefniCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
    this.onTap,
    this.color = AppTheme.bgWhite,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: border == null ? AppTheme.cardShadow : null,
        border: border,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: card,
    );
  }
}

/// Pill chip used for cuisine filters and tags.
class ChefniChip extends StatelessWidget {
  const ChefniChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.selectedColor = AppTheme.coralPrimary,
    this.idleColor = AppTheme.bgWhite,
    this.showBorder = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color selectedColor;
  final Color idleColor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? selectedColor : idleColor,
          borderRadius: BorderRadius.circular(999),
          border: showBorder && !selected
              ? Border.all(color: AppTheme.inputBorder, width: 1.5)
              : null,
        ),
        child: Text(
          label,
          style: AppTheme.display(
            size: 13.5,
            weight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.darkText,
          ),
        ),
      ),
    );
  }
}

/// Tinted tag used on recipe detail (teal tint, deep teal text).
class ChefniTag extends StatelessWidget {
  const ChefniTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.tintTeal,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTheme.display(
          size: 11.5,
          weight: FontWeight.w700,
          color: AppTheme.tealDeep,
        ),
      ),
    );
  }
}

/// Section heading with an optional trailing action ("See all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.size = 17,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTheme.display(size: size)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTheme.display(
                size: 13,
                weight: FontWeight.w700,
                color: AppTheme.tealPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Segmented control (recipe tabs, billing toggle) on the sand-tinted track.
class ChefniSegmented extends StatelessWidget {
  const ChefniSegmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.chipNeutral,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.bgWhite : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: AppTheme.display(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: selected ? AppTheme.darkText : AppTheme.mutedText,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Square checkbox used by ingredients and the shopping list.
class ChefniCheckbox extends StatelessWidget {
  const ChefniCheckbox({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21,
      height: 21,
      decoration: BoxDecoration(
        color: checked ? AppTheme.tealPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? AppTheme.tealPrimary : AppTheme.cardBorder,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : null,
    );
  }
}

/// Circular icon button on a white pill — back buttons, notification bell.
class ChefniCircleButton extends StatelessWidget {
  const ChefniCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.background = AppTheme.bgWhite,
    this.iconColor = AppTheme.darkText,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color background;
  final Color iconColor;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: AppTheme.softShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: iconSize, color: iconColor),
            if (showDot)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppTheme.coralPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.bgWhite, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Media placeholder standing in for recipe photography until real assets
/// are wired up. Mirrors the prototype's image slots.
class MediaSlot extends StatelessWidget {
  const MediaSlot({
    super.key,
    this.radius = 16,
    this.icon = Icons.restaurant_menu,
    this.label,
    this.height,
    this.width,
    this.seed = 0,
  });

  final double radius;
  final IconData icon;
  final String? label;
  final double? height;
  final double? width;
  final int seed;

  static const List<List<Color>> _palettes = [
    [AppTheme.tintTeal, AppTheme.tintCoral],
    [AppTheme.tintCoral, AppTheme.chipNeutral],
    [AppTheme.tintGreen, AppTheme.tintTeal],
    [AppTheme.chipNeutral, AppTheme.tintCoral],
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[seed.abs() % _palettes.length];
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.mutedText.withValues(alpha: 0.55), size: 24),
            if (label != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: AppTheme.body(size: 10.5, color: AppTheme.mutedText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-width primary action button (coral) used at the bottom of flows.
class ChefniPrimaryButton extends StatelessWidget {
  const ChefniPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppTheme.coralPrimary,
    this.glow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: glow ? AppTheme.coralGlow(0.30) : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: AppTheme.display(size: 15, weight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

/// Stat tile used across studio/admin dashboards.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaPositive = true,
  });

  final String label;
  final String value;
  final String? delta;
  final bool deltaPositive;

  @override
  Widget build(BuildContext context) {
    return ChefniCard(
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTheme.body(size: 11.5, color: AppTheme.mutedText)),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.display(size: 19)),
          if (delta != null) ...[
            const SizedBox(height: 2),
            Text(
              delta!,
              style: AppTheme.display(
                size: 11.5,
                weight: FontWeight.w700,
                color: deltaPositive ? AppTheme.successGreen : AppTheme.alertRed,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
