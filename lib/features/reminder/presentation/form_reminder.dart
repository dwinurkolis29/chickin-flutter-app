import 'package:flutter/material.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/services/notification_service.dart';
import 'package:recording_app/core/services/reminder_local_service.dart';
import 'package:recording_app/features/reminder/data/models/reminder_data.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Form untuk tambah dan edit reminder.
/// Jika [editReminder] diisi, form berjalan di mode edit.
class FormReminder extends StatefulWidget {
  final ReminderData? editReminder;

  const FormReminder({Key? key, this.editReminder}) : super(key: key);

  @override
  State<FormReminder> createState() => _FormReminderState();
}

class _FormReminderState extends State<FormReminder> {
  final _formKey = GlobalKey<FormState>();
  final _notificationService = NotificationService();
  final _localService = ReminderLocalService();

  final TextEditingController _controllerTitle = TextEditingController();
  final TextEditingController _controllerDate = TextEditingController();
  final TextEditingController _controllerTime = TextEditingController();
  final TextEditingController _controllerDescription = TextEditingController();

  final FocusNode _focusNodeTitle = FocusNode();
  final FocusNode _focusNodeDate = FocusNode();
  final FocusNode _focusNodeTime = FocusNode();
  final FocusNode _focusNodeDescription = FocusNode();

  bool _isLoading = false;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  bool get _isEditMode => widget.editReminder != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      final r = widget.editReminder!;
      _selectedDate = DateTime.tryParse(r.date) ?? DateTime.now();
      final parts = r.time.split(':');
      _selectedTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? TimeOfDay.now().hour,
        minute: int.tryParse(parts[1]) ?? TimeOfDay.now().minute,
      );
      _controllerTitle.text = r.title;
      _controllerDate.text = r.date;
      _controllerTime.text = r.time;
      _controllerDescription.text = r.description;
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _controllerDate.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _controllerTime.text =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _controllerTitle.dispose();
    _controllerDate.dispose();
    _controllerTime.dispose();
    _controllerDescription.dispose();
    _focusNodeTitle.dispose();
    _focusNodeDate.dispose();
    _focusNodeTime.dispose();
    _focusNodeDescription.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _controllerDate.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _controllerTime.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  DateTime _getScheduledDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final scheduledDateTime = _getScheduledDateTime();
    if (scheduledDateTime.isBefore(DateTime.now())) {
      AppSnackbar.showError(context, 'Waktu reminder tidak boleh di masa lalu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now().toIso8601String();
      final int notifId;
      final String reminderId;

      if (_isEditMode) {
        reminderId = widget.editReminder!.id;
        notifId = int.tryParse(reminderId) ?? reminderId.hashCode;
        // Batalkan notif lama sebelum reschedule
        await _notificationService.cancelNotification(notifId);
      } else {
        notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        reminderId = notifId.toString();
      }

      final reminder = ReminderData(
        id: reminderId,
        title: _controllerTitle.text.trim(),
        date: _controllerDate.text.trim(),
        time: _controllerTime.text.trim(),
        description: _controllerDescription.text.trim(),
        createdAt: _isEditMode ? widget.editReminder!.createdAt : now,
        updatedAt: now,
      );

      if (_isEditMode) {
        await _localService.updateReminder(reminder);
      } else {
        await _localService.addReminder(reminder);
      }

      await _notificationService.scheduleNotification(
        id: notifId,
        title: reminder.title,
        body: reminder.description.isNotEmpty
            ? reminder.description
            : 'Reminder pada ${reminder.time}',
        scheduledDate: scheduledDateTime,
        payload: reminderId,
      );

      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          _isEditMode
              ? 'Reminder berhasil diperbarui!'
              : 'Reminder berhasil ditambahkan!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Gagal menyimpan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showImmediateNotification(
      id: 999,
      title: 'Uji Notifikasi',
      body: 'This is a test notification',
    );
    if (mounted) AppSnackbar.showInfo(context, 'Test notification sent!');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppHeader(
        title: _isEditMode ? 'Edit Reminder' : 'Tambah Reminder',
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active, color: cs.tertiary),
            onPressed: _testNotification,
            tooltip: 'Test Notification',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  _isEditMode ? 'Edit Pengingat' : 'Pengingat Baru',
                  style: tt.titleLarge?.copyWith(color: cs.onSurface),
                ),
                const SizedBox(height: 24),

                AppTextFormField(
                  controller: _controllerTitle,
                  focusNode: _focusNodeTitle,
                  labelText: 'Judul',
                  hintText: 'Masukkan judul reminder',
                  prefixIcon: Icons.title,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Judul tidak boleh kosong' : null,
                  onEditingComplete: () => _focusNodeDate.requestFocus(),
                ),
                const SizedBox(height: 12),

                AppTextFormField(
                  controller: _controllerDate,
                  focusNode: _focusNodeDate,
                  readOnly: true,
                  onTap: _selectDate,
                  labelText: 'Tanggal',
                  hintText: 'Pilih tanggal',
                  prefixIcon: Icons.calendar_today,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Tanggal tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),

                AppTextFormField(
                  controller: _controllerTime,
                  focusNode: _focusNodeTime,
                  readOnly: true,
                  onTap: _selectTime,
                  labelText: 'Waktu',
                  hintText: 'Pilih waktu',
                  prefixIcon: Icons.access_time,
                  suffixText: _selectedTime.hour < 12 ? 'AM' : 'PM',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Waktu tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),

                AppTextFormField(
                  controller: _controllerDescription,
                  focusNode: _focusNodeDescription,
                  maxLines: 3,
                  labelText: 'Deskripsi',
                  hintText: 'Masukkan deskripsi (opsional)',
                  prefixIcon: Icons.description,
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.secondary),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.onSecondaryContainer, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notifikasi akan muncul pada waktu yang dijadwalkan',
                          style: tt.labelSmall?.copyWith(color: cs.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                  ),
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Simpan Perubahan' : 'Tambah Pengingat',
                          style: tt.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimary,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
