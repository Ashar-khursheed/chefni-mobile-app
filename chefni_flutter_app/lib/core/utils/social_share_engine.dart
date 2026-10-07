import 'dart:io';

import 'package:share_plus/share_plus.dart';

/// Outbound sharing for reels and recipe cards.
///
/// The OS share sheet decides which apps appear — Instagram, TikTok, WhatsApp
/// and the rest show up when installed. There is no per-platform deep link
/// here because those APIs require app-specific SDKs and registered client IDs.
class SocialShareEngine {
  static const String _hashtags =
      '#Chefni #ChefniAI #FineFastFab #CookingReels #Recipes';

  static String _deepLink(String path) => 'https://chefni.com/$path';

  /// Shares the compressed, watermarked reel file itself. Falls back to a text
  /// share when the file is missing — a share sheet with a broken attachment is
  /// worse than one with just the link.
  static Future<void> shareReel({
    required String title,
    required String videoFilePath,
    String? recipeCardId,
  }) async {
    final link = _deepLink(
      recipeCardId != null ? 'recipe/$recipeCardId' : 'reels',
    );

    final caption = '🎬 $title — made with Chefni AI\n\n'
        'Watch the full recipe: $link\n\n$_hashtags';

    final file = File(videoFilePath);

    if (videoFilePath.isNotEmpty && await file.exists()) {
      await SharePlus.instance.share(ShareParams(
        files: [XFile(videoFilePath)],
        text: caption,
        subject: 'Chefni reel — $title',
      ));
      return;
    }

    await SharePlus.instance.share(ShareParams(
      text: caption,
      subject: 'Chefni reel — $title',
    ));
  }

  /// Shares a recipe card as text: what it makes, what it costs, and a link.
  static Future<void> shareRecipeCard({
    required String title,
    required String recipeId,
    String? totalCost,
    int? servings,
  }) async {
    final details = <String>[
      if (servings != null) 'Serves $servings',
      if (totalCost != null) 'Approx. $totalCost',
    ];

    final caption = '🍳 $title\n'
        '${details.isEmpty ? '' : '${details.join(' · ')}\n'}'
        '\nFull recipe and costing on Chefni:\n${_deepLink('recipe/$recipeId')}\n\n'
        '$_hashtags';

    await SharePlus.instance.share(ShareParams(
      text: caption,
      subject: 'Chefni recipe — $title',
    ));
  }
}
