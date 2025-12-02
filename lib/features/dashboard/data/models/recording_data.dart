import '../../../../core/models/safe_convert.dart';

// model untuk menyimpan data recording ayam
class RecordingData {
  final int umur;
  final int terimaPakan;
  final double habisPakan;
  final int matiAyam;
  final int beratAyam;
  final int id_periode;

  RecordingData({
    this.umur = 0,
    this.terimaPakan = 0,
    this.habisPakan = 0.0,
    this.matiAyam = 0,
    this.beratAyam = 0,
    this.id_periode = 0
  });

  factory RecordingData.fromJson(Map<String, dynamic>? json) => RecordingData(
    umur: asInt(json, 'umur'),
    terimaPakan: asInt(json, 'terimaPakan'),
    habisPakan: asDouble(json, 'habisPakan'),
    matiAyam: asInt(json, 'matiAyam'),
    beratAyam: asInt(json, 'beratAyam'),
    id_periode: asInt(json, 'id_periode'),
  );

  Map<String, dynamic> toJson() => {
    'umur': umur,
    'terimaPakan': terimaPakan,
    'habisPakan': habisPakan,
    'matiAyam': matiAyam,
    'beratAyam': beratAyam,
    'id_periode': id_periode
  };

  RecordingData copyWith({
    int? umur,
    int? terimaPakan,
    double? habisPakan,
    int? matiAyam,
    int? beratAyam,
    int? id_periode
  }) {
    return RecordingData(
      umur: umur ?? this.umur,
      terimaPakan: terimaPakan ?? this.terimaPakan,
      habisPakan: habisPakan ?? this.habisPakan,
      matiAyam: matiAyam ?? this.matiAyam,
      beratAyam: beratAyam ?? this.beratAyam,
      id_periode: id_periode ?? this.id_periode
    );
  }

  @override
  toString() {
    return 'RecordingData(umur: $umur, terimaPakan: $terimaPakan, habisPakan: $habisPakan, matiAyam: $matiAyam, beratAyam: $beratAyam)';
  }
}

