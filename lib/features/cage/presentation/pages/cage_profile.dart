import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';
import 'package:recording_app/features/cage/presentation/pages/form_cage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recording_app/core/components/header/app_header.dart';

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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text('Galeri', style: Theme.of(context).textTheme.bodyMedium),
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
                color: AppColors.secondary.withOpacity(0.3),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text('Kamera', style: Theme.of(context).textTheme.bodyMedium),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: widget.isTab
          ? null
          : AppHeader(title: 'Profil Kandang'),
      body: SafeArea(
        top: false,
        child: Consumer<CageController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            if (controller.errorMessage != null &&
                controller.errorMessage!.isNotEmpty) {
              if (!controller.hasValidCageData) {
                return _buildEmptyState(context, colorScheme);
              }
            }

            if (!controller.hasValidCageData) {
              return _buildEmptyState(context, colorScheme);
            }

            final cageData = controller.cageData!;

            return RefreshIndicator(
              onRefresh: () => controller.loadCageData(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _Card(
                      onTap: () {
                        final cageData = controller.cageData;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FormCage(cageData: cageData),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: colorScheme.primary
                                    .withOpacity(0.12),
                                backgroundImage:
                                    cageData.imageUrl != null
                                        ? NetworkImage(cageData.imageUrl!)
                                        : null,
                                child:
                                    cageData.imageUrl == null
                                        ? Icon(
                                          Icons.house_siding,
                                          size: 48,
                                          color: colorScheme.primary,
                                        )
                                        : null,
                              ),
                              if (controller.isUploadingImage)
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black38,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap:
                                      controller.isUploadingImage
                                          ? null
                                          : () => _showImageSourceBottomSheet(
                                            context,
                                            controller,
                                          ),
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: colorScheme.primary,
                                    child: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cageData.type,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Data Kandang',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    _Card(
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.reduce_capacity,
                            value: '${cageData.capacity} Ekor',
                          ),
                          Divider(
                            height: 20,
                            color: colorScheme.outlineVariant,
                          ),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            value: cageData.location,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.house_siding_outlined,
              size: 100,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Data Kandang',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Anda belum memiliki data kandang. Silakan tambahkan data kandang terlebih dahulu.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
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
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kandang'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Card({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isInteractive = onTap != null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child:
          isInteractive
              ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: SizedBox(width: double.infinity, child: child),
                ),
              )
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: SizedBox(width: double.infinity, child: child),
              ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
