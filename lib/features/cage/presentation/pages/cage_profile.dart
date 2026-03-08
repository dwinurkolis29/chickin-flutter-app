import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';
import 'package:recording_app/features/cage/presentation/pages/form_cage.dart';

class CageProfile extends StatefulWidget {
  const CageProfile({super.key});

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Profil Kandang',
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: colorScheme.onSurface),
            onPressed: () {
              final cageData = context.read<CageController>().cageData;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormCage(cageData: cageData),
                ),
              );
            },
          ),
        ],
      ),
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

            return SingleChildScrollView(
              child: Column(
                children: [
                  _Card(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: colorScheme.primary.withOpacity(
                            0.12,
                          ),
                          child: Icon(
                            Icons.house_siding,
                            size: 48,
                            color: colorScheme.primary,
                          ),
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
                        Divider(height: 20, color: colorScheme.outlineVariant),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          value: cageData.location,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  _Card(
                    onTap: () => controller.loadCageData(),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Refresh Data',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
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
