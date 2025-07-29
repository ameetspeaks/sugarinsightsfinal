import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'notification_service.dart';

class ReminderScheduler {
  static final ReminderScheduler _instance = ReminderScheduler._internal();
  factory ReminderScheduler() => _instance;
  ReminderScheduler._internal();

  final NotificationService _notificationService = NotificationService();

  // Schedule reminders for a medication
  Future<void> scheduleMedicationReminders(Medication medication) async {
    // Cancel any existing reminders for this medication
    await cancelMedicationReminders(medication.id!);

    // Get the next occurrence for each time
    final now = DateTime.now();
    final List<DateTime> scheduleDates = [];

    // Calculate schedule based on frequency
    switch (medication.frequency.toLowerCase()) {
      case 'once daily':
        scheduleDates.add(_getNextOccurrence(medication.time));
        break;
      case 'twice daily':
        // Assuming times are stored in order
        for (var time in [medication.time, TimeOfDay(hour: (medication.time.hour + 12) % 24, minute: medication.time.minute)]) {
          scheduleDates.add(_getNextOccurrence(time));
        }
        break;
      case 'thrice daily':
        // Assuming 8-hour intervals
        for (var i = 0; i < 3; i++) {
          final time = TimeOfDay(
            hour: (medication.time.hour + (i * 8)) % 24,
            minute: medication.time.minute,
          );
          scheduleDates.add(_getNextOccurrence(time));
        }
        break;
      case 'four times daily':
        // Assuming 6-hour intervals
        for (var i = 0; i < 4; i++) {
          final time = TimeOfDay(
            hour: (medication.time.hour + (i * 6)) % 24,
            minute: medication.time.minute,
          );
          scheduleDates.add(_getNextOccurrence(time));
        }
        break;
    }

    // Schedule notifications for each date
    for (var date in scheduleDates) {
      if (date.isBefore(medication.endDate) && date.isAfter(now)) {
        // Schedule reminder notification (15 minutes before)
        final reminderTime = date.subtract(const Duration(minutes: 15));
        await _notificationService.scheduleMedicationReminder(
          id: _generateNotificationId(medication.id!, date, isReminder: true),
          title: 'Medication Reminder',
          body: 'Remember to take ${medication.name} ${medication.dosage} in 15 minutes',
          scheduledDate: reminderTime,
          payload: _generatePayload(medication, isReminder: true),
        );

        // Schedule alarm notification (at exact time)
        await _notificationService.scheduleMedicationReminder(
          id: _generateNotificationId(medication.id!, date, isReminder: false),
          title: 'Take Medication',
          body: 'Time to take ${medication.name} ${medication.dosage}',
          scheduledDate: date,
          payload: _generatePayload(medication, isReminder: false),
          isAlarm: true,
        );
      }
    }
  }

  // Cancel all reminders for a medication
  Future<void> cancelMedicationReminders(String medicationId) async {
    final now = DateTime.now();
    // Cancel reminders for the next 30 days (maximum possible scheduled reminders)
    for (var i = 0; i < 30; i++) {
      final date = now.add(Duration(days: i));
      await _notificationService.cancelNotification(
        _generateNotificationId(medicationId, date, isReminder: true),
      );
      await _notificationService.cancelNotification(
        _generateNotificationId(medicationId, date, isReminder: false),
      );
    }
  }

  // Get the next occurrence of a time
  DateTime _getNextOccurrence(TimeOfDay time) {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Generate a unique notification ID
  int _generateNotificationId(String medicationId, DateTime date, {required bool isReminder}) {
    // Use medication ID hash combined with date and type for uniqueness
    final baseId = medicationId.hashCode;
    final dateId = date.day + (date.month * 100) + (date.year * 10000);
    final typeId = isReminder ? 1 : 2;
    return (baseId + dateId + typeId).abs();
  }

  // Generate notification payload
  String _generatePayload(Medication medication, {required bool isReminder}) {
    return '{"type": "${isReminder ? 'reminder' : 'alarm'}", "medicationId": "${medication.id}"}';
  }
} 