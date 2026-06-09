import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/features/recording/data/models/fcr_data.dart';
import 'package:recording_app/core/theme/app_colors.dart';

class FCRDataCard extends StatelessWidget {
  final List<FCRData> fcrData;
  final int maxWeeks;

  const FCRDataCard({
    Key? key,
    required this.fcrData,
    this.maxWeeks = 5,
  }) : super(key: key);

  _FCRStatus _getStatus(double fcr) {
    if (fcr <= 1.8) return _FCRStatus.good;
    if (fcr <= 2.19) return _FCRStatus.warn;
    return _FCRStatus.bad;
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat fmt = NumberFormat.decimalPattern('id_ID');
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'FCR Mingguan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (fcrData.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Text(
              'Belum ada data FCR untuk ditampilkan.',
              style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    _expanded ? _controller.forward() : _controller.reverse();
  }

  Color get _badgeBackground {
    switch (widget.status) {
      case _FCRStatus.good: return const Color(0xFFEAF3DE);
      case _FCRStatus.warn: return const Color(0xFFFAEEDA);
      case _FCRStatus.bad:  return const Color(0xFFFCEBEB);
    }
  }

  Color get _badgeText {
    switch (widget.status) {
      case _FCRStatus.good: return const Color(0xFF27500A);
      case _FCRStatus.warn: return const Color(0xFF633806);
      case _FCRStatus.bad:  return const Color(0xFF791F1F);
    }
  }

  Color get _barColor {
    switch (widget.status) {
      case _FCRStatus.good: return const Color(0xFF639922);
      case _FCRStatus.warn: return const Color(0xFFBA7517);
      case _FCRStatus.bad:  return const Color(0xFFE24B4A);
    }
  }

  IconData get _badgeIcon {
    switch (widget.status) {
      case _FCRStatus.good: return Icons.check_rounded;
      case _FCRStatus.warn: return Icons.warning_amber_rounded;
      case _FCRStatus.bad:  return Icons.close_rounded;
    }
  }

  double get _barProgress {
    return (widget.data.fcr / 2.2).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = widget.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Text(
                    'Minggu ${widget.weekNumber}',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _badgeBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_badgeIcon, size: 12, color: _badgeText),
                        const SizedBox(width: 4),
                        Text(
                          'FCR ${widget.fmt.format(widget.data.fcr)}',
                          style: tt.labelMedium?.copyWith(color: _badgeText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('FCR', style: tt.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface
                                    )),
                                    Text(
                                      '${widget.fmt.format(widget.data.fcr)} / 1.8',
                                      style: tt.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: _barProgress,
                                    minHeight: 6,
                                    backgroundColor: cs.outlineVariant.withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'FCR ideal ≤ 1.8 — semakin rendah semakin efisien',
                                  style: tt.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.8,
                        children: [
                          _StatTile(
                            label: 'Total Pakan',
                            value: '${widget.fmt.format(widget.data.totalPakan)} kg',
                            textTheme: tt,
                          ),
                          _StatTile(
                            label: 'Sisa Ayam',
                            value: '${widget.fmt.format(widget.data.sisaAyam)} ekor',
                            textTheme: tt,
                          ),
                          _StatTile(
                            label: 'Berat Ayam',
                            value: '${widget.fmt.format(widget.data.beratAyam)} kg',
                            textTheme: tt,
                          ),
                          _StatTile(
                            label: 'FCR',
                            value: widget.fmt.format(widget.data.fcr),
                            textTheme: tt,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final TextTheme textTheme;

  const _StatTile({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}