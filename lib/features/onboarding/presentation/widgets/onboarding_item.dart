import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/features/onboarding/data/onboarding_data.dart';
import 'onboarding_indicator.dart';

class OnboardingItemWidget extends StatelessWidget {
  final OnboardingItem item;
  final int currentIndex;
  final int totalCount;

  const OnboardingItemWidget({
    super.key,
    required this.item,
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        // Illustration area — takes majority of screen
        Expanded(
          flex: 6,
          child: Center(
            child: Container(
              width: size.width * 0.65,
              height: size.width * 0.65,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(36),
              child: SvgPicture.asset(
                item.svgAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Indicator + Text area
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Indicator sits right above the title
                OnboardingIndicator(
                  count: totalCount,
                  currentIndex: currentIndex,
                ),

                const SizedBox(height: 28),

                // Title — large, bold, multi-line centered
                Text(
                  item.title,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 14),

                // Subtitle — muted, readable
                Text(
                  item.subtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}