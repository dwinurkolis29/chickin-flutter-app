import 'package:flutter/material.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/services/notification_service.dart';
import 'package:recording_app/core/services/reminder_local_service.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/features/reminder/data/models/reminder_data.dart';
import 'package:recording_app/features/reminder/presentation/form_reminder.dart';
import 'package:recording_app/core/components/header/app_header.dart';

class Reminder extends StatefulWidget {
  const Reminder({super.key});

  @override
  State<Reminder> createState() => _ReminderState();
}

class _ReminderState extends State<Reminder> {
  final _localService = ReminderLocalService();
  final _notificationService = NotificationService();

  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();

  List<ReminderData> _filterByDate(List<ReminderData> all) {
    final selectedStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    return all.where((r) => r.date == selectedStr).toList();
  }

  Future<void> _deleteReminder(ReminderData reminder) async {
    final confirmed = await DialogHelper.showConfirm(
      context,
      'Hapus Reminder',
      'Yakin ingin menghapus reminder ini?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final notifId = int.tryParse(reminder.id) ?? reminder.id.hashCode;
        await _notificationService.cancelNotification(notifId);
        await _localService.deleteReminder(reminder.id);
        if (mounted) AppSnackbar.showSuccess(context, 'Reminder dihapus');
      } catch (e) {
        if (mounted) AppSnackbar.showError(context, 'Gagal menghapus: $e');
      }
    }
  }

  void _openForm({ReminderData? editReminder}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormReminder(editReminder: editReminder),
      ),
    );
    if (result == true) setState(() {});
  }

  void _showMonthCalendar() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    DialogHelper.showBottomSheet(
      context,
      backgroundColor: Colors.transparent,
      builder: SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMMM yyyy').format(focusedDate), style: tt.titleLarge),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() => focusedDate = DateTime(focusedDate.year, focusedDate.month - 1));
                              Navigator.pop(context);
                              _showMonthCalendar();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() => focusedDate = DateTime(focusedDate.year, focusedDate.month + 1));
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
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildMonthCalendar(cs, tt),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthCalendar(ColorScheme cs, TextTheme tt) {
    final firstDay = DateTime(focusedDate.year, focusedDate.month, 1);
    final lastDay = DateTime(focusedDate.year, focusedDate.month + 1, 0);
    final startWeekday = firstDay.weekday - 1;

    final days = <Widget>[
      for (int i = 0; i < startWeekday; i++) const SizedBox(width: 40, height: 40),
      for (int day = 1; day <= lastDay.day; day++) _buildDayCell(day, cs, tt),
    ];

    final weeks = <Widget>[];
    for (int i = 0; i < days.length; i += 7) {
      final weekDays = days.sublist(i, (i + 7).clamp(0, days.length));
      while (weekDays.length < 7) { weekDays.add(const SizedBox(width: 40, height: 40)); }
      weeks.add(Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: weekDays));
      weeks.add(const SizedBox(height: 8));
    }

    return Column(children: weeks);
  }

  Widget _buildDayCell(int day, ColorScheme cs, TextTheme tt) {
    final current = DateTime(focusedDate.year, focusedDate.month, day);
    final isSelected = selectedDate.year == current.year &&
        selectedDate.month == current.month &&
        selectedDate.day == current.day;
    final isToday = DateTime.now().year == current.year &&
        DateTime.now().month == current.month &&
        DateTime.now().day == current.day;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDate = current;
          focusedDate = current;
        });
        Navigator.pop(context);
      },
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected ? Border.all(color: cs.primary, width: 2) : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: tt.bodyMedium?.copyWith(
              color: isSelected ? cs.onPrimary : cs.onSurface,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      backgroundColor: cs.surfaceContainerLow,
      appBar: const AppHeader(title: 'Reminder'),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMM yyyy').format(focusedDate), style: tt.titleLarge),
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
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        dayNumStyle: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                        dayStrStyle: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      activeDayStyle: DayStyle(
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        dayNumStyle: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimary,
                        ),
                        dayStrStyle: tt.bodySmall?.copyWith(
                          color: cs.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
          body: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text('Reminders', style: tt.titleMedium),
                  ),
                ),
                _buildReminderList(cs, tt),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderList(ColorScheme cs, TextTheme tt) {
    // Pakai StreamBuilder reactive dari Hive watchAll
    return StreamBuilder<List<ReminderData>>(
      stream: _localService.watchReminders(),
      // initialData agar tidak kosong saat pertama load
      initialData: _localService.getAllReminders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: AppErrorState(
              message: 'Gagal memuat data reminder',
              subtitle: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            ),
          );
        }

        final all = snapshot.data ?? [];
        final filtered = _filterByDate(all);

        if (all.isEmpty) {
          return const SliverFillRemaining(
            child: AppEmptyState(
              icon: Icons.event_note_outlined,
              message: 'Belum ada reminder',
              subtitle: 'Klik tombol + untuk menambah reminder',
            ),
          );
        }

        if (filtered.isEmpty) {
          return const SliverFillRemaining(
            child: AppEmptyState(
              icon: Icons.event_busy_outlined,
              message: 'Tidak ada reminder',
              subtitle: 'Tidak ada reminder untuk tanggal ini',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final reminder = filtered[index];
                return _ReminderCard(
                  reminder: reminder,
                  onTap: () => _openForm(editReminder: reminder),
                  onDelete: () => _deleteReminder(reminder),
                );
              },
              childCount: filtered.length,
            ),
          ),
        );
      },
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderData reminder;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.alarm, color: cs.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reminder.time,
                      style: tt.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (reminder.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.description,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
