import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/safe_convert.dart';

/// Model untuk menyimpan data periode pemeliharaan ayam
class PeriodData {
  final String id;
  final String name;
  final int initialCapacity;
  final double initialWeight; // default 0.4 kg
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'active' | 'closed'
  final DateTime createdAt;
  final PeriodSummary? summary;

  const PeriodData({
    this.id = '',
    this.name = '',
    this.initialCapacity = 0,
    this.initialWeight = 0.4,
    required this.startDate,
    this.endDate,
    this.status = 'active',
    required this.createdAt,
    this.summary,
  });

  factory PeriodData.fromJson(Map<String, dynamic>? json, {String? docId}) {
    if (json == null) {
      return PeriodData(
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }

    return PeriodData(
      id: docId ?? asString(json, 'id'),
      name: asString(json, 'name'),
      initialCapacity: asInt(json, 'initialCapacity'),
      initialWeight: asDouble(json, 'initialWeight', defaultValue: 0.4),
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate(),
      status: asString(json, 'status', defaultValue: 'active'),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      summary: json['summary'] != null 
          ? PeriodSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'name': name,
    'initialCapacity': initialCapacity,
    'initialWeight': initialWeight,
    'startDate': Timestamp.fromDate(startDate),
    if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    if (summary != null) 'summary': summary!.toJson(),
  };

  PeriodData copyWith({
    String? id,
    String? name,
    int? initialCapacity,
    double? initialWeight,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    DateTime? createdAt,
    PeriodSummary? summary,
  }) {
    return PeriodData(
      id: id ?? this.id,
      name: name ?? this.name,
      initialCapacity: initialCapacity ?? this.initialCapacity,
      initialWeight: initialWeight ?? this.initialWeight,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      summary: summary ?? this.summary,
    );
  }

  @override
  String toString() {
    return 'PeriodData(id: $id, name: $name, status: $status, initialCapacity: $initialCapacity)';
  }
}

/// Model untuk summary periode
class PeriodSummary {
  final double totalFeedKg;
  final int finalPopulation;
  final int totalMortality;
  final double finalBiomass;
  final double finalFCR;
  final double avgDailyGain;
  final List<WeeklyFCR> weeklyFCR;

  const PeriodSummary({
    this.totalFeedKg = 0.0,
    this.finalPopulation = 0,
    this.totalMortality = 0,
    this.finalBiomass = 0.0,
    this.finalFCR = 0.0,
    this.avgDailyGain = 0.0,
    this.weeklyFCR = const [],
  });

  factory PeriodSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PeriodSummary();
    }

    return PeriodSummary(
      totalFeedKg: asDouble(json, 'totalFeedKg'),
      finalPopulation: asInt(json, 'finalPopulation'),
      totalMortality: asInt(json, 'totalMortality'),
      finalBiomass: asDouble(json, 'finalBiomass'),
      finalFCR: asDouble(json, 'finalFCR'),
      avgDailyGain: asDouble(json, 'avgDailyGain'),
      weeklyFCR: (json['weeklyFCR'] as List<dynamic>?)
          ?.map((e) => WeeklyFCR.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'totalFeedKg': totalFeedKg,
    'finalPopulation': finalPopulation,
    'totalMortality': totalMortality,
    'finalBiomass': finalBiomass,
    'finalFCR': finalFCR,
    'avgDailyGain': avgDailyGain,
    'weeklyFCR': weeklyFCR.map((e) => e.toJson()).toList(),
  };

  PeriodSummary copyWith({
    double? totalFeedKg,
    int? finalPopulation,
    int? totalMortality,
    double? finalBiomass,
    double? finalFCR,
    double? avgDailyGain,
    List<WeeklyFCR>? weeklyFCR,
  }) {
    return PeriodSummary(
      totalFeedKg: totalFeedKg ?? this.totalFeedKg,
      finalPopulation: finalPopulation ?? this.finalPopulation,
      totalMortality: totalMortality ?? this.totalMortality,
      finalBiomass: finalBiomass ?? this.finalBiomass,
      finalFCR: finalFCR ?? this.finalFCR,
      avgDailyGain: avgDailyGain ?? this.avgDailyGain,
      weeklyFCR: weeklyFCR ?? this.weeklyFCR,
    );
  }
}

/// Model untuk FCR mingguan
class WeeklyFCR {
  final int week;
  final double fcr;

  const WeeklyFCR({
    this.week = 0,
    this.fcr = 0.0,
  });

  factory WeeklyFCR.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const WeeklyFCR();
    }

    return WeeklyFCR(
      week: asInt(json, 'week'),
      fcr: asDouble(json, 'fcr'),
    );
  }

  Map<String, dynamic> toJson() => {
    'week': week,
    'fcr': fcr,
  };

  WeeklyFCR copyWith({
    int? week,
    double? fcr,
  }) {
    return WeeklyFCR(
      week: week ?? this.week,
      fcr: fcr ?? this.fcr,
    );
  }
}
