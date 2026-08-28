import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';
import 'package:recording_app/features/cage/presentation/pages/form_cage.dart';

/// Halaman Profil Kandang yang berfokus pada visualisasi fasilitas fisik kandang,
/// skala kapasitas maksimal, dan spesifikasi konstruksi bangunan.
class CageProfile extends StatefulWidget {
  final bool isTab;
  const CageProfile({super.key, this.isTab = false});

  @override
  State<CageProfile> createState() => _CageProfileState();
}

class _CageProfileState extends State<CageProfile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CageController>().loadCageData();
      }
    });
  }

  void _showImageSourceBottomSheet(
    BuildContext context,
    CageController controller,
  ) {
    DialogHelper.showBottomSheet(
      context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.cardRadius),
        ),
      ),
      builder: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  controller.handleCageImageUpload(ImageSource.gallery);
                },
              ),
              Divider(
                height: 0,
                thickness: 0.5,
                indent: 16,
                endIndent: 16,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Ambil Foto Kamera',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  controller.handleCageImageUpload(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AppHeader(title: 'Profil Kandang'),
      body: SafeArea(
        child: Consumer<CageController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: cs.primary),
              );
            }

            if (controller.errorMessage != null) {
              return AppErrorState(
                message: 'Gagal memuat profil kandang',
                subtitle: controller.errorMessage,
                onRetry: () => controller.loadCageData(),
              );
            }

            final cageData = controller.cageData;
            if (cageData == null || (cageData.capacity == 0 && cageData.type.isEmpty)) {
              return _buildEmptyState(context, cs, tt);
            }

            final numFmt = NumberFormat('#,###', 'id_ID');

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. Hero Landscape Photo Facility Banner ─────────
                      Container(
                        height: 190,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          color: cs.primary.withValues(alpha: 0.08),
                          image: cageData.imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(cageData.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            if (cageData.imageUrl == null)
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.warehouse_rounded,
                                      size: 56,
                                      color: cs.primary.withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Foto Tampak Kandang',
                                      style: tt.bodyMedium?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (cageData.imageUrl != null)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.5),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (controller.isUploadingImage)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black45,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: FilledButton.tonalIcon(
                                onPressed: controller.isUploadingImage
                                    ? null
                                    : () => _showImageSourceBottomSheet(
                                          context,
                                          controller,
                                        ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: cs.surface.withValues(alpha: 0.9),
                                  foregroundColor: cs.primary,
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.pillRadius,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                                label: Text(
                                  cageData.imageUrl != null ? 'Ganti Foto' : 'Unggah Foto',
                                  style: tt.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 2. Hero Kapasitas Tampang DOC ────────────────────
                      AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: cs.secondaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.groups_rounded,
                                          size: 18,
                                          color: cs.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Kapasitas Maksimal',
                                        style: tt.labelMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.pillRadius,
                                      ),
                                    ),
                                    child: Text(
                                      'Kandang Utama',
                                      style: tt.labelSmall?.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    numFmt.format(cageData.capacity),
                                    style: tt.headlineMedium?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ekor DOC',
                                    style: tt.titleMedium?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Daya tampung maksimal bibit ayam broiler per siklus pemeliharaan.',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 3. Spesifikasi Konstruksi & Lokasi ────────────────
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.architecture_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Spesifikasi Bangunan & Lokasi',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _CageSpecTile(
                                icon: Icons.roofing_rounded,
                                label: 'Tipe Konstruksi Kandang',
                                value: cageData.type.isNotEmpty ? cageData.type : 'Belum diisi',
                                subtitle: 'Model ventilasi dan sirkulasi udara',
                              ),
                              const Divider(height: 20),
                              _CageSpecTile(
                                icon: Icons.location_on_outlined,
                                label: 'Alamat / Titik Lokasi Kandang',
                                value: cageData.location.isNotEmpty ? cageData.location : 'Belum diisi',
                                subtitle: 'Lokasi operasional peternakan',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── 4. Tombol Utama (Ubah Data Kandang) ───────────────
                      FilledButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormCage(cageData: cageData),
                            ),
                          );
                          if (result == true && mounted) {
                            context.read<CageController>().loadCageData();
                          }
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(
                          'Ubah Spesifikasi Kandang',
                          style: tt.labelLarge?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warehouse_outlined,
                size: 56,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Data Kandang',
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Isi kapasitas dan tipe konstruksi kandang Anda untuk memulai pencatatan dan monitoring populasi ayam.',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FormCage()),
                );
                if (result == true && mounted) {
                  context.read<CageController>().loadCageData();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Data Kandang Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CageSpecTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  const _CageSpecTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: cs.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
