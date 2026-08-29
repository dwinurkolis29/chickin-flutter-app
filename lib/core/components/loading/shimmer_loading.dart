import 'package:flutter/material.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';

/// Widget dasar Shimmer Box untuk efek skeleton loading yang responsif & adaptif terhadap tema
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const ShimmerLoading.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? cs.surfaceContainerHighest.withValues(alpha: 0.6)
        : cs.surfaceContainerHigh;
    final highlightColor = isDark
        ? cs.surfaceContainer.withValues(alpha: 0.3)
        : cs.surfaceContainerLowest;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cs.surface,
          shape: shape,
          borderRadius: shape == BoxShape.circle
              ? null
              : (borderRadius ?? BorderRadius.circular(AppTheme.rowRadius)),
        ),
      ),
    );
  }
}

/// Skeleton loader untuk kartu periode (Hero Active Period + List Period Card)
class PeriodCardSkeleton extends StatelessWidget {
  const PeriodCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const ShimmerLoading.circular(size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ShimmerLoading(width: 140, height: 16),
                    const Spacer(),
                    ShimmerLoading(
                      width: 60,
                      height: 20,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const ShimmerLoading(width: 180, height: 12),
                const SizedBox(height: 6),
                const ShimmerLoading(width: 110, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const ShimmerLoading(width: 18, height: 18),
        ],
      ),
    );
  }
}

/// Skeleton loader untuk tabel data recording harian
class TableSkeleton extends StatelessWidget {
  final int rowCount;
  const TableSkeleton({super.key, this.rowCount = 5});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const ShimmerLoading.circular(size: 36),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(width: 120, height: 16),
                      SizedBox(height: 4),
                      ShimmerLoading(width: 80, height: 11),
                    ],
                  ),
                ],
              ),
              ShimmerLoading(
                width: 70,
                height: 24,
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Header Kolom Tabel Skeleton
          ShimmerLoading(
            width: double.infinity,
            height: 32,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),

          // Baris Data
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount,
            separatorBuilder: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Divider(height: 1),
            ),
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ShimmerLoading(
                      width: 44,
                      height: 20,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Expanded(
                    flex: 3,
                    child: Center(child: ShimmerLoading(width: 55, height: 14)),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Center(child: ShimmerLoading(width: 45, height: 14)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ShimmerLoading(
                        width: 40,
                        height: 18,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader untuk Laporan Ringkasan Periode (Hero IP + 4 Key Metrics Grid + Chart + Insights)
class ReportSkeleton extends StatelessWidget {
  const ReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hero IP Header Card
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ShimmerLoading(width: 160, height: 22),
                    const ShimmerLoading.circular(size: 32),
                  ],
                ),
                const SizedBox(height: 8),
                const ShimmerLoading(width: 180, height: 12),
                const SizedBox(height: 16),

                // Hero IP Box Skeleton
                ShimmerLoading(
                  width: double.infinity,
                  height: 110,
                  borderRadius: BorderRadius.circular(14),
                ),
                const SizedBox(height: 16),

                // 3 Quick Metrics Pill Skeleton
                Row(
                  children: List.generate(
                    3,
                    (_) => Expanded(
                      child: Column(
                        children: const [
                          ShimmerLoading(width: 50, height: 18),
                          SizedBox(height: 4),
                          ShimmerLoading(width: 60, height: 11),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. 4 Key Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.38,
            children: List.generate(
              4,
              (_) => AppCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const ShimmerLoading(width: 65, height: 12),
                        ShimmerLoading(
                          width: 40,
                          height: 16,
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        ),
                      ],
                    ),
                    const ShimmerLoading(width: 70, height: 18),
                    const ShimmerLoading(width: 90, height: 10),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. FCR Trend Chart Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    ShimmerLoading.circular(size: 28),
                    SizedBox(width: 10),
                    ShimmerLoading(width: 140, height: 16),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ShimmerLoading(
                      width: double.infinity,
                      height: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Insight Card Skeleton
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    ShimmerLoading.circular(size: 28),
                    SizedBox(width: 10),
                    ShimmerLoading(width: 180, height: 16),
                  ],
                ),
                const SizedBox(height: 14),
                ShimmerLoading(
                  width: double.infinity,
                  height: 48,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 8),
                ShimmerLoading(
                  width: double.infinity,
                  height: 48,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader untuk Layar Beranda (Dashboard) lengkap
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const ShimmerLoading.circular(size: 44),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerLoading(width: 120, height: 16),
                    SizedBox(height: 6),
                    ShimmerLoading(width: 160, height: 12),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // 1. Population Section Skeleton
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const ShimmerLoading(width: 130, height: 16),
                          ShimmerLoading(
                            width: 60,
                            height: 20,
                            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ShimmerLoading(
                              width: double.infinity,
                              height: 64,
                              borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ShimmerLoading(
                              width: double.infinity,
                              height: 64,
                              borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // 2. Statistics Section Skeleton (Flex 3 : 2)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              ShimmerLoading(width: 100, height: 16),
                              SizedBox(height: 16),
                              ShimmerLoading(width: double.infinity, height: 60),
                              SizedBox(height: 16),
                              ShimmerLoading(width: 70, height: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Expanded(
                              child: AppCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    ShimmerLoading(width: 50, height: 12),
                                    ShimmerLoading(width: 40, height: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: AppCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    ShimmerLoading(width: 40, height: 12),
                                    ShimmerLoading(width: 40, height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Table Skeleton
                const TableSkeleton(rowCount: 4),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
