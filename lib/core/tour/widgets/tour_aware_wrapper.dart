import 'package:flutter/material.dart';

/// Wrapper untuk widget yang ingin ditandai dalam tour.
/// Berguna untuk mendapatkan posisi dan ukuran widget di layar.
class TourAwareWrapper extends StatelessWidget {
  final GlobalKey tourKey;
  final Widget child;

  const TourAwareWrapper({
    super.key,
    required this.tourKey,
    required this.child,
  });

  static Rect? getRect(GlobalKey key) {
    if (key.currentContext == null || !key.currentContext!.mounted) return null;

    try {
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return null;

      // RenderTransform (seperti animasi FAB) bisa belum selesai layout
      // meski hasSize sudah true. try-catch menangkap race condition itu.
      final translation = renderBox.localToGlobal(Offset.zero);
      return translation & renderBox.size;
    } catch (_) {
      // Kembalikan null — overlay tidak akan tampil di frame ini.
      // Frame berikutnya widget sudah stabil dan akan muncul dengan benar.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: tourKey,
      child: child,
    );
  }
}
