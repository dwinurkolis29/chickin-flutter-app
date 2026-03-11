import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/features/auth/presentation/login.dart';
import 'package:recording_app/features/onboarding/data/onboarding_data.dart';
import 'package:recording_app/features/onboarding/presentation/widgets/onboarding_item.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Sync indicator live during drag swipe (not just on snap)
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentIndex) {
        setState(() => _currentIndex = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    await Hive.box('onboarding').put('seen', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLastPage = _currentIndex == onboardingItems.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // PageView — swipe kiri/kanan untuk previous/next
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingItems.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return OnboardingItemWidget(
                    item: onboardingItems[index],
                    currentIndex: _currentIndex,
                    totalCount: onboardingItems.length,
                  );
                },
              ),
            ),

            // Bottom action area — animates between nav and start
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              ),
              child: isLastPage
                  ? _buildStartButton(textTheme)
                  : _buildNavButtons(textTheme, screenWidth),
            ),
          ],
        ),
      ),
    );
  }

  /// Full-width START button — last page only
  Widget _buildStartButton(TextTheme textTheme) {
    return Padding(
      key: const ValueKey('start'),
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _finishOnboarding,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          child: Text(
            'START',
            style: textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// SKIP (left plain text) + NEXT pill button (right, ~40% screen width)
  Widget _buildNavButtons(TextTheme textTheme, double screenWidth) {
    return Padding(
      key: const ValueKey('nav'),
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SKIP — no background, no border, pure text
          SizedBox(
            height: 54,
            child: TextButton(
              onPressed: _finishOnboarding,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary.withValues(alpha: 0.65),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                overlayColor: AppColors.primary.withValues(alpha: 0.08),
              ),
              child: Text(
                'SKIP',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // NEXT — pill button, width proportional to screen (~40%)
          SizedBox(
            width: screenWidth * 0.40,
            height: 54,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'NEXT',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}