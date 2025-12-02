import 'package:flutter/material.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your model and service
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/services/notification_service.dart';
import 'package:recording_app/features/reminder/data/models/reminder_data.dart';
import 'package:recording_app/features/reminder/presentation/form_reminder.dart';

class Reminder extends StatefulWidget {
  const Reminder({Key? key}) : super(key: key);

  @override
  State<Reminder> createState() => _ReminderState();
}

class _ReminderState extends State<Reminder> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    // Optionally show pending notifications for debugging
    await _notificationService.getPendingNotifications();
  }

  void _showMonthCalendar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(focusedDate),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            focusedDate = DateTime(
                              focusedDate.year,
                              focusedDate.month - 1,
                            );
                          });
                          Navigator.pop(context);
                          _showMonthCalendar();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            focusedDate = DateTime(
                              focusedDate.year,
                              focusedDate.month + 1,
                            );
                          });
                          Navigator.pop(context);
                          _showMonthCalendar();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((day) => SizedBox(
                  width: 40,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildMonthCalendar(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCalendar() {
    DateTime firstDayOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
    DateTime lastDayOfMonth = DateTime(focusedDate.year, focusedDate.month + 1, 0);
    int daysInMonth = lastDayOfMonth.day;
    int startWeekday = firstDayOfMonth.weekday - 1;

    List<Widget> days = [];

    for (int i = 0; i < startWeekday; i++) {
      days.add(const SizedBox(width: 40, height: 40));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime currentDay = DateTime(focusedDate.year, focusedDate.month, day);
      bool isSelected = selectedDate.year == currentDay.year &&
          selectedDate.month == currentDay.month &&
          selectedDate.day == currentDay.day;
      bool isToday = DateTime.now().year == currentDay.year &&
          DateTime.now().month == currentDay.month &&
          DateTime.now().day == currentDay.day;

      days.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedDate = currentDay;
              focusedDate = currentDay;
            });
            Navigator.pop(context);
          },
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                colors: [Colors.indigo, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isToday && !isSelected
                  ? Border.all(color: Colors.indigo, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    List<Widget> weeks = [];
    for (int i = 0; i < days.length; i += 7) {
      int end = (i + 7 < days.length) ? i + 7 : days.length;
      List<Widget> weekDays = days.sublist(i, end);

      while (weekDays.length < 7) {
        weekDays.add(const SizedBox(width: 40, height: 40));
      }

      weeks.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays,
        ),
      );
      weeks.add(const SizedBox(height: 8));
    }

    return SingleChildScrollView(
      child: Column(
        children: weeks,
      ),
    );
  }

  // Filter reminders by selected date
  List<ReminderData> _filterRemindersByDate(List<ReminderData> reminders) {
    String selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    return reminders.where((reminder) => reminder.date == selectedDateStr).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    showDeleteDialog(ReminderData reminder) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Reminder'),
          content: const Text('Are you sure you want to delete this reminder?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Delete from Firebase
                  await _firebaseService.deleteReminder(reminder.id, user!.email!);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reminder deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting reminder: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Button to check pending notifications (for debugging)
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.black),
            onPressed: () async {
              final pending = await _notificationService.getPendingNotifications();
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Pending Notifications'),
                  content: Text(
                    pending.isEmpty
                        ? 'No pending notifications'
                        : pending.map((n) => '${n.id}: ${n.title}').join('\n'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: user == null
          ? Center(
        child: Text('Silahkan login terlebih dahulu'),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM yyyy').format(focusedDate),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _showMonthCalendar,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          EasyDateTimeLine(
            initialDate: selectedDate,
            onDateChange: (date) {
              setState(() {
                selectedDate = date;
                focusedDate = date;
              });
            },
            headerProps: const EasyHeaderProps(
              showHeader: false,
            ),
            dayProps: EasyDayProps(
              height: 100,
              width: 60,
              dayStructure: DayStructure.dayStrDayNum,
              inactiveDayStyle: DayStyle(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                dayNumStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                dayStrStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              activeDayStyle: DayStyle(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                dayNumStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                dayStrStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reminders',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.more_horiz, color: Colors.grey),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<ReminderData>>(
                      stream: _firebaseService.getReminderStream(user.email!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_note,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada reminder',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final allReminders = snapshot.data!;
                        final filteredReminders = _filterRemindersByDate(allReminders);

                        if (filteredReminders.isEmpty) {
                          return Center(
                            child: Text(
                              'Tidak ada reminder untuk tanggal ini',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredReminders.length,
                          itemBuilder: (context, index) {
                            final reminder = filteredReminders[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.alarm,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reminder.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          reminder.time,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        if (reminder.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            reminder.description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      showDeleteDialog(reminder);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FormReminder()),
                        );
                      },
                      backgroundColor: Colors.white,
                      icon: Icon(Icons.add),
                      label: Text("Tambah"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}