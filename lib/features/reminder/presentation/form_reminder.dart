import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your model, service, and notification service
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

  // Firebase Auth and Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  // Controllers
  final TextEditingController _controllerTitle = TextEditingController();
  final TextEditingController _controllerDate = TextEditingController();
  final TextEditingController _controllerTime = TextEditingController();
  final TextEditingController _controllerDescription = TextEditingController();

  // Focus Nodes
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
    _controllerTime.text = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

    // Request notification permissions on init
    _requestNotificationPermission();
  }

  // Request notification permission
  Future<void> _requestNotificationPermission() async {
    await _notificationService.requestPermissions();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        _controllerTime.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  // Combine date and time into single DateTime
  DateTime _getScheduledDateTime() {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  // Method untuk menambahkan reminder ke Firebase dan schedule notification
  Future<void> addReminder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anda harus login terlebih dahulu')),
          );
        }
        return;
      }

      // Generate ID dan timestamps
      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Use seconds for int
      final String id = notificationId.toString();
      final String createdAt = DateTime.now().toIso8601String();
      final String updatedAt = DateTime.now().toIso8601String();

      // Get scheduled date time
      final DateTime scheduledDateTime = _getScheduledDateTime();

      // Check if scheduled time is in the past
      if (scheduledDateTime.isBefore(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Waktu reminder tidak boleh di masa lalu'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // membuat objek reminder dengan data yang diambil dari text field
      final reminder = ReminderData(
        id: id,
        title: _controllerTitle.text.trim(),
        date: _controllerDate.text.trim(),
        time: _controllerTime.text.trim(),
        description: _controllerDescription.text.trim(),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      // 1. Simpan ke Firebase
      await _firebaseService.addReminder(reminder, user.email!);

      // 2. Schedule Local Notification
      await _notificationService.scheduleNotification(
        id: notificationId,
        title: reminder.title,
        body: reminder.description.isNotEmpty
            ? reminder.description
            : 'Reminder pada ${reminder.time}',
        scheduledDate: scheduledDateTime,
        payload: id, // Pass reminder ID for navigation
      );

      if (mounted) {
        // Tampilkan snackbar sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Reminder berhasil ditambahkan!\nNotifikasi dijadwalkan: ${DateFormat('dd MMM yyyy, HH:mm').format(scheduledDateTime)}'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Kembali ke halaman sebelumnya dengan hasil true
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // menampilkan snackbar jika terjadi error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Test notification (for debugging)
  Future<void> _testNotification() async {
    await _notificationService.showImmediateNotification(
      id: 999,
      title: 'Test Notification',
      body: 'This is a test notification',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent!')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Test notification button (remove in production)
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.orange),
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
              const Text(
                'Pengingat',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Title
              TextFormField(
                controller: _controllerTitle,
                focusNode: _focusNodeTitle,
                decoration: InputDecoration(
                  labelText: "Title",
                  hintText: "Masukkan Judul",
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Title tidak boleh kosong.";
                  }
                  return null;
                },
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
                  labelText: "Date",
                  hintText: "Select date",
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Date tidak boleh kosong.";
                  }
                  return null;
                },
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
                  labelText: "Time",
                  hintText: "Select time",
                  prefixIcon: const Icon(Icons.access_time),
                  suffixText: selectedTime.hour < 12 ? "AM" : "PM",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Time tidak boleh kosong.";
                  }
                  return null;
                },
                onEditingComplete: () => _focusNodeDescription.requestFocus(),
              ),
              const SizedBox(height: 10),

              // Description
              TextFormField(
                controller: _controllerDescription,
                focusNode: _focusNodeDescription,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description",
                  hintText: "Masukkan Deskripsi",
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              // Info about notification
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notifikasi akan muncul pada waktu yang dijadwalkan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Create Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    addReminder();
                  }
                },
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  "Tambah Pengingat",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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