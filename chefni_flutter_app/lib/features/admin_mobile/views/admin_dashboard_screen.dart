import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/repositories/admin_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';

enum AdminTab { overview, users, moderation, revenue, ads }

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, this.initialTab = AdminTab.overview});

  final AdminTab initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      body: SafeArea(
        bottom: false,
        child: switch (initialTab) {
          AdminTab.overview => const _OverviewTab(),
          AdminTab.users => const _UsersTab(),
          AdminTab.moderation => const _ModerationTab(),
          AdminTab.revenue => const _RevenueTab(),
          AdminTab.ads => const _AdsTab(),
        },
      ),
    );
  }
}

class _AdminScaffold extends StatelessWidget {
  const _AdminScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(title, style: AppTheme.display(size: 22)),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

/// Simple bar chart shared by the admin and studio dashboards.
class AdminBarChart extends StatelessWidget {
  const AdminBarChart({
    super.key,
    required this.points,
    this.color = AppTheme.tealPrimary,
  });

  final List<TrendPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = points.map((p) => p.value).fold<int>(0, (a, b) => a > b ? a : b);

    return ChefniCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: points.map((point) {
            // Guard against divide-by-zero on an all-zero series.
            final ratio = maxValue == 0 ? 0.0 : point.value / maxValue;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${point.value}',
                      style: AppTheme.body(size: 10, color: AppTheme.mutedText)),
                  const SizedBox(height: 4),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    height: (88 * ratio).clamp(2.0, 88.0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(point.label,
                      style: AppTheme.body(size: 10, color: AppTheme.mutedText)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────── Overview ───────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return AsyncView<AdminTelemetry>(
      load: ServiceScope.of(context).admin.fetchTelemetry,
      builder: (context, data, reload) => RefreshIndicator(
        color: AppTheme.coralPrimary,
        onRefresh: () async => reload(),
        child: _AdminScaffold(
          title: 'Platform overview',
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.75,
              children: [
                StatTile(label: 'Total users', value: '${data.totalUsers}'),
                StatTile(
                    label: 'Active subscriptions',
                    value: '${data.activeSubscriptions}'),
                StatTile(label: 'Recipes', value: '${data.totalRecipes}'),
                StatTile(label: 'Signups today', value: '${data.signupsToday}'),
              ],
            ),
            const SizedBox(height: 22),
            Text('Signups · last 7 days', style: AppTheme.display(size: 14.5)),
            const SizedBox(height: 12),
            AdminBarChart(points: data.signupTrend),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Users ───────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Color _planColor(String plan) => switch (plan) {
        'Creator' || 'Creator (trial)' => AppTheme.tealPrimary,
        'Restaurant Pro' => AppTheme.coralPrimary,
        _ => AppTheme.mutedText,
      };

  @override
  Widget build(BuildContext context) {
    final admin = ServiceScope.of(context).admin;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Users', style: AppTheme.display(size: 22)),
              const SizedBox(height: 14),
              TextField(
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search users by name or email…',
                  prefixIcon:
                      Icon(Icons.search, size: 20, color: AppTheme.mutedText),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<AdminUser>>(
            key: ValueKey(_query),
            load: () => admin.fetchUsers(search: _query),
            builder: (context, users, reload) {
              if (users.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      _query.isEmpty
                          ? 'No users yet.'
                          : 'No users match "$_query"',
                      style: AppTheme.body(size: 14, color: AppTheme.mutedText),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppTheme.coralPrimary,
                onRefresh: () async => reload(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  itemCount: users.length,
                  itemBuilder: (_, i) => _buildUserRow(users[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserRow(AdminUser user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ChefniCard(
        radius: 14,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: AppTheme.logoGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(user.initials,
                  style: AppTheme.display(size: 13, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(user.name,
                            style: AppTheme.display(
                                size: 13.5, weight: FontWeight.w700)),
                      ),
                      if (user.role == 'admin') ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.shield,
                            size: 13, color: AppTheme.tealDeep),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style:
                          AppTheme.body(size: 11.5, color: AppTheme.mutedText)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _planColor(user.plan).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                user.plan,
                style: AppTheme.display(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: _planColor(user.plan),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Revenue ───────────────────────────

class _RevenueTab extends StatelessWidget {
  const _RevenueTab();

  @override
  Widget build(BuildContext context) {
    return AsyncView<RevenueBreakdown>(
      load: ServiceScope.of(context).admin.fetchRevenue,
      builder: (context, data, reload) => RefreshIndicator(
        color: AppTheme.coralPrimary,
        onRefresh: () async => reload(),
        child: _AdminScaffold(
          title: 'Revenue',
          children: [
            Text('Subscriptions by plan', style: AppTheme.display(size: 14.5)),
            const SizedBox(height: 10),
            if (data.byPlan.isEmpty)
              Text('No active subscriptions yet.',
                  style: AppTheme.body(size: 13, color: AppTheme.mutedText))
            else
              ...data.byPlan.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ChefniCard(
                    radius: 12,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p.name,
                            style: AppTheme.display(
                                size: 13, weight: FontWeight.w700)),
                        Text('${p.count} subscribers',
                            style: AppTheme.body(
                                size: 13, color: AppTheme.mutedText)),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text('Payment gateway split', style: AppTheme.display(size: 14.5)),
            const SizedBox(height: 10),
            if (data.gatewaySplit.isEmpty)
              Text('No payments recorded yet.',
                  style: AppTheme.body(size: 13, color: AppTheme.mutedText))
            else
              ...data.gatewaySplit.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(g.name, style: AppTheme.body(size: 12)),
                          Text('${g.pct}%', style: AppTheme.body(size: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: g.pct / 100,
                          minHeight: 8,
                          backgroundColor: AppTheme.chipNeutral,
                          valueColor:
                              const AlwaysStoppedAnimation(AppTheme.tealPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── Moderation & Ads (not yet backed) ───────────────────

class _ModerationTab extends StatelessWidget {
  const _ModerationTab();

  @override
  Widget build(BuildContext context) {
    return const _AdminScaffold(
      title: 'Moderation queue',
      children: [
        _NotWiredNotice(
          feature: 'Content moderation',
          detail:
              'Reporting and takedown endpoints are not implemented on the API yet. '
              'Once reports are captured server-side, this queue will list them here.',
        ),
      ],
    );
  }
}

class _AdsTab extends StatelessWidget {
  const _AdsTab();

  @override
  Widget build(BuildContext context) {
    return const _AdminScaffold(
      title: 'Advertising',
      children: [
        _NotWiredNotice(
          feature: 'Ad campaign management',
          detail:
              'Campaign, impression and spend data has no API endpoint yet. '
              'This screen will report live figures once ad serving is wired up.',
        ),
      ],
    );
  }
}

/// Honest placeholder: says a surface has no backing data instead of
/// showing invented numbers that read as real.
class _NotWiredNotice extends StatelessWidget {
  const _NotWiredNotice({required this.feature, required this.detail});

  final String feature;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return ChefniCard(
      radius: 16,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.construction, size: 18, color: AppTheme.accentGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text('$feature — not connected',
                    style: AppTheme.display(size: 14, weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(detail,
              style: AppTheme.body(
                  size: 12.5, color: AppTheme.mutedText, height: 1.5)),
        ],
      ),
    );
  }
}
