import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chefni_logo_widget.dart';
import '../../../core/widgets/chefni_ui.dart';
import 'otp_verify_screen.dart';
import 'register_screen.dart';

/// Step one of sign-in: collect a number and have a code sent to it. There is
/// no password — the code is the credential.
class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key, required this.onAuthenticated});

  final ValueChanged<UserSession> onAuthenticated;

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Local Pakistani numbers are 10 digits after the leading zero.
  bool get _looksComplete =>
      _phoneController.text.replaceAll(RegExp(r'\D'), '').length >= 10;

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ServiceScope.of(context).auth.requestOtp(phone);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            phone: phone,
            onAuthenticated: widget.onAuthenticated,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            const Center(child: ChefniLogoWidget(width: 170)),
            const SizedBox(height: 34),
            Text('Enter your number', style: AppTheme.display(size: 24)),
            const SizedBox(height: 8),
            Text(
              'We’ll text you a 6-digit code. No password to remember.',
              style: AppTheme.body(size: 13.5, color: AppTheme.mutedText, height: 1.5),
            ),
            const SizedBox(height: 22),
            _buildPhoneField(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTheme.body(size: 12.5, color: AppTheme.alertRed),
              ),
            ],
            const SizedBox(height: 18),
            ChefniPrimaryButton(
              label: _isSubmitting ? 'Sending…' : 'Send code',
              onPressed: _isSubmitting || !_looksComplete ? null : _sendCode,
            ),
            const SizedBox(height: 14),
            Text(
              'By continuing you agree to our Terms and Privacy Policy.',
              textAlign: TextAlign.center,
              style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
            ),
            const SizedBox(height: 26),
            _buildTrialCard(),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RegisterScreen(
                      onAuthenticated: widget.onAuthenticated,
                    ),
                  ),
                ),
                child: Text(
                  'Use email instead',
                  style: AppTheme.body(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: AppTheme.coralPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppTheme.inputBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Text('🇵🇰 +92', style: AppTheme.display(size: 14, weight: FontWeight.w800)),
          const SizedBox(width: 10),
          Container(width: 1, height: 24, color: AppTheme.inputBorder),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              onChanged: (_) => setState(() {}),
              style: AppTheme.body(size: 15, weight: FontWeight.w600),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '312 4567890',
                hintStyle: AppTheme.body(size: 15, color: AppTheme.mutedText),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.tintTeal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your 14-day trial',
              style: AppTheme.display(size: 13.5, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '3 AI video extractions, 1080p reel export, and an offline recipe '
            'library — free, no card required.',
            style: AppTheme.body(size: 12, color: AppTheme.mutedText, height: 1.5),
          ),
        ],
      ),
    );
  }
}
