import 'package:flutter/material.dart';
import '../../data/models/recording_data.dart';

class ChickenDataTable extends StatefulWidget {
  final List<RecordingData> chickenDataList;
  
  const ChickenDataTable({super.key, required this.chickenDataList});

  @override
  ChickenDataTableState createState() => ChickenDataTableState();
}

class ChickenDataTableState extends State<ChickenDataTable> {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
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
    return SingleChildScrollView(
      // membuat paginated data table
      child: PaginatedDataTable(
        // membuat header pada paginated data table
        header: const Text('Recording Data'),
        rowsPerPage: _rowsPerPage,
        onRowsPerPageChanged: (value) {
          setState(() {
            // mengatur jumlah baris per halaman
            _rowsPerPage = value ?? 10;
          });
        },
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        columns: [
          // membuat kolom pada paginated data table
          DataColumn(
            label: const Text('Umur (hari)'),
            numeric: true,
            onSort: (columnIndex, ascending) =>
                _sort<num>((d) => d.day, columnIndex, ascending),
          ),
          DataColumn(
            label: const Text('Habis pakan (sak)'),
            numeric: true,
            onSort: (columnIndex, ascending) =>
                _sort<num>((d) => d.feedSack, columnIndex, ascending),
          ),
          DataColumn(
            label: const Text('Mati (ekor)'),
            numeric: true,
            onSort: (columnIndex, ascending) =>
                _sort<num>((d) => d.mortality, columnIndex, ascending),
          ),
          DataColumn(
            label: const Text('Bobot (gram)'),
            numeric: true,
            onSort: (columnIndex, ascending) =>
                _sort<num>((d) => d.avgWeightGram, columnIndex, ascending),
          ),
        ],
        source: _chickenDataSource,
      ),
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
          ? Comparable.compare(aValue as Comparable<T>, bValue as Comparable<T>)
          : Comparable.compare(bValue as Comparable<T>, aValue as Comparable<T>);
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
        DataCell(Text(chicken.day.toString())),
        DataCell(Text(chicken.feedSack.toString())),
        DataCell(Text(chicken.mortality.toString())),
        DataCell(Text(chicken.avgWeightGram.toStringAsFixed(2))),
      ],
    );
  }

  @override
  int get rowCount => _chickenData.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;

  void dispose() {
    // Clean up resources if needed
  }
}