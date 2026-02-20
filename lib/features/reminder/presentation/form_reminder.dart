import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/services/notification_service.dart';
import 'package:recording_app/features/reminder/data/models/reminder_data.dart';

class FormReminder extends StatefulWidget {
  const FormReminder({Key? key}) : super(key: key);

  @override
  State<FormReminder> createState() => _FormReminderState();
}

class _FormReminderState extends State<FormReminder> {
  final _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  final TextEditingController _controllerTitle = TextEditingController();
  final TextEditingController _controllerDate = TextEditingController();
  final TextEditingController _controllerTime = TextEditingController();
  final TextEditingController _controllerDescription = TextEditingController();

  final FocusNode _focusNodeTitle = FocusNode();
  final FocusNode _focusNodeDate = FocusNode();
  final FocusNode _focusNodeTime = FocusNode();
  final FocusNode _focusNodeDescription = FocusNode();

  bool _isLoading = false;

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _controllerDate.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    _controllerTime.text =
        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    await _notificationService.requestPermissions();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _controllerDate.text = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        _controllerTime.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  DateTime _getScheduledDateTime() {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  Future<void> addReminder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) AppSnackbar.showError(context, 'Anda harus login terlebih dahulu');
        return;
      }

      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final String id = notificationId.toString();
      final String createdAt = DateTime.now().toIso8601String();
      final String updatedAt = DateTime.now().toIso8601String();
      final DateTime scheduledDateTime = _getScheduledDateTime();

      if (scheduledDateTime.isBefore(DateTime.now())) {
        if (mounted) AppSnackbar.showError(context, 'Waktu reminder tidak boleh di masa lalu');
        setState(() => _isLoading = false);
        return;
      }

      final reminder = ReminderData(
        id: id,
        title: _controllerTitle.text.trim(),
        date: _controllerDate.text.trim(),
        time: _controllerTime.text.trim(),
        description: _controllerDescription.text.trim(),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      await _firebaseService.addReminder(reminder, user.email!);
      await _notificationService.scheduleNotification(
        id: notificationId,
        title: reminder.title,
        body: reminder.description.isNotEmpty
            ? reminder.description
            : 'Reminder pada ${reminder.time}',
        scheduledDate: scheduledDateTime,
        payload: id,
      );

      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          'Reminder berhasil ditambahkan!\nNotifikasi dijadwalkan: ${DateFormat('dd MMM yyyy, HH:mm').format(scheduledDateTime)}',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Gagal menyimpan data: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showImmediateNotification(
      id: 999,
      title: 'Test Notification',
      body: 'This is a test notification',
    );
    if (mounted) AppSnackbar.showInfo(context, 'Test notification sent!');
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active, color: colorScheme.tertiary),
            onPressed: _testNotification,
            tooltip: 'Test Notification',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengingat',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 30),

              // Title
              TextFormField(
                controller: _controllerTitle,
                focusNode: _focusNodeTitle,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Masukkan Judul',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Title tidak boleh kosong.' : null,
                onEditingComplete: () => _focusNodeDate.requestFocus(),
              ),
              const SizedBox(height: 10),

              // Date
              TextFormField(
                controller: _controllerDate,
                focusNode: _focusNodeDate,
                readOnly: true,
                onTap: _selectDate,
                decoration: InputDecoration(
                  labelText: 'Date',
                  hintText: 'Select date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Date tidak boleh kosong.' : null,
                onEditingComplete: () => _focusNodeTime.requestFocus(),
              ),
              const SizedBox(height: 10),

              // Time
              TextFormField(
                controller: _controllerTime,
                focusNode: _focusNodeTime,
                readOnly: true,
                onTap: _selectTime,
                decoration: InputDecoration(
                  labelText: 'Time',
                  hintText: 'Select time',
                  prefixIcon: const Icon(Icons.access_time),
                  suffixText: selectedTime.hour < 12 ? 'AM' : 'PM',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Time tidak boleh kosong.' : null,
                onEditingComplete: () => _focusNodeDescription.requestFocus(),
              ),
              const SizedBox(height: 10),

              // Description
              TextFormField(
                controller: _controllerDescription,
                focusNode: _focusNodeDescription,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Masukkan Deskripsi',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                ),
              ),
              const SizedBox(height: 10),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.secondary),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.onSecondaryContainer, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notifikasi akan muncul pada waktu yang dijadwalkan',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Submit button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) addReminder();
                      },
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                        ),
                      )
                    : Text(
                        'Tambah Pengingat',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}