import 'package:hive_flutter/hive_flutter.dart';
import 'package:recording_app/features/reminder/data/models/reminder_data.dart';

/// Local storage service untuk reminder menggunakan Hive.
/// Menggantikan Firebase untuk penyimpanan reminder.
class ReminderLocalService {
  static const String _boxName = 'reminders';

  static final ReminderLocalService _instance = ReminderLocalService._internal();
  factory ReminderLocalService() => _instance;
  ReminderLocalService._internal();

  Box get _box => Hive.box(_boxName);

  /// Tambah reminder baru
  Future<void> addReminder(ReminderData reminder) async {
    await _box.put(reminder.id, reminder.toJson());
  }

  /// Update reminder yang sudah ada (berdasarkan id)
  Future<void> updateReminder(ReminderData reminder) async {
    await _box.put(reminder.id, reminder.toJson());
  }

  /// Hapus reminder berdasarkan id
  Future<void> deleteReminder(String id) async {
    await _box.delete(id);
  }

  /// Ambil semua reminder sebagai list
  List<ReminderData> getAllReminders() {
    return _box.values
        .map((e) => ReminderData.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Stream reactive — emit ulang setiap kali ada perubahan di box
  Stream<List<ReminderData>> watchReminders() {
    return _box.watch().map((_) => getAllReminders());
  }
}
