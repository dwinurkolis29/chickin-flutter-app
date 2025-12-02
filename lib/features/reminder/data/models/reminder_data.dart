import '../../../../core/models/safe_convert.dart';

// model untuk menyimpan data reminder
class ReminderData {
  final String id;
  final String title;
  final String date;
  final String time;
  final String description;
  final String createdAt;
  final String updatedAt;

  ReminderData({
    this.id = '',
    this.title = '',
    this.date = '',
    this.time = '',
    this.description = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory ReminderData.fromJson(Map<String, dynamic>? json) => ReminderData(
    id: asString(json, 'id'),
    title: asString(json, 'title'),
    date: asString(json, 'date'),
    time: asString(json, 'time'),
    description: asString(json, 'description'),
    createdAt: asString(json, 'createdAt'),
    updatedAt: asString(json, 'updatedAt'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'time': time,
    'description': description,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  ReminderData copyWith({
    String? id,
    String? title,
    String? date,
    String? time,
    String? description,
    String? createdAt,
    String? updatedAt,
  }) {
    return ReminderData(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  toString() {
    return 'ReminderData(id: $id, title: $title, date: $date, time: $time, description: $description, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}