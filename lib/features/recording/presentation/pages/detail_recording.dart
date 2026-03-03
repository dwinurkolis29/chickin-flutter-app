import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';

/// Halaman yang menampilkan semua data recording beserta tombol Edit di tiap baris.
class DetailRecording extends StatelessWidget {
  const DetailRecording({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecordingController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Recording'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<RecordingData>>(
        stream: controller.recordingsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final recordings = snapshot.data ?? <RecordingData>[];

          if (recordings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data recording',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return _RecordingTable(recordings: recordings, controller: controller);
        },
      ),
    );
  }
}

class _RecordingTable extends StatelessWidget {
  const _RecordingTable({required this.recordings, required this.controller});

  final List<RecordingData> recordings;
  final RecordingController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          ),
          columns: const [
            DataColumn(label: Text('Hari', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Berat (g)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Pakan (sak)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Mati', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Edit', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: recordings.map((rec) {
            return DataRow(cells: [
              DataCell(Text('${rec.day}')),
              DataCell(Text('${rec.avgWeightGram}')),
              DataCell(Text('${rec.feedSack}')),
              DataCell(Text('${rec.mortality}')),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit recording',
                  onPressed: () => _showEditSheet(context, rec),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, RecordingData recording) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditRecordingSheet(
        recording: recording,
        onSave: (updated) async {
          try {
            await controller.updateRecording(updated);
            if (context.mounted) {
              AppSnackbar.showSuccess(context, 'Data berhasil diperbarui');
            }
          } catch (e) {
            if (context.mounted) {
              AppSnackbar.showError(context, 'Gagal memperbarui data: $e');
            }
          }
        },
      ),
    );
  }
}

/// Bottom sheet form untuk mengedit satu baris recording.
class _EditRecordingSheet extends StatefulWidget {
  const _EditRecordingSheet({required this.recording, required this.onSave});

  final RecordingData recording;
  final Future<void> Function(RecordingData updated) onSave;

  @override
  State<_EditRecordingSheet> createState() => _EditRecordingSheetState();
}

class _EditRecordingSheetState extends State<_EditRecordingSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _ctrlDay;
  late final TextEditingController _ctrlWeight;
  late final TextEditingController _ctrlFeed;
  late final TextEditingController _ctrlMortality;

  @override
  void initState() {
    super.initState();
    _ctrlDay = TextEditingController(text: '${widget.recording.day}');
    _ctrlWeight = TextEditingController(text: '${widget.recording.avgWeightGram}');
    _ctrlFeed = TextEditingController(text: '${widget.recording.feedSack}');
    _ctrlMortality = TextEditingController(text: '${widget.recording.mortality}');
  }

  @override
  void dispose() {
    _ctrlDay.dispose();
    _ctrlWeight.dispose();
    _ctrlFeed.dispose();
    _ctrlMortality.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final updated = widget.recording.copyWith(
      day: int.tryParse(_ctrlDay.text),
      avgWeightGram: int.tryParse(_ctrlWeight.text),
      feedSack: int.tryParse(_ctrlFeed.text),
      mortality: int.tryParse(_ctrlMortality.text),
    );

    await widget.onSave(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + padding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Edit Recording', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _ctrlDay,
              label: 'Umur Ayam (hari)',
              icon: Icons.data_saver_on_rounded,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _ctrlWeight,
              label: 'Berat Ayam (gram)',
              icon: Icons.scale,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _ctrlFeed,
              label: 'Habis pakan (sak)',
              icon: Icons.arrow_circle_up,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _ctrlMortality,
              label: 'Mati ayam (Ekor)',
              icon: Icons.highlight_remove,
              required: false,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? '$label tidak boleh kosong.' : null
          : null,
    );
  }
}
