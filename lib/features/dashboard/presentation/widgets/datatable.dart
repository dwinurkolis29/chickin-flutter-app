import 'package:flutter/material.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';

class ChickenDataTable extends StatefulWidget {
  final List<RecordingData> chickenDataList;
  final VoidCallback? onViewAll;

  const ChickenDataTable({super.key, required this.chickenDataList, this.onViewAll});

  @override
  ChickenDataTableState createState() => ChickenDataTableState();
}

class ChickenDataTableState extends State<ChickenDataTable> {
  int _rowsPerPage = 7;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  // membuat variabel untuk menyimpan data recording ayam
  late List<RecordingData> _chickenData;
  late ChickenDataSource _chickenDataSource;

  @override
  void initState() {
    super.initState();
    _chickenData = List.from(widget.chickenDataList);
    _chickenDataSource = ChickenDataSource(_chickenData);
  }

  @override
  void didUpdateWidget(covariant ChickenDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chickenDataList != oldWidget.chickenDataList) {
      setState(() {
        _chickenData = List.from(widget.chickenDataList);
        _chickenDataSource = ChickenDataSource(_chickenData);
      });
    }
  }

  void _sort<T>(Comparable<T> Function(RecordingData d) getField, int columnIndex, bool ascending) {
    _chickenDataSource.sort<T>(getField, ascending);
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  void dispose() {
    _chickenDataSource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        // Estimasi total lebar konten 4 kolom: ~420px
        const double contentWidth = 420.0;
        final double horizontalMargin = maxWidth > 600 ? 24.0 : 16.0;
        final double calculatedSpacing = (maxWidth - contentWidth - (horizontalMargin * 2)) / 3;
        final double finalColumnSpacing = calculatedSpacing.clamp(24.0, 120.0);

        return SingleChildScrollView(
          // membuat paginated data table
          child: PaginatedDataTable(
            // membuat header pada paginated data table
            header: Text('Recording Data',
                style: Theme.of(context).textTheme.titleMedium),
            columnSpacing: finalColumnSpacing,
            horizontalMargin: horizontalMargin,
        actions: [
          if (widget.onViewAll != null)
            TextButton.icon(
              onPressed: widget.onViewAll,
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text('Lihat Semua'),
            ),
        ],
        rowsPerPage: _rowsPerPage,
        availableRowsPerPage: const <int>[7, 10, 20],
        onRowsPerPageChanged: (value) {
          setState(() {
            // mengatur jumlah baris per halaman
            _rowsPerPage = value ?? 7;
          });
        },
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        columns: [
          // membuat kolom pada paginated data table
          DataColumn(
            label: const Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text('Umur (hari)'),
              ),
            ),
            numeric: true,
            onSort: (columnIndex, ascending) =>
                _sort<num>((d) => d.day, columnIndex, ascending),
          ),
          DataColumn(
            label: const Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text('Pakan (sak)'),
              ),
            ),
            numeric: true,
            onSort: (columnIndex, ascending) =>
                _sort<num>((d) => d.feedSack, columnIndex, ascending),
          ),
          DataColumn(
            label: const Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text('Mati (ekor)'),
              ),
            ),
            numeric: true,
            onSort: (columnIndex, ascending) =>
                _sort<num>((d) => d.mortality, columnIndex, ascending),
          ),
          DataColumn(
            label: const Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text('Bobot (gram)'),
              ),
            ),
            numeric: true,
            onSort: (columnIndex, ascending) =>
                _sort<num>((d) => d.avgWeightGram, columnIndex, ascending),
          ),
        ],
        source: _chickenDataSource,
      ),
    );
  },
);
}
}

class ChickenDataSource extends DataTableSource {
  final List<RecordingData> _chickenData;

  // membuat konstruktor untuk memasukkan data recording ayam
  ChickenDataSource(List<RecordingData> chickenData) : _chickenData = chickenData;

  void sort<T>(Comparable<T> Function(RecordingData d) getField, bool ascending) {
    _chickenData.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= _chickenData.length) return null;
    final chicken = _chickenData[index];

    // membuat baris data
    return DataRow.byIndex(
      index: index,
      cells: [
        // membuat cell pada baris data
        DataCell(
          Align(
            alignment: Alignment.center,
            child: Text(chicken.day.toString()),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.center,
            child: Text(chicken.feedSack.toString()),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.center,
            child: Text(chicken.mortality.toString()),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.center,
            child: Text(chicken.avgWeightGram.toStringAsFixed(2)),
          ),
        ),
      ],
    );
  }

  @override
  int get rowCount => _chickenData.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}