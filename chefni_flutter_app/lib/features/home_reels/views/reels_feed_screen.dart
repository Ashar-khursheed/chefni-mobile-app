import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/network/api_client.dart';
import '../../../core/repositories/reel_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/social_share_engine.dart';
import '../../../core/widgets/async_view.dart';
import '../../recipe_detail/views/recipe_detail_screen.dart';

/// The app's landing surface: Chefni's own published reels, played full-screen
/// and swiped vertically. Each reel links through to its recipe.
class ReelsFeedScreen extends StatefulWidget {
  const ReelsFeedScreen({super.key, this.onOpenMenu});

  /// Opens the app drawer. Null when the screen is not hosted by the shell.
  final VoidCallback? onOpenMenu;

  @override
  State<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends State<ReelsFeedScreen> {
  /// Local like overrides so a tap reflects immediately without refetching
  /// the whole feed. Keyed by reel id.
  final Map<String, ({bool isLiked, int likesCount})> _likeOverrides = {};

  Future<void> _toggleLike(ReelItem reel) async {
    try {
      final result = await ServiceScope.of(context).reels.toggleLike(reel.id);
      if (mounted) setState(() => _likeOverrides[reel.id] = result);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  void _share(ReelItem reel) {
    SocialShareEngine.shareReel(
      title: reel.title,
      // The feed serves a URL, not a local file, so this shares the link.
      videoFilePath: '',
      recipeCardId: reel.recipeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          AsyncView<List<ReelItem>>(
            load: ServiceScope.of(context).reels.fetchOfficialReels,
            loadingBuilder: (_) => const Center(
              child: CircularProgressIndicator(
                color: AppTheme.coralPrimary,
                strokeWidth: 2.5,
              ),
            ),
            emptyCheck: (reels) => reels.isEmpty,
            emptyBuilder: (_) => Center(
              child: Text(
                'No reels published yet.',
                style: AppTheme.body(size: 14, color: Colors.white60),
              ),
            ),
            builder: (context, reels, reload) => PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: reels.length,
              itemBuilder: (_, i) => _ReelPage(
                reel: reels[i],
                likeOverride: _likeOverrides[reels[i].id],
                onLike: () => _toggleLike(reels[i]),
                onShare: () => _share(reels[i]),
              ),
            ),
          ),
          if (widget.onOpenMenu != null) _buildTopBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            _GlassButton(icon: Icons.menu, onTap: widget.onOpenMenu!),
            const Spacer(),
            Text(
              'Chefni',
              style: AppTheme.display(size: 17, color: Colors.white),
            ),
            const Spacer(),
            // Balances the row so the wordmark stays centred.
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

/// One full-screen reel. Owns its player and only plays while actually visible,
/// so scrolling the feed does not leave audio running behind it.
class _ReelPage extends StatefulWidget {
  const _ReelPage({
    required this.reel,
    required this.likeOverride,
    required this.onLike,
    required this.onShare,
  });

  final ReelItem reel;

  /// Named `likeOverride` rather than `override` — a field called `override`
  /// shadows the annotation and breaks every `@override` in the class.
  final ({bool isLiked, int likesCount})? likeOverride;
  final VoidCallback onLike;
  final VoidCallback onShare;

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  VideoPlayerController? _controller;
  bool _initialising = true;
  String? _playbackError;
  bool _userPaused = false;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  Future<void> _initialise() async {
    final url = widget.reel.videoUrl;

    if (url.isEmpty) {
      setState(() {
        _initialising = false;
        _playbackError = 'This reel has no video attached.';
      });
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initialising = false;
      });
    } catch (e) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _initialising = false;
        _playbackError = 'This reel could not be played.';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Drives playback from how much of the page is on screen, so a half-swiped
  /// reel does not keep playing.
  void _onVisibilityChanged(VisibilityInfo info) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final visible = info.visibleFraction > 0.7;

    if (visible && !_userPaused) {
      controller.play();
    } else {
      controller.pause();
    }
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _userPaused = controller.value.isPlaying;
      _userPaused ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final isLiked = widget.likeOverride?.isLiked ?? reel.isLiked;
    final likesCount = widget.likeOverride?.likesCount ?? reel.likesCount;

    return VisibilityDetector(
      key: Key('reel-${reel.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _togglePlayback,
            child: _buildVideoLayer(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Color(0xB3000000), Color(0x00000000)],
              ),
            ),
          ),
          if (_userPaused) const Center(child: _PlayBadge()),
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
                _action(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '$likesCount',
                  color: isLiked ? AppTheme.coralPrimary : Colors.white,
                  onTap: widget.onLike,
                ),
                const SizedBox(height: 20),
                _action(
                  icon: Icons.chat_bubble_outline,
                  label: '${reel.commentsCount}',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Comments are coming soon.',
                          style: AppTheme.body(size: 13.5, color: Colors.white)),
                      backgroundColor: AppTheme.darkText,
                      behavior: SnackBarBehavior.floating,
                      shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _action(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: widget.onShare,
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 90,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.logoGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        reel.chef.isEmpty ? '?' : reel.chef[0].toUpperCase(),
                        style: AppTheme.display(size: 12, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(reel.chef,
                        style: AppTheme.display(size: 14, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  reel.caption,
                  style: AppTheme.body(size: 13.5, color: Colors.white, height: 1.4),
                ),
                if (reel.recipeId != null) ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipeId: reel.recipeId!),
                      ),
                    ),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.coralPrimary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'View full recipe',
                        style: AppTheme.display(size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_controller != null && _controller!.value.isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: AppTheme.coralPrimary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_initialising) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.coralPrimary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_outlined,
                  size: 44, color: Colors.white24),
              const SizedBox(height: 12),
              Text(
                _playbackError ?? 'Video unavailable.',
                textAlign: TextAlign.center,
                style: AppTheme.body(size: 13, color: Colors.white38),
              ),
            ],
          ),
        ),
      );
    }

    // Reels are 9:16; cover the screen rather than letterboxing them.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.body(size: 11.5, color: Colors.white)),
        ],
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 21, color: Colors.white),
      ),
    );
  }
}
