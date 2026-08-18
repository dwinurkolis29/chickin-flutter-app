import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_wrapper.dart';
import 'package:recording_app/core/auth/auth_service.dart';
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

    try {
      final authService = context.read<AuthService>();
      authService.signOut().whenComplete(() {});
      // AuthWrapper reaktif — tidak perlu navigate manual.
    } catch (_) {}
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
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper()));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;
    final isLastPage = _currentIndex == onboardingItems.length - 1;

    Widget content = Column(
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
          transitionBuilder:
              (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              ),
          child:
              isLastPage
                  ? _buildStartButton(textTheme, colorScheme)
                  : _buildNavButtons(textTheme, colorScheme, isWideScreen ? 480 : size.width),
        ),
      ],
    );

    if (isWideScreen) {
      content = Center(
        child: Container(
          width: 480,
          height: 800,
          margin: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: content,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isWideScreen ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : colorScheme.surface,
      body: SafeArea(
        child: content,
      ),
    );
  }

  /// Full-width START button — last page only
  Widget _buildStartButton(TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      key: const ValueKey('start'),
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _finishOnboarding,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          child: Text(
            'START',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimary,
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
  Widget _buildNavButtons(TextTheme textTheme, ColorScheme colorScheme, double screenWidth) {
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
                foregroundColor: colorScheme.primary.withValues(alpha: 0.65),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                overlayColor: colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: Text(
                'SKIP',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary.withValues(alpha: 0.65),
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
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'NEXT',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
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
