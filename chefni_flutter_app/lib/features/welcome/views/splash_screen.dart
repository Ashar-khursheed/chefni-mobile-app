import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chefni_logo_widget.dart';
import '../../../core/widgets/chefni_ui.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const SplashScreen({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.splashGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // OFFICIAL CHEFNI LOGO BADGE (Exact match to official brand logo)
                  const ChefniLogoWidget(width: 220, isDark: true),
                  const SizedBox(height: 32),

                  // TAGLINE & SUBTITLE
                  const Text(
                    'FINE. FAST. FAB.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppTheme.skyBlueAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Solely Premium for You',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.normal,
                    ),
                  ),

                  const Spacer(),

                  // GET STARTED CORAL PILL BUTTON
                  ChefniPrimaryButton(
                    label: 'Get Started',
                    onPressed: onGetStarted,
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
