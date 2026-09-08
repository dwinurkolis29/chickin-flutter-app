import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/period/data/models/harvest_record.dart';

/// Banner alert di Dashboard untuk memantau sisa ayam pasca-penjarangan (panen parsial).
/// Otomatis muncul selama 72 jam pertama setelah panen parsial terakhir.
class PostThinningStressAlert extends StatefulWidget {
  final HarvestRecord lastPartialHarvest;

  const PostThinningStressAlert({super.key, required this.lastPartialHarvest});

  @override
  State<PostThinningStressAlert> createState() =>
      _PostThinningStressAlertState();
}

class _PostThinningStressAlertState extends State<PostThinningStressAlert> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final numFmt = NumberFormat.decimalPattern('id_ID');

    final harvest = widget.lastPartialHarvest;
    final hoursAgo = DateTime.now().difference(harvest.date).inHours;
    final daysAgo = DateTime.now().difference(harvest.date).inDays;

    final String timeAgoText =
        hoursAgo < 1
            ? 'Baru saja'
            : (hoursAgo < 24 ? '$hoursAgo jam lalu' : '$daysAgo hari lalu');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Pemulihan Pasca Penjarangan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.pillRadius,
                                ),
                              ),
                              child: Text(
                                timeAgoText,
                                style: tt.labelSmall?.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dipanen ${numFmt.format(harvest.chicks)} ekor (${harvest.weightKg.toStringAsFixed(1)} kg). Sisa ayam butuh pantauan ekstra.',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PANDUAN MITIGASI RISIKO STRES & BIOSEKURITI:',
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTipRow(
                    context,
                    icon: Icons.medication_liquid_rounded,
                    title: 'Anti-Stres & Elektrolit',
                    desc:
                        'Berikan multivitamin (terutama Vit C) atau elektrolit di air minum selama 48 jam untuk meredakan stres akibat proses tangkap.',
                  ),
                  const SizedBox(height: 8),
                  _buildTipRow(
                    context,
                    icon: Icons.restaurant_rounded,
                    title: 'Pantau Konsumsi Pakan (*Feed Intake*)',
                    desc:
                        'Jika konsumsi pakan sisa ayam anjlok drastis hari ini, pastikan pencahayaan cukup dan pakan digoyang agar memicu nafsu makan.',
                  ),
                  const SizedBox(height: 8),
                  _buildTipRow(
                    context,
                    icon: Icons.air_rounded,
                    title: 'Suhu & Ventilasi Kandang',
                    desc:
                        'Karena kepadatan berkurang, suhu kandang bisa lebih dingin di malam hari. Sesuaikan tirai dan kipas agar sisa ayam tidak kedinginan.',
                  ),
                  const SizedBox(height: 8),
                  _buildTipRow(
                    context,
                    icon: Icons.health_and_safety_outlined,
                    title: 'Disinfeksi Pasca Panen',
                    desc:
                        'Semprot disinfektan ringan di lorong depan dan area yang sempat dilalui tim tangkap untuk mencegah masuknya bibit penyakit.',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                desc,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
