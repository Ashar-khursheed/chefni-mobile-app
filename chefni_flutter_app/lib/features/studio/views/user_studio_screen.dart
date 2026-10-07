import 'package:flutter/material.dart';

import '../../../core/models/session_scope.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/repositories/studio_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/social_share_engine.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import '../../notifications/views/notifications_screen.dart';
import '../../recipe_card/views/recipe_card_screen.dart';
import 'new_video_upload_screen.dart';

/// Creator Studio — the account's uploaded videos and the recipe cards Chefni
/// built from them.
class UserStudioScreen extends StatefulWidget {
  const UserStudioScreen({super.key});

  @override
  State<UserStudioScreen> createState() => _UserStudioScreenState();
}

class _UserStudioScreenState extends State<UserStudioScreen> {
  final GlobalKey<AsyncViewState<List<UserVideo>>> _viewKey =
      GlobalKey<AsyncViewState<List<UserVideo>>>();

  Future<void> _openUpload() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewVideoUploadScreen()),
    );
    // A new upload should show up without a manual pull-to-refresh.
    _viewKey.currentState?.reload();
  }

  Future<void> _confirmDelete(UserVideo video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.bgWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete this video?', style: AppTheme.display(size: 16)),
        content: Text(
          'The reel and its recipe card will be removed permanently.',
          style: AppTheme.body(size: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: AppTheme.display(size: 13.5, color: AppTheme.mutedText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete',
                style: AppTheme.display(size: 13.5, color: AppTheme.alertRed)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ServiceScope.of(context).studio.deleteVideo(video.id);
      _viewKey.currentState?.reload();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);
    final session = SessionScope.sessionOf(context);
    final trialDays = session.trialDaysRemaining;

    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      body: SafeArea(
        bottom: false,
        child: AsyncView<List<UserVideo>>(
          key: _viewKey,
          load: services.studio.fetchMyVideos,
          builder: (context, videos, reload) => RefreshIndicator(
            color: AppTheme.coralPrimary,
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Creator Studio', style: AppTheme.display(size: 22)),
                        const SizedBox(height: 2),
                        Text(session.tier.label,
                            style: AppTheme.body(
                                size: 13, color: AppTheme.mutedText)),
                      ],
                    ),
                    ChefniCircleButton(
                      icon: Icons.notifications_none,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      ),
                    ),
                  ],
                ),
                if (trialDays != null) ...[
                  const SizedBox(height: 16),
                  _buildTrialBanner(trialDays),
                ],
                const SizedBox(height: 22),
                SectionHeader(title: 'My videos (${videos.length})'),
                const SizedBox(height: 12),
                if (videos.isEmpty)
                  _buildEmpty()
                else
                  ...videos.map(_buildVideoRow),
                const SizedBox(height: 18),
                ChefniPrimaryButton(
                  label: '+ Upload a cooking video',
                  onPressed: _openUpload,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 10),
      child: Column(
        children: [
          const Icon(Icons.video_library_outlined,
              size: 38, color: AppTheme.mutedText),
          const SizedBox(height: 12),
          Text(
            'Nothing uploaded yet. Add a cooking video and Chefni will turn it '
            'into a 1-minute reel and a recipe card.',
            textAlign: TextAlign.center,
            style:
                AppTheme.body(size: 13, color: AppTheme.mutedText, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoRow(UserVideo video) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ChefniCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(video),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.display(
                            size: 14, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      _buildStatusLine(video),
                      if (video.sizeSummary != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          [
                            video.sizeSummary!,
                            if (video.durationLabel != null) video.durationLabel!,
                          ].join(' · '),
                          style: AppTheme.body(
                              size: 11.5, color: AppTheme.mutedText),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline,
                      size: 19, color: AppTheme.mutedText),
                  onPressed: () => _confirmDelete(video),
                ),
              ],
            ),
            // A note on a ready video means the reel worked but the recipe did not.
            if (video.status == VideoStatus.ready && video.failureReason != null) ...[
              const SizedBox(height: 10),
              _buildNote(video.failureReason!, AppTheme.accentGold),
            ],
            if (video.status == VideoStatus.failed && video.failureReason != null) ...[
              const SizedBox(height: 10),
              _buildNote(video.failureReason!, AppTheme.alertRed),
            ],
            if (video.status == VideoStatus.ready) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (video.hasRecipeCard)
                    Expanded(
                      child: _buildAction(
                        icon: Icons.receipt_long_outlined,
                        label: 'Recipe card',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RecipeCardScreen(cardId: video.recipeCardId!),
                          ),
                        ),
                      ),
                    ),
                  if (video.hasRecipeCard) const SizedBox(width: 8),
                  Expanded(
                    child: _buildAction(
                      icon: Icons.ios_share,
                      label: 'Share',
                      onTap: () => SocialShareEngine.shareReel(
                        title: video.title,
                        videoFilePath: '',
                        recipeCardId: video.recipeCardId?.toString(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(UserVideo video) {
    if (video.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          video.thumbnailUrl!,
          width: 54,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => MediaSlot(
            width: 54,
            height: 72,
            radius: 12,
            seed: video.id,
            icon: Icons.play_arrow_rounded,
          ),
        ),
      );
    }

    return MediaSlot(
      width: 54,
      height: 72,
      radius: 12,
      seed: video.id,
      icon: Icons.play_arrow_rounded,
    );
  }

  Widget _buildStatusLine(UserVideo video) {
    switch (video.status) {
      case VideoStatus.ready:
        return Row(
          children: [
            const Icon(Icons.check_circle,
                size: 13, color: AppTheme.successGreen),
            const SizedBox(width: 5),
            Text('Ready',
                style: AppTheme.body(size: 11.5, color: AppTheme.successGreen)),
          ],
        );
      case VideoStatus.failed:
        return Row(
          children: [
            const Icon(Icons.error_outline, size: 13, color: AppTheme.alertRed),
            const SizedBox(width: 5),
            Text('Failed',
                style: AppTheme.body(size: 11.5, color: AppTheme.alertRed)),
          ],
        );
      default:
        return Row(
          children: [
            const SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                  strokeWidth: 1.8, color: AppTheme.coralPrimary),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                video.status.label,
                style: AppTheme.body(size: 11.5, color: AppTheme.coralPrimary),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.chipNeutral,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppTheme.darkText),
            const SizedBox(width: 6),
            Text(label,
                style: AppTheme.display(size: 12, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildNote(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        message,
        style: AppTheme.body(size: 11.5, color: AppTheme.darkText, height: 1.4),
      ),
    );
  }

  Widget _buildTrialBanner(int daysLeft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppTheme.unlockBannerGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  daysLeft > 0
                      ? '$daysLeft days left in your trial'
                      : 'Your trial ends today',
                  style: AppTheme.display(size: 13.5, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text('Keep unlimited uploads and recipe cards',
                    style: AppTheme.body(size: 11.5, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
