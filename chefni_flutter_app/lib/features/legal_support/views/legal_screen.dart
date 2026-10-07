import 'package:flutter/material.dart';
import '../../../core/models/session_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import 'legal_document_screen.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  bool _deleting = false;

  void _openDocument(LegalDocumentKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalDocumentScreen(kind: kind)),
    );
  }

  void _showSupportSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.bgWhite,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Need a hand?', style: AppTheme.display(size: 17)),
              const SizedBox(height: 10),
              Text(
                'Email support@chefni.com and our team will get back to you '
                'within one business day. Include your account email and a '
                'screenshot if something looks wrong.',
                style: AppTheme.body(size: 13.5, color: AppTheme.mutedText, height: 1.55),
              ),
              const SizedBox(height: 18),
              ChefniPrimaryButton(
                label: 'Close',
                color: AppTheme.tealPrimary,
                glow: false,
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext dialogContext) async {
    Navigator.pop(dialogContext);
    setState(() => _deleting = true);

    try {
      await ServiceScope.of(context).auth.deleteAccount();
      if (!mounted) return;
      SessionScope.of(context).signOut();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      showApiError(context, e);
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete account & erase data?',
          style: AppTheme.display(size: 17, color: AppTheme.alertRed),
        ),
        content: Text(
          'In compliance with Apple guidelines and Google Play policy, deleting '
          'your account permanently removes your private recipes, saved reels and '
          'personal data within 30 days.',
          style: AppTheme.body(size: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTheme.display(
                size: 13,
                weight: FontWeight.w700,
                color: AppTheme.mutedText,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _deleteAccount(ctx),
            child: Text(
              'Confirm delete',
              style: AppTheme.display(size: 13.5, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        title: Text('Legal & privacy', style: AppTheme.display(size: 19)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          _buildLinkTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: AppTheme.tealPrimary,
            title: 'Privacy policy',
            subtitle: 'GDPR, CCPA and App Store compliant data safety',
            onTap: () => _openDocument(LegalDocumentKind.privacyPolicy),
          ),
          const SizedBox(height: 10),
          _buildLinkTile(
            icon: Icons.gavel_outlined,
            iconColor: AppTheme.coralPrimary,
            title: 'Terms of service & EULA',
            subtitle: 'End user licence agreement and AI content rights',
            onTap: () => _openDocument(LegalDocumentKind.terms),
          ),
          const SizedBox(height: 10),
          _buildLinkTile(
            icon: Icons.help_outline,
            iconColor: AppTheme.accentGold,
            title: 'Help & support centre',
            subtitle: 'Contact support or browse FAQs',
            onTap: _showSupportSheet,
          ),
          const SizedBox(height: 28),
          Text(
            'User rights & data privacy',
            style: AppTheme.display(size: 15, color: AppTheme.alertRed),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.alertRed.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.alertRed.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete account & erase all personal data',
                  style: AppTheme.display(size: 14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Per Apple and Play Store guidelines, you can request full erasure '
                  'of your account and private video data at any time.',
                  style: AppTheme.body(
                    size: 12.5,
                    color: AppTheme.mutedText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.alertRed,
                    side: const BorderSide(color: AppTheme.alertRed, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      _deleting ? null : () => _showDeleteAccountDialog(context),
                  icon: _deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.alertRed),
                        )
                      : const Icon(Icons.delete_forever, size: 18),
                  label: Text(
                    _deleting ? 'Deleting…' : 'Request account deletion',
                    style: AppTheme.display(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: AppTheme.alertRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ChefniCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTheme.display(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppTheme.mutedText),
        ],
      ),
    );
  }
}
