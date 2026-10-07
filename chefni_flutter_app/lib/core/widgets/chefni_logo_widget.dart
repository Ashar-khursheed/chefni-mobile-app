import 'package:flutter/material.dart';

/// The Chefni wordmark, drawn from the supplied brand asset.
///
/// The artwork carries the ribbon tagline, which is unreadable below roughly
/// 120 logical pixels — so [showTagline] crops to the oval for app bars and
/// other tight spots.
class ChefniLogoWidget extends StatelessWidget {
  const ChefniLogoWidget({
    super.key,
    this.width = 160,
    this.isDark = true,
    this.showTagline = true,
  });

  final double width;

  /// Retained so existing call sites keep compiling; the asset reads on either
  /// ground, so it no longer changes what is drawn.
  final bool isDark;

  /// False keeps only the oval badge — the tagline is illegible when small.
  final bool showTagline;

  static const String _asset = 'assets/images/chefni_logo.png';

  /// The source art is 285x166 with the ribbon occupying the lower ~28%.
  static const double _fullRatio = 285 / 166;
  static const double _ovalRatio = 285 / 120;

  @override
  Widget build(BuildContext context) {
    if (showTagline) {
      return Image.asset(
        _asset,
        width: width,
        fit: BoxFit.contain,
        semanticLabel: 'Chefni',
      );
    }

    // Crop the ribbon away rather than scaling the whole lockup down, so the
    // script stays as large as the space allows.
    return SizedBox(
      width: width,
      height: width / _ovalRatio,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: _ovalRatio / _fullRatio,
          child: Image.asset(
            _asset,
            width: width,
            fit: BoxFit.contain,
            semanticLabel: 'Chefni',
          ),
        ),
      ),
    );
  }
}
