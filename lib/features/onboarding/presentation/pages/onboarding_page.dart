import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_rounded_button.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../auth/presentation/pages/auth_page.dart';
import '../widgets/phnom_penh_illustrations.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback? onFinish;

  const OnboardingPage({super.key, this.onFinish});

  static const String prefKey = 'seen_onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      title: 'Welcome to EduNet!',
      description:
          'Connect, share, and learn with students across city and province. Your academic journey starts here.',
      illustrationType: _IllustrationType.skyline,
      badgeText: 'BUILD BRIGHT, CAMBODIA',
    ),
    _OnboardingItem(
      title: 'Learn & Collaborate',
      description:
          'Discover study materials, join student discussions, and share academic insights with your peers.',
      illustrationType: _IllustrationType.monument,
      badgeText: 'COMMUNITY & KNOWLEDGE',
    ),
    _OnboardingItem(
      title: 'Stay Organized & Grow',
      description:
          'Manage your academic schedule, track assignments, and achieve your educational goals together.',
      illustrationType: _IllustrationType.palace,
      badgeText: 'SCHEDULE & SUCCESS',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingPage.prefKey, true);

    if (!mounted) return;

    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim1, anim2) => const AuthPage(),
          transitionsBuilder: (context, anim1, anim2, child) =>
              FadeTransition(opacity: anim1, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: GradientBackground(
        showFloatingOrbs: true,
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand mark
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'EduNet',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Skip button
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: _completeOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: GestureDetector(
                          onTap: _completeOnboarding,
                          child: Text(
                            'Skip',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 60),
                  ],
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),

                          // Landmark Illustration
                          SizedBox(
                            height: size.height * 0.35,
                            child: Center(
                              child: _buildIllustration(item.illustrationType, size.width * 0.72),
                            ),
                          ),

                          const Spacer(),

                          // Badge Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.cardSubtle,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? AppColors.darkDivider : AppColors.divider,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              item.badgeText,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Title
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Description
                          Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              height: 1.55,
                            ),
                          ),

                          const SizedBox(height: 28),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Area: Indicators & Navigation Button
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                child: Column(
                  children: [
                    // Page indicator dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (idx) {
                        final isActive = idx == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                                : (isDark ? AppColors.darkDivider : AppColors.divider),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // Next / Get Started Button
                    CustomRoundedButton(
                      text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      onPressed: _nextPage,
                      variant: ButtonVariant.primary,
                      height: 56,
                      borderRadius: 28,
                      icon: _currentPage == _pages.length - 1
                          ? const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20)
                          : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(_IllustrationType type, double size) {
    switch (type) {
      case _IllustrationType.skyline:
        return PhnomPenhSkylineIllustration(size: size);
      case _IllustrationType.monument:
        return IndependenceMonumentIllustration(size: size);
      case _IllustrationType.palace:
        return RoyalPalaceIllustration(size: size);
    }
  }
}

enum _IllustrationType { skyline, monument, palace }

class _OnboardingItem {
  final String title;
  final String description;
  final _IllustrationType illustrationType;
  final String badgeText;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.illustrationType,
    required this.badgeText,
  });
}
