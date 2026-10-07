import 'package:flutter/material.dart';

import '../models/session_scope.dart';
import '../models/user_session.dart';
import '../services/service_locator.dart';
import '../theme/app_theme.dart';

import '../../features/inventory/views/inventory_screen.dart';
import '../../features/inventory/views/store_switcher_screen.dart';
import '../../features/legal_support/views/legal_screen.dart';
import '../../features/notifications/views/notifications_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/recipe_card/views/cookbook_export_screen.dart';
import '../../features/recipe_card/views/recipe_card_list_screen.dart';
import '../../features/restaurant_pro/views/haccp_screen.dart';
import '../../features/restaurant_pro/views/team_screen.dart';
import '../../features/restaurant_pro/views/white_label_screen.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../features/shopping_list/views/shopping_list_screen.dart';
import '../../features/studio/views/user_studio_screen.dart';
import '../../features/subscription/views/paywall_screen.dart';

/// Side navigation for everything the bottom bar does not carry. The bar keeps
/// the few surfaces people move between constantly; the drawer holds the rest.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SessionScope.of(context);
    final session = SessionScope.sessionOf(context);
    final services = ServiceScope.of(context);

    return Drawer(
      backgroundColor: AppTheme.bgShell,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(session),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (session.hasCreatorTools)
                    _tile(
                      context,
                      icon: Icons.bar_chart_rounded,
                      label: 'Creator Studio',
                      screen: const UserStudioScreen(),
                    ),
                  _tile(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: 'My recipe cards',
                    screen: const RecipeCardListScreen(),
                  ),
                  _tile(
                    context,
                    icon: Icons.checklist_rtl_outlined,
                    label: 'Shopping list',
                    screen: const ShoppingListScreen(),
                  ),
                  _tile(
                    context,
                    icon: Icons.kitchen_outlined,
                    label: 'Inventory',
                    screen: const InventoryScreen(),
                  ),
                  _tile(
                    context,
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                    screen: const NotificationsScreen(),
                  ),
                  if (session.hasCreatorTools)
                    _tile(
                      context,
                      icon: Icons.menu_book_outlined,
                      label: 'Export cookbook',
                      screen: const CookbookExportScreen(),
                    ),
                  if (session.tier == SubscriptionTier.restaurantPro) ...[
                    const _DrawerDivider(),
                    _tile(
                      context,
                      icon: Icons.storefront_outlined,
                      label: 'My locations',
                      screen: const StoreSwitcherScreen(),
                    ),
                    _tile(
                      context,
                      icon: Icons.groups_outlined,
                      label: 'Team',
                      screen: const TeamScreen(),
                    ),
                    _tile(
                      context,
                      icon: Icons.checklist_rtl_outlined,
                      label: 'HACCP logs',
                      screen: const HaccpScreen(),
                    ),
                    _tile(
                      context,
                      icon: Icons.sell_outlined,
                      label: 'White-label branding',
                      screen: const WhiteLabelScreen(),
                    ),
                  ],
                  const _DrawerDivider(),
                  _tile(
                    context,
                    icon: Icons.person_outline,
                    label: 'Profile',
                    screen: const ProfileScreen(),
                  ),
                  if (session.showUpgradePrompts)
                    _tile(
                      context,
                      icon: Icons.workspace_premium_outlined,
                      label: 'Upgrade to Creator',
                      screen: const PaywallScreen(),
                      highlight: true,
                    ),
                  _tile(
                    context,
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    screen: const SettingsScreen(),
                  ),
                  _tile(
                    context,
                    icon: Icons.description_outlined,
                    label: 'Legal & support',
                    screen: const LegalScreen(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.hairline),
            ListTile(
              leading: const Icon(Icons.logout, size: 21, color: AppTheme.alertRed),
              title: Text(
                'Sign out',
                style: AppTheme.display(size: 14, color: AppTheme.alertRed),
              ),
              onTap: () async {
                Navigator.pop(context);
                // Clear the stored bearer token too, otherwise the next launch
                // restores the session we just signed out of.
                try {
                  await services.auth.logout();
                } catch (_) {
                  // A failed server-side logout must not trap the user in the app.
                }
                controller.signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserSession session) {
    final trialDays = session.trialDaysRemaining;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: const BoxDecoration(gradient: AppTheme.logoGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  session.initials,
                  style: AppTheme.display(size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.display(size: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.email,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(size: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trialDays != null
                  ? '${session.tier.label} · $trialDays days left'
                  : session.tier.label,
              style: AppTheme.display(size: 11.5, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget screen,
    bool highlight = false,
  }) {
    final color = highlight ? AppTheme.coralPrimary : AppTheme.darkText;

    return ListTile(
      leading: Icon(icon, size: 21, color: color),
      title: Text(
        label,
        style: AppTheme.display(
          size: 14,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
      onTap: () {
        // Close the drawer first so the push animates from the shell, not from
        // behind the panel.
        Navigator.pop(context);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Divider(height: 1, color: AppTheme.hairline),
      );
}
