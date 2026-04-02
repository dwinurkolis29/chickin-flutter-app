import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card collapsible berisi detail teknis yang tidak perlu dilihat setiap kali.
/// Default: tersembunyi (collapsed). User expand sendiri jika butuh.
class ExpandableDetailCard extends StatefulWidget {
  final double totalBiomassKg;
  final double avgDailyGainGram;
  final double feedPerBird;
  final double weightGainKg;
  final int finalAvgWeightGram;

  const ExpandableDetailCard({
    super.key,
    required this.totalBiomassKg,
    required this.avgDailyGainGram,
    required this.feedPerBird,
    required this.weightGainKg,
    required this.finalAvgWeightGram,
  });

  @override
  State<ExpandableDetailCard> createState() => _ExpandableDetailCardState();
}

class _ExpandableDetailCardState extends State<ExpandableDetailCard>
    with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fmt = NumberFormat('#,###.##');

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header — selalu tampil, bisa di-tap
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Detail Teknis',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
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

          // Collapsible content
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Total Biomassa',
                        value: '${fmt.format(widget.totalBiomassKg)} kg',
                        icon: Icons.scale_outlined,
                      ),
                      _DetailRow(
                        label: 'Pertambahan Bobot Harian',
                        value: '${widget.avgDailyGainGram.toStringAsFixed(1)} g/hari',
                        icon: Icons.trending_up_rounded,
                      ),
                      _DetailRow(
                        label: 'Pakan per Ekor',
                        value: '${widget.feedPerBird.toStringAsFixed(3)} kg',
                        icon: Icons.set_meal_outlined,
                      ),
                      _DetailRow(
                        label: 'Pertambahan Bobot Total',
                        value: '${fmt.format(widget.weightGainKg)} kg',
                        icon: Icons.arrow_upward_rounded,
                      ),
                      _DetailRow(
                        label: 'Bobot Rata-rata Akhir',
                        value: '${NumberFormat("#,###").format(widget.finalAvgWeightGram)} g',
                        icon: Icons.monitor_weight_outlined,
                        isLast: true,
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary.withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
