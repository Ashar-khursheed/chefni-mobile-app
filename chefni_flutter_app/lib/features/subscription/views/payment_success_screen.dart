import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chefni_ui.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, required this.tierName});

  final String tierName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(
                    color: AppTheme.successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 22),
                Text('Trial started!', style: AppTheme.display(size: 21)),
                const SizedBox(height: 8),
                Text(
                  "You're on $tierName free for 14 days. "
                  "We'll remind you 3 days before it ends.",
                  textAlign: TextAlign.center,
                  style: AppTheme.body(size: 14, color: AppTheme.mutedText, height: 1.5),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: 220,
                  child: ChefniPrimaryButton(
                    label: 'Back to Chefni',
                    color: AppTheme.tealPrimary,
                    glow: false,
                    onPressed: () =>
                        Navigator.of(context).popUntil((route) => route.isFirst),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
