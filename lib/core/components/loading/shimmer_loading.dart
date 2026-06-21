import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget dasar Shimmer Box untuk efek skeleton loading
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const ShimmerLoading({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Skeleton loader untuk kartu periode (Period Card)
class PeriodCardSkeleton extends StatelessWidget {
  const PeriodCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            const ShimmerLoading(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(24))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerLoading(width: 140, height: 16),
                  const SizedBox(height: 8),
                  const ShimmerLoading(width: 80, height: 12),
                ],
              ),
            ),
            const ShimmerLoading(width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader untuk tabel baris data recording
class TableSkeleton extends StatelessWidget {
  final int rowCount;
  const TableSkeleton({Key? key, this.rowCount = 5}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerLoading(width: 120, height: 18),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (_) => const ShimmerLoading(width: 60, height: 14)),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rowCount,
              separatorBuilder: (_, __) => const SizedBox(height: 15),
              itemBuilder: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ShimmerLoading(width: 40, height: 14),
                  const ShimmerLoading(width: 50, height: 14),
                  const ShimmerLoading(width: 50, height: 14),
                  const ShimmerLoading(width: 40, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader untuk Laporan Ringkasan Periode (Header + Chart + Grid)
class ReportSkeleton extends StatelessWidget {
  const ReportSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          const ShimmerLoading(width: double.infinity, height: 140, borderRadius: BorderRadius.all(Radius.circular(16))),
          const SizedBox(height: 16),
          // Chart Section
          const ShimmerLoading(width: double.infinity, height: 240, borderRadius: BorderRadius.all(Radius.circular(16))),
          const SizedBox(height: 16),
          // Grid Section
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: List.generate(
              4,
              (_) => const ShimmerLoading(width: double.infinity, height: 80, borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }
}
