import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/recording/data/models/fcr_data.dart';

class FCRDataCard extends StatelessWidget {
  final List<FCRData> fcrData;
  final int maxWeeks;

  const FCRDataCard({
    super.key,
    required this.fcrData,
    this.maxWeeks = 5,
  });

  _FCRStatus _getStatus(double fcr) {
    if (fcr <= 1.8) return _FCRStatus.good;
    if (fcr <= 2.2) return _FCRStatus.warn;
    return _FCRStatus.bad;
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat fmt = NumberFormat.decimalPattern('id_ID');
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fcrData.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Belum ada data FCR mingguan untuk ditampilkan.',
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...fcrData.map((data) {
            final status = _getStatus(data.fcr);
            return _WeekCard(
              data: data,
              weekNumber: data.mingguKe,
              status: status,
              fmt: fmt,
              textTheme: textTheme,
            );
          }),
      ],
    );
  }
}

enum _FCRStatus { good, warn, bad }

class _WeekCard extends StatefulWidget {
  final FCRData data;
  final int weekNumber;
  final _FCRStatus status;
  final NumberFormat fmt;
  final TextTheme textTheme;

  const _WeekCard({
    required this.data,
    required this.weekNumber,
    required this.status,
    required this.fmt,
    required this.textTheme,
  });

  @override
  State<_WeekCard> createState() => _WeekCardState();
}

class _WeekCardState extends State<_WeekCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  String get _statusLabel {
    switch (widget.status) {
      case _FCRStatus.good:
        return 'Efisien';
      case _FCRStatus.warn:
        return 'Cukup';
      case _FCRStatus.bad:
        return 'Boros';
    }
  }

  String get _statusDescription {
    switch (widget.status) {
      case _FCRStatus.good:
        return 'Penggunaan pakan sangat efisien dan bobot ayam berkembang optimal.';
      case _FCRStatus.warn:
        return 'Rasio pakan mendekati batas toleransi. Periksa pakan tercecer atau suhu kandang.';
      case _FCRStatus.bad:
        return 'FCR tinggi (boros pakan). Segera periksa kesehatan ayam dan efisiensi ransum pakan.';
    }
  }

  Color get _statusBgColor {
    switch (widget.status) {
      case _FCRStatus.good:
        return AppColors.fcrGoodBg;
      case _FCRStatus.warn:
        return AppColors.fcrWarnBg;
      case _FCRStatus.bad:
        return AppColors.fcrBadBg;
    }
  }

  Color get _statusTextColor {
    switch (widget.status) {
      case _FCRStatus.good:
        return AppColors.fcrGoodText;
      case _FCRStatus.warn:
        return AppColors.fcrWarnText;
      case _FCRStatus.bad:
        return AppColors.fcrBadText;
    }
  }

  Color get _statusBarColor {
    switch (widget.status) {
      case _FCRStatus.good:
        return AppColors.fcrGoodBorder;
      case _FCRStatus.warn:
        return AppColors.fcrWarnBorder;
      case _FCRStatus.bad:
        return AppColors.fcrBadBorder;
    }
  }

  IconData get _statusIcon {
    switch (widget.status) {
      case _FCRStatus.good:
        return Icons.check_circle_rounded;
      case _FCRStatus.warn:
        return Icons.warning_amber_rounded;
      case _FCRStatus.bad:
        return Icons.error_outline_rounded;
    }
  }

  double get _barProgress {
    // Normalisasi visual progress (0.0 s.d. 1.0) dengan rentang max FCR 2.5
    return (widget.data.fcr / 2.5).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = widget.textTheme;
    final startDay = (widget.weekNumber - 1) * 7 + 1;
    final endDay = widget.weekNumber * 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── CARD HEADER (SELALU TERLIHAT) ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Informasi Minggu & Rentang Umur
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Minggu ${widget.weekNumber}',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Umur $startDay - $endDay Hari',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Badge Status FCR (Besar & Kontras Jelas)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusBgColor,
                        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, size: 16, color: _statusTextColor),
                          const SizedBox(width: 6),
                          Text(
                            'FCR ${widget.fmt.format(widget.data.fcr)} • $_statusLabel',
                            style: tt.labelMedium?.copyWith(
                              color: _statusTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Icon Panah Expand/Collapse
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: cs.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // ── DETAIL EXPANDED CONTENT ─────────────────────────────────
              SizeTransition(
                sizeFactor: _expandAnim,
                child: Column(
                  children: [
                    Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Banner Hero Nilai FCR & Progress Bar
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      'Nilai FCR',
                                      style: tt.bodyMedium?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: widget.fmt.format(widget.data.fcr),
                                            style: tt.headlineSmall?.copyWith(
                                              color: _statusTextColor,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' (Target: ≤ 1,80)',
                                            style: tt.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Progress Indicator Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _barProgress,
                                    minHeight: 8,
                                    backgroundColor: cs.outlineVariant.withValues(alpha: 0.4),
                                    valueColor: AlwaysStoppedAnimation<Color>(_statusBarColor),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Keterangan Evaluasi Peternak
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 14,
                                      color: _statusTextColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _statusDescription,
                                        style: tt.bodySmall?.copyWith(
                                          color: cs.onSurface,
                                          fontSize: 11.5,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3 Kartu Rincian Fisik Pakan & Bobot Ayam
                          _MetricTile(
                            icon: Icons.inventory_2_outlined,
                            iconColor: cs.primary,
                            iconBgColor: cs.secondaryContainer,
                            label: 'Total Pakan Dikonsumsi',
                            value: '${widget.fmt.format(widget.data.totalPakan)} kg',
                            subtitle: '${(widget.data.totalPakan / 50).toStringAsFixed(1)} sak (per 50 kg)',
                            textTheme: tt,
                          ),
                          const SizedBox(height: 8),
                          _MetricTile(
                            icon: Icons.scale_rounded,
                            iconColor: cs.primary,
                            iconBgColor: cs.secondaryContainer,
                            label: 'Total Bobot Ayam Hidup',
                            value: '${widget.fmt.format(widget.data.beratAyam)} kg',
                            subtitle: 'Akumulasi seluruh populasi',
                            textTheme: tt,
                          ),
                          const SizedBox(height: 8),
                          _MetricTile(
                            icon: Icons.groups_rounded,
                            iconColor: cs.primary,
                            iconBgColor: cs.secondaryContainer,
                            label: 'Sisa Ayam Hidup',
                            value: '${widget.fmt.format(widget.data.sisaAyam)} ekor',
                            subtitle: 'Populasi kandang aktif',
                            textTheme: tt,
                          ),
                          const SizedBox(height: 12),

                          // Catatan Rumus FCR
                          Center(
                            child: Text(
                              'Rumus: Total Pakan (kg) ÷ Total Bobot (kg) = FCR',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                                fontSize: 10.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
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
}

/// Widget baris metrik rincian pakan & bobot ayam dengan icon jelas dan teks kontras tinggi.
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String value;
  final String subtitle;
  final TextTheme textTheme;

  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),

          // Label dan Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Angka Nilai Besar & Jelas
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}