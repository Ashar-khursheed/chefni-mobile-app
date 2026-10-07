import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CookingModeScreen extends StatefulWidget {
  final String recipeTitle;
  final List<String> steps;

  const CookingModeScreen({
    super.key,
    this.recipeTitle = 'Authentic Mughlai Mutton Karahi',
    this.steps = const [
      '1. Heat 4 tbsp oil in pan over medium flame for 3 minutes.',
      '2. Add 1 kg mutton meat and sauté for 10 minutes until golden brown.',
      '3. Add tomatoes, ginger, and 2.5 tbsp Karahi Spice Mix.',
      '4. Cover and simmer on low heat for 15 minutes.',
      '5. Garnish with fresh green chillies and ginger juliennes, serve hot.',
    ],
  });

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  int currentStep = 0;

  // Active step timer variables
  Timer? _stepTimer;
  int _timerSecondsRemaining = 0;
  bool _isTimerRunning = false;

  void _startStepTimer(int minutes) {
    _stepTimer?.cancel();
    setState(() {
      _timerSecondsRemaining = minutes * 60;
      _isTimerRunning = true;
    });

    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSecondsRemaining > 0) {
        setState(() => _timerSecondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _isTimerRunning = false);
        _showTimerAlert();
      }
    });
  }

  void _showTimerAlert() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCocoaCard,
        title: const Row(
          children: [
            Icon(Icons.alarm_on, color: AppTheme.primaryPink, size: 30),
            SizedBox(width: 10),
            Text('Timer Finished! 🔔', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Your cooking step timer has completed. Check your dish!', style: TextStyle(color: AppTheme.warmCream)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK, Got It!'),
          ),
        ],
      ),
    );
  }

  String _formatTimer(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepText = widget.steps[currentStep];

    return Scaffold(
      backgroundColor: const Color(0xFF1F0F17), // Deep dark high-contrast kitchen background
      appBar: AppBar(
        title: const Text('Hands-Free Cooking Mode 🍳'),
        backgroundColor: const Color(0xFF1F0F17),
        actions: [
          // SCREEN WAKE LOCK INDICATOR
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                SizedBox(width: 4),
                Text('Screen ON 💡', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // STEP PROGRESS COUNTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${currentStep + 1} of ${widget.steps.length}',
                  style: const TextStyle(color: AppTheme.skyBlueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                LinearProgressIndicator(
                  value: (currentStep + 1) / widget.steps.length,
                  color: AppTheme.primaryPink,
                  backgroundColor: AppTheme.darkCocoaSurface,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // BIG FONT STEP INSTRUCTION BOX
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.darkCocoaCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryPink, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stepText,
                      style: const TextStyle(
                        fontSize: 26, // Extra big font for easy kitchen reading from distance!
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // IN-STEP TIMER BUTTON (Simulate detection of 15 min or 3 min timers)
                    if (stepText.contains('15 minutes') || stepText.contains('3 minutes') || stepText.contains('10 minutes')) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTimerRunning ? Colors.amber : AppTheme.primaryPink,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        onPressed: () {
                          int mins = 15;
                          if (stepText.contains('3 minutes')) mins = 3;
                          if (stepText.contains('10 minutes')) mins = 10;
                          _startStepTimer(mins);
                        },
                        icon: const Icon(Icons.timer, size: 24),
                        label: Text(
                          _isTimerRunning
                              ? 'Timer Running: ${_formatTimer(_timerSecondsRemaining)}'
                              : 'Tap to Start Step Timer ⏱️',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // NAVIGATION BUTTONS (Previous / Next Step)
            Row(
              children: [
                if (currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: AppTheme.warmCream),
                      ),
                      onPressed: () => setState(() => currentStep--),
                      child: const Text('Previous Step', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                if (currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: AppTheme.primaryPink,
                    ),
                    onPressed: () {
                      if (currentStep < widget.steps.length - 1) {
                        setState(() => currentStep++);
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Dish Finished! Bon Appétit from Chefni!'),
                            backgroundColor: AppTheme.primaryPink,
                          ),
                        );
                      }
                    },
                    child: Text(
                      currentStep == widget.steps.length - 1 ? 'Finish Cooking 🎉' : 'Next Step ➔',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
