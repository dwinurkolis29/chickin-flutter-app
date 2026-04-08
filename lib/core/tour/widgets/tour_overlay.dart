import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:recording_app/core/tour/widgets/tour_aware_wrapper.dart';

class TourOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final Widget tooltip;
  final VoidCallback onSkip;

  const TourOverlay({
    super.key,
    required this.targetKey,
    required this.tooltip,
    required this.onSkip,
  });

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _targetRect = TourAwareWrapper.getRect(widget.targetKey);
    _ticker = createTicker((_) {
      final rect = TourAwareWrapper.getRect(widget.targetKey);
      if (rect != null && rect != _targetRect) {
        setState(() => _targetRect = rect);
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_targetRect == null) return const SizedBox.expand();

    return LayoutBuilder(
      builder: (context, constraints) {
        // We defer grabbing the local rect to a small helper
        // Since LayoutBuilder gives us constraints but not an immediately usable RenderBox
        // during the first build, we will calculate local coordinates safely.
        final box = context.findRenderObject() as RenderBox?;
        final localTargetRect = box != null 
            ? _targetRect!.shift(box.globalToLocal(Offset.zero))
            : _targetRect!;
            
        final hole = localTargetRect.inflate(8);

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. VISUAL LAYER: Gelapkan layar & buat lubang
            IgnorePointer(
              ignoring: true, // Pastikan layer visual tidak memblokir apapun
              child: CustomPaint(
                painter: _InvertedPainter(localTargetRect),
              ),
            ),
            
            // 2. TACTILE LAYER: 4 Blocker di sekeliling lubang untuk menangkap tap di luar lubang
            // TOP
            if (hole.top > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: hole.top,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onSkip,
                  child: const SizedBox.expand(),
                ),
              ),
            
            // BOTTOM
            if (hole.bottom < constraints.maxHeight)
              Positioned(
                top: hole.bottom,
                left: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onSkip,
                  child: const SizedBox.expand(),
                ),
              ),
            
            // LEFT
            if (hole.left > 0)
              Positioned(
                top: hole.top > 0 ? hole.top : 0,
                bottom: hole.bottom < constraints.maxHeight ? constraints.maxHeight - hole.bottom : 0,
                left: 0,
                width: hole.left,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onSkip,
                  child: const SizedBox.expand(),
                ),
              ),
            
            // RIGHT
            if (hole.right < constraints.maxWidth)
              Positioned(
                top: hole.top > 0 ? hole.top : 0,
                bottom: hole.bottom < constraints.maxHeight ? constraints.maxHeight - hole.bottom : 0,
                right: 0,
                width: constraints.maxWidth - hole.right,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onSkip,
                  child: const SizedBox.expand(),
                ),
              ),

            // 3. TOOLTIP LAYER
            _buildTooltipPositioned(localTargetRect, constraints.maxHeight),
          ],
        );
      },
    );
  }

  Widget _buildTooltipPositioned(Rect localTargetRect, double maxHeight) {
    double top = localTargetRect.bottom + 12;
    double? bottom;
    
    // Jika tooltip tertutup layar, letakkan di atas target
    if (top + 150 > maxHeight) {
      bottom = maxHeight - localTargetRect.top + 12;
      top = 0;
    }

    return Positioned(
      top: top > 0 ? top : null,
      bottom: bottom,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: widget.tooltip,
        ),
      ),
    );
  }
}

class _InvertedPainter extends CustomPainter {
  final Rect localTargetRect;

  _InvertedPainter(this.localTargetRect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.75)
      ..style = PaintingStyle.fill;

    // Path untuk seluruh layar
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Path untuk cutout (area transparan di target)
    final cutoutPath = Path()..addRRect(
      RRect.fromRectAndRadius(
        localTargetRect.inflate(8), 
        const Radius.circular(8),
      ),
    );

    // Gabungkan path dengan operasi difference untuk membuat lubang
    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(_InvertedPainter oldDelegate) => oldDelegate.localTargetRect != localTargetRect;
}
