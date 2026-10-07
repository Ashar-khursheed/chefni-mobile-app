import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/session_scope.dart';
import '../../../core/models/user_session.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chefni_ui.dart';
import '../../inventory/views/inventory_screen.dart';
import '../../legal_support/views/legal_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../recipe_calculator/views/calculator_screen.dart';
import '../../shopping_list/views/shopping_list_screen.dart';
import '../../subscription/views/paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _pushKey = 'chefni_pref_push_notifications';
  static const _offlineKey = 'chefni_pref_offline_downloads';

  bool _pushNotifications = true;
  bool _offlineDownloads = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushNotifications = prefs.getBool(_pushKey) ?? true;
      _offlineDownloads = prefs.getBool(_offlineKey) ?? true;
    });
  }

  Future<void> _setPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Revokes the token server-side before clearing the local session, so the
  /// credential cannot be reused.
  Future<void> _logout(SessionController controller) async {
    setState(() => _isLoggingOut = true);
    await ServiceScope.of(context).auth.logout();
    if (!mounted) return;
    controller.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final controller = SessionScope.of(context);
    final session = controller.session;

    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        title: Text('Settings', style: AppTheme.display(size: 19)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          _buildAccountCard(session),
          const SizedBox(height: 22),
          _sectionHeader('ACCOUNT'),
          _group([
            _row('Edit profile', onTap: () => _open(const ProfileScreen())),
            _row(
              'Subscription',
              value: session.tier.label,
              onTap: () => _open(const PaywallScreen()),
            ),
            _row('Payment methods',
                onTap: () => _open(const PaywallScreen()), isLast: true),
          ]),
          const SizedBox(height: 22),
          _sectionHeader('KITCHEN'),
          _group([
            _row('Shopping list', onTap: () => _open(const ShoppingListScreen())),
            _row('Pantry inventory', onTap: () => _open(const InventoryScreen())),
            _row('Recipe cost calculator',
                onTap: () => _open(const CalculatorScreen()), isLast: true),
          ]),
          const SizedBox(height: 22),
          _sectionHeader('PREFERENCES'),
          _group([
            _switchRow(
              'Push notifications',
              _pushNotifications,
              (v) {
                setState(() => _pushNotifications = v);
                _setPreference(_pushKey, v);
              },
            ),
            _row(
              'Language',
              value: 'English',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('More languages are coming soon.',
                      style: AppTheme.body(size: 13.5, color: Colors.white)),
                  backgroundColor: AppTheme.darkText,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            _switchRow(
              'Offline downloads',
              _offlineDownloads,
              (v) {
                setState(() => _offlineDownloads = v);
                _setPreference(_offlineKey, v);
              },
              isLast: true,
            ),
          ]),
          const SizedBox(height: 22),
          _sectionHeader('SUPPORT'),
          _group([
            _row('Help center', onTap: () => _open(const LegalScreen())),
            _row('Contact us', onTap: () => _open(const LegalScreen())),
            _row('Terms & privacy',
                onTap: () => _open(const LegalScreen()), isLast: true),
          ]),
          const SizedBox(height: 26),
          OutlinedButton(
            onPressed: _isLoggingOut ? null : () => _logout(controller),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.coralPrimary,
              side: const BorderSide(color: AppTheme.inputBorder, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _isLoggingOut ? 'Logging out…' : 'Log out',
              style: AppTheme.display(
                size: 14,
                weight: FontWeight.w700,
                color: AppTheme.coralPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(UserSession session) {
    return ChefniCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              gradient: AppTheme.logoGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              session.initials,
              style: AppTheme.display(size: 17, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.name, style: AppTheme.display(size: 16)),
                const SizedBox(height: 3),
                Text(
                  session.email,
                  style: AppTheme.body(size: 12.5, color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
          if (session.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.tintTeal,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'ADMIN',
                style: AppTheme.display(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppTheme.tealDeep,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTheme.display(
          size: 12,
          weight: FontWeight.w700,
          color: AppTheme.mutedText,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _group(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }

  Widget _row(
    String label, {
    String? value,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppTheme.hairline)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTheme.body(size: 14.5))),
            if (value != null)
              Text(
                value,
                style: AppTheme.body(size: 13.5, color: AppTheme.mutedText),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 20, color: AppTheme.mutedText),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.hairline)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTheme.body(size: 14.5))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
