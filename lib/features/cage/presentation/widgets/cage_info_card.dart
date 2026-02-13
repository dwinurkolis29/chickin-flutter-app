// lib/features/cage/presentation/widgets/cage_info_card.dart
import 'package:flutter/material.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';

class CageInfoCard extends StatelessWidget {
  final CageData cageData;

  const CageInfoCard({
    super.key,
    required this.cageData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ReadOnlyField(
          label: "Kandang ke",
          value: cageData.idKandang.toString(),
          icon: Icons.other_houses_outlined,
        ),
        const SizedBox(height: 10),
        _ReadOnlyField(
          label: "Jenis Kandang",
          value: cageData.type,
          icon: Icons.bloodtype,
        ),
        const SizedBox(height: 10),
        _ReadOnlyField(
          label: "Kapasitas Kandang",
          value: cageData.capacity.toString(),
          icon: Icons.reduce_capacity,
        ),
        const SizedBox(height: 10),
        _ReadOnlyField(
          label: "Alamat Kandang",
          value: cageData.address,
          icon: Icons.location_on_outlined,
          maxLines: 2,
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final int maxLines;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      child: Text(
        value,
        maxLines: maxLines,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}