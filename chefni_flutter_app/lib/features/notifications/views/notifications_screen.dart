import 'package:flutter/material.dart';

import '../../../core/repositories/notification_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';

/// Notices derived from the account's live state — credit resets, expiry
/// alerts and subscription reminders. There is nothing to mark read: each
/// notice simply stops appearing once the condition behind it clears.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        backgroundColor: AppTheme.bgShell,
        elevation: 0,
        foregroundColor: AppTheme.darkText,
        title: Text('Notifications', style: AppTheme.display(size: 18)),
      ),
      body: AsyncView<List<AppNotice>>(
        load: ServiceScope.of(context).notifications.fetchAll,
        emptyCheck: (notices) => notices.isEmpty,
        emptyBuilder: (_) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    size: 42, color: AppTheme.mutedText),
                const SizedBox(height: 14),
                Text("You're all caught up", style: AppTheme.display(size: 16)),
                const SizedBox(height: 8),
                Text(
                  'Credit resets, expiry alerts and subscription reminders will '
                  'show up here.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                      size: 13, color: AppTheme.mutedText, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        builder: (context, notices, reload) => RefreshIndicator(
          color: AppTheme.coralPrimary,
          onRefresh: () async => reload(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            itemCount: notices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _buildRow(notices[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(AppNotice notice) {
    final style = _styleFor(notice);
    return ChefniCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(style.icon, size: 16, color: style.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notice.title,
                    style: AppTheme.display(size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  notice.body,
                  style: AppTheme.body(size: 12, color: AppTheme.mutedText, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _NoticeStyle _styleFor(AppNotice notice) {
    switch (notice.type) {
      case 'credits':
        return const _NoticeStyle(Icons.bolt, AppTheme.tintCoral, AppTheme.coralPrimaryDark);
      case 'inventory':
        return notice.severity == NoticeSeverity.low
            ? const _NoticeStyle(
                Icons.kitchen_outlined, AppTheme.tintGreen, AppTheme.successDeep)
            : const _NoticeStyle(
                Icons.kitchen_outlined, AppTheme.tintCoral, AppTheme.coralPrimaryDark);
      case 'video':
        return const _NoticeStyle(Icons.error_outline, AppTheme.tintTeal, AppTheme.tealDeep);
      case 'subscription':
      default:
        return const _NoticeStyle(Icons.workspace_premium_outlined, AppTheme.tintCoral,
            AppTheme.coralPrimaryDark);
    }
  }
}

class _NoticeStyle {
  const _NoticeStyle(this.icon, this.background, this.iconColor);
  final IconData icon;
  final Color background;
  final Color iconColor;
}
