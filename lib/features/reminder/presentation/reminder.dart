import 'package:flutter/material.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/services/notification_service.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
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
    await _notificationService.getPendingNotifications();
  }

  void _showMonthCalendar() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
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
                    style: textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            focusedDate = DateTime(focusedDate.year, focusedDate.month - 1);
                          });
                          Navigator.pop(context);
                          _showMonthCalendar();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            focusedDate = DateTime(focusedDate.year, focusedDate.month + 1);
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
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              color: isSelected ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isToday && !isSelected
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: textTheme.bodyMedium?.copyWith(
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
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
      weeks.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays,
      ));
      weeks.add(const SizedBox(height: 8));
    }

    return SingleChildScrollView(child: Column(children: weeks));
  }

  List<ReminderData> _filterRemindersByDate(List<ReminderData> reminders) {
    String selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    return reminders.where((reminder) => reminder.date == selectedDateStr).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = _auth.currentUser;

    showDeleteDialog(ReminderData reminder) async {
      final confirmed = await DialogHelper.showConfirm(
        context,
        'Delete Reminder',
        'Are you sure you want to delete this reminder?',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDestructive: true,
      );

      if (confirmed == true) {
        try {
          await _firebaseService.deleteReminder(reminder.id, user!.email!);
          if (mounted) AppSnackbar.showSuccess(context, 'Reminder deleted successfully');
        } catch (e) {
          if (mounted) AppSnackbar.showError(context, 'Error deleting reminder: $e');
        }
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active, color: colorScheme.onSurface),
            onPressed: () async {
              final pending = await _notificationService.getPendingNotifications();
              if (!mounted) return;
              DialogHelper.showInfo(
                context,
                'Pending Notifications',
                pending.isEmpty
                    ? 'No pending notifications'
                    : pending.map((n) => '${n.id}: ${n.title}').join('\n'),
              );
            },
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text('Silahkan login terlebih dahulu'))
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
                        style: textTheme.titleLarge,
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
                  headerProps: const EasyHeaderProps(showHeader: false),
                  dayProps: EasyDayProps(
                    height: 100,
                    width: 60,
                    dayStructure: DayStructure.dayStrDayNum,
                    inactiveDayStyle: DayStyle(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      dayNumStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      dayStrStyle: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    activeDayStyle: DayStyle(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      dayNumStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                      dayStrStyle: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Reminders',
                                style: textTheme.titleMedium,
                              ),
                              Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                        Expanded(
                          child: StreamBuilder<List<ReminderData>>(
                            stream: _firebaseService.getReminderStream(user.email!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.event_note, size: 80, color: colorScheme.outlineVariant),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Belum ada reminder',
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
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
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
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
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.alarm,
                                            color: colorScheme.primary,
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
                                                style: textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                reminder.time,
                                                style: textTheme.bodySmall?.copyWith(
                                                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                                                ),
                                              ),
                                              if (reminder.description.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  reminder.description,
                                                  style: textTheme.labelSmall?.copyWith(
                                                    color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: colorScheme.error),
                                          onPressed: () => showDeleteDialog(reminder),
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
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah'),
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