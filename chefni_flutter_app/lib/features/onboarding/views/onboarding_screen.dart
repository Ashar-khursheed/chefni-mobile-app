import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chefni_ui.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinishOnboarding;

  const OnboardingScreen({super.key, required this.onFinishOnboarding});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'One video. One AI.',
      'subtitle': 'Turn any cooking video into a complete recipe — ingredients, steps, and cost — instantly.',
    },
    {
      'title': 'Reels that sell themselves',
      'subtitle': 'Chefni AI finds your best moment and turns it into a share-ready reel, captioned and branded.',
    },
    {
      'title': 'Instant Pantry & Costing',
      'subtitle': 'Scale ingredients to any weight instantly and track pantry items before they expire.',
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgOffWhite,
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR WITH SKIP BUTTON (Exact match to Screenshots 2 & 3)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24, top: 12),
                child: TextButton(
                  onPressed: widget.onFinishOnboarding,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // PAGE VIEW FOR SLIDES
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // DASHED ILLUSTRATION CONTAINER (Exact match to Screenshots 2 & 3)
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: AppTheme.cardBorder,
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: AppTheme.mutedText,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Onboarding illustration',
                                style: TextStyle(
                                  color: AppTheme.mutedText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // HEADLINE
                        Text(
                          page['title']!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.darkText,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // SUBTITLE
                        Text(
                          page['subtitle']!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.mutedText,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // PAGINATION DOTS (Red active pill, grey inactive dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final bool isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.coralPrimary : AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // BLUE "NEXT" BUTTON (Exact match to Screenshots 2 & 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ChefniPrimaryButton(
                label: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                color: AppTheme.tealPrimary,
                onPressed: _nextPage,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
