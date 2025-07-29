import 'dart:async';
import 'dart:convert'; // Added missing import for json
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';
import 'notification_service.dart';
import 'reminder_scheduler.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final NotificationService _notificationService = NotificationService();
  final ReminderScheduler _reminderScheduler = ReminderScheduler();
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    // Background service initialized - simplified version without background_fetch
    print('[BackgroundService] Initialized');
  }

  // Check and reschedule medication reminders
  Future<void> _checkAndRescheduleMedications() async {
    try {
      // Get stored medications
      final medicationsJson = _prefs.getString('medications');
      if (medicationsJson == null) return;

      final List<dynamic> medicationsList = json.decode(medicationsJson);
      final List<Medication> medications = medicationsList
          .map((json) => Medication.fromJson(json))
          .where((med) => !med.isTaken && med.endDate.isAfter(DateTime.now()))
          .toList();

      // Check each medication
      for (var medication in medications) {
        // Get the next scheduled time
        final nextSchedule = _getNextMedicationTime(medication);
        if (nextSchedule != null) {
          // If it's within the next 15 minutes, schedule a notification
          final now = DateTime.now();
          final difference = nextSchedule.difference(now);
          if (difference.inMinutes <= 15 && difference.inMinutes > 0) {
            await _reminderScheduler.scheduleMedicationReminders(medication);
          }
        }
      }
    } catch (e) {
      print('Error checking medications: $e');
    }
  }

  // Get the next medication time
  DateTime? _getNextMedicationTime(Medication medication) {
    final now = DateTime.now();
    final baseTime = DateTime(
      now.year,
      now.month,
      now.day,
      medication.time.hour,
      medication.time.minute,
    );

    switch (medication.frequency.toLowerCase()) {
      case 'once daily':
        return baseTime.isBefore(now)
            ? baseTime.add(const Duration(days: 1))
            : baseTime;

      case 'twice daily':
        final times = [
          baseTime,
          baseTime.add(const Duration(hours: 12)),
        ];
        return _findNextTime(times, now);

      case 'thrice daily':
        final times = [
          baseTime,
          baseTime.add(const Duration(hours: 8)),
          baseTime.add(const Duration(hours: 16)),
        ];
        return _findNextTime(times, now);

      case 'four times daily':
        final times = [
          baseTime,
          baseTime.add(const Duration(hours: 6)),
          baseTime.add(const Duration(hours: 12)),
          baseTime.add(const Duration(hours: 18)),
        ];
        return _findNextTime(times, now);

      default:
        return null;
    }
  }

  // Find the next available time from a list of times
  DateTime? _findNextTime(List<DateTime> times, DateTime now) {
    DateTime? nextTime;
    for (var time in times) {
      if (time.isAfter(now)) {
        if (nextTime == null || time.isBefore(nextTime)) {
          nextTime = time;
        }
      }
    }
    if (nextTime == null && times.isNotEmpty) {
      // If no time is found today, get the first time tomorrow
      nextTime = times.first.add(const Duration(days: 1));
    }
    return nextTime;
  }

  // Stop background service
  Future<void> stop() async {
    print('[BackgroundService] Stopped');
  }
} 