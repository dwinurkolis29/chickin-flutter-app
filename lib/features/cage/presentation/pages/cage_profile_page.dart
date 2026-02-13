// lib/features/cage/presentation/pages/cage_profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';
import 'package:recording_app/features/cage/presentation/widgets/cage_info_card.dart';
import 'package:recording_app/features/cage/presentation/pages/add_cage_page.dart';

class CageProfilePage extends StatefulWidget {
  const CageProfilePage({super.key});

  @override
  State<CageProfilePage> createState() => _CageProfilePageState();
}

class _CageProfilePageState extends State<CageProfilePage> {
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Consumer<CageController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return _buildErrorState(context, controller);
          }

          // UBAH INI - CEK hasValidCageData BUKAN cageData == null
          if (!controller.hasValidCageData) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildHeader(context),
                const SizedBox(height: 35),
                CageInfoCard(cageData: controller.cageData!),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, CageController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => controller.loadCageData(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.house_siding_outlined,
              size: 100,
              color: Colors.grey,
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
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCagePage(),
                  ),
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

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.house_siding, size: 50),
            const SizedBox(width: 10),
            Text(
              "Profil Kandang",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "Informasi Kandang Peternak",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}