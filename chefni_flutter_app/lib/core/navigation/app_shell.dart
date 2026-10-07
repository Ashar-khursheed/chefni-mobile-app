import 'package:flutter/material.dart';
import '../models/session_scope.dart';
import '../models/user_session.dart';
import '../theme/app_theme.dart';
import 'app_drawer.dart';

import '../../features/home/views/home_feed_screen.dart';
import '../../features/home_reels/views/reels_feed_screen.dart';
import '../../features/admin_mobile/views/admin_dashboard_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/recipe_calculator/views/calculator_screen.dart';
import '../../features/recipe_card/views/recipe_card_list_screen.dart';
import '../../features/studio/views/new_video_upload_screen.dart';

/// A single destination in the bottom bar.
class _Destination {
  const _Destination({
    required this.icon,
    required this.label,
    required this.builder,
  });

  final IconData icon;
  final String label;
  final Widget Function(BuildContext context, VoidCallback openMenu) builder;
}

/// The app's main surface. Reels is the landing screen for everyone except
/// admins, who get the operator surface instead. Everything that is not a
/// constant destination lives in the drawer.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Null until the first build knows the account type: creators land on Home
  /// (index 1), admins on their overview (index 0).
  int? _index;

  void _openMenu() => _scaffoldKey.currentState?.openDrawer();

  List<_Destination> _destinationsFor(UserSession session) {
    if (session.isAdmin) {
      return [
        _Destination(
          icon: Icons.insights_outlined,
          label: 'Overview',
          builder: (_, __) => const AdminDashboardScreen(),
        ),
        _Destination(
          icon: Icons.groups_outlined,
          label: 'Users',
          builder: (_, __) => const AdminDashboardScreen(initialTab: AdminTab.users),
        ),
        _Destination(
          icon: Icons.flag_outlined,
          label: 'Reports',
          builder: (_, __) =>
              const AdminDashboardScreen(initialTab: AdminTab.moderation),
        ),
        _Destination(
          icon: Icons.payments_outlined,
          label: 'Revenue',
          builder: (_, __) => const AdminDashboardScreen(initialTab: AdminTab.revenue),
        ),
        _Destination(
          icon: Icons.campaign_outlined,
          label: 'Ads',
          builder: (_, __) => const AdminDashboardScreen(initialTab: AdminTab.ads),
        ),
      ];
    }

    // Order and labels match the approved prototype: Reels, Home, then the
    // creator's own library and profile, with the upload button between them.
    return [
      _Destination(
        icon: Icons.play_circle_outline,
        label: 'Reels',
        builder: (_, openMenu) => ReelsFeedScreen(onOpenMenu: openMenu),
      ),
      _Destination(
        icon: Icons.home_outlined,
        label: 'Home',
        builder: (_, __) => const HomeFeedScreen(),
      ),
      _Destination(
        icon: Icons.receipt_long_outlined,
        label: 'Library',
        builder: (_, __) => const RecipeCardListScreen(),
      ),
      _Destination(
        icon: Icons.person_outline,
        label: 'Profile',
        builder: (_, __) => const ProfileScreen(),
      ),
    ];
  }

  void _openUpload() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewVideoUploadScreen()),
    );
  }

  void _openCalculator() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CalculatorScreen()),
    );
  }

  /// The `+` offers the three ways to start something, rather than assuming a
  /// video upload.
  void _openCreateSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: AppTheme.bgWhite,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.heroShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                decoration: BoxDecoration(
                  color: AppTheme.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _createOption(
                sheetContext,
                icon: Icons.videocam_outlined,
                title: 'Create New Reel',
                subtitle: 'Record or pick a cooking video',
                onTap: _openUpload,
              ),
              const Divider(height: 1, color: AppTheme.hairline, indent: 62),
              _createOption(
                sheetContext,
                icon: Icons.edit_note_outlined,
                title: 'Write New Recipe',
                subtitle: 'Type it in by hand',
                onTap: _openUpload,
              ),
              const Divider(height: 1, color: AppTheme.hairline, indent: 62),
              _createOption(
                sheetContext,
                icon: Icons.calculate_outlined,
                title: 'Calculate New Cost',
                subtitle: 'Price a dish without a video',
                onTap: _openCalculator,
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createOption(
    BuildContext sheetContext, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(sheetContext);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.tintCoral,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: AppTheme.coralPrimaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTheme.display(size: 13.5, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTheme.body(size: 11, color: AppTheme.mutedText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.sessionOf(context);
    final destinations = _destinationsFor(session);

    // Role or tier changes can shorten the bar while a later tab is active.
    final index = (_index ?? (session.isAdmin ? 0 : 1))
        .clamp(0, destinations.length - 1);

    // Admins operate the platform; they do not upload content.
    final showUploadButton = !session.isAdmin;

    // Reels is edge-to-edge dark; anything else sits on the shell background.
    final isImmersive = !session.isAdmin && index == 0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isImmersive ? const Color(0xFF121212) : AppTheme.bgShell,
      drawer: const AppDrawer(),
      body: destinations[index].builder(context, _openMenu),
      floatingActionButton: showUploadButton
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppTheme.coralGlow(0.40),
              ),
              child: FloatingActionButton(
                onPressed: _openCreateSheet,
                backgroundColor: AppTheme.coralPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 28),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildTabBar(
        destinations,
        index,
        showUploadButton,
        isImmersive,
        session.isAdmin,
      ),
    );
  }

  Widget _buildTabBar(
    List<_Destination> destinations,
    int activeIndex,
    bool hasNotch,
    bool isImmersive,
    bool isAdmin,
  ) {
    // With a docked FAB the destinations split around a centre gap.
    final int splitAt =
        hasNotch ? (destinations.length / 2).ceil() : destinations.length;

    final background = isImmersive ? const Color(0xFF1A1A1A) : AppTheme.bgWhite;
    final idleColor = isImmersive ? Colors.white54 : AppTheme.mutedText;

    Widget item(int i) {
      final d = destinations[i];
      final selected = i == activeIndex;
      final color = selected ? AppTheme.coralPrimary : idleColor;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _index = i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(d.icon, size: 22, color: color),
                const SizedBox(height: 3),
                Text(
                  d.label,
                  style: AppTheme.display(
                      size: 10, weight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border(
          top: BorderSide(
            color: isImmersive ? Colors.white12 : AppTheme.hairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // Admins reach the drawer from here since their screens have no
              // menu button of their own.
              if (isAdmin)
                SizedBox(
                  width: 52,
                  child: IconButton(
                    icon: Icon(Icons.menu, size: 22, color: idleColor),
                    onPressed: _openMenu,
                  ),
                ),
              for (int i = 0; i < splitAt; i++) item(i),
              if (hasNotch) const SizedBox(width: 64),
              for (int i = splitAt; i < destinations.length; i++) item(i),
            ],
          ),
        ),
      ),
    );
  }
}
