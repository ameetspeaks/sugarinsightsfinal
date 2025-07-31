import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'medication_service.dart';
import 'notification_service.dart';
import '../models/medication.dart';

class ReminderScheduler {
  final MedicationService _medicationService;
  final NotificationService _notificationService;

  ReminderScheduler(this._medicationService, this._notificationService);

  // ============================================================================
  // SCHEDULING METHODS
  // ============================================================================

  /// Schedule reminders for a medication
  Future<void> scheduleMedicationReminders(Medication medication) async {
    try {
      // Cancel existing reminders for this medication
      await cancelMedicationReminders(medication.id!);

      // Generate reminder times based on frequency and times
      final reminderTimes = _generateReminderTimes(medication);

      // Schedule each reminder
      for (int i = 0; i < reminderTimes.length; i++) {
        final scheduledTime = reminderTimes[i];
        final notificationId = _generateNotificationId(medication.id!, i);

        // Schedule the notification
        await _notificationService.scheduleMedicationReminderWithData(
          id: notificationId,
          medicationName: medication.name,
          dosage: medication.dosage,
          scheduledDate: scheduledTime,
          medicationId: medication.id,
          notes: medication.notes,
        );

        // Store reminder in database
        await _medicationService.createMedicationReminder(
          medication.id!,
          notificationId,
          scheduledTime,
        );
      }

      print('✅ Scheduled ${reminderTimes.length} reminders for ${medication.name}');
    } catch (e) {
      print('❌ Error scheduling medication reminders: $e');
      throw 'Failed to schedule medication reminders: $e';
    }
  }

  /// Update reminders for a medication
  Future<void> updateMedicationReminders(Medication medication) async {
    try {
      // Cancel existing reminders
      await cancelMedicationReminders(medication.id!);
      
      // Schedule new reminders
      await scheduleMedicationReminders(medication);
    } catch (e) {
      throw 'Failed to update medication reminders: $e';
    }
  }

  /// Cancel all reminders for a medication
  Future<void> cancelMedicationReminders(String medicationId) async {
    try {
      // Get active reminders for this medication
      final reminders = await _medicationService.getActiveReminders();
      final medicationReminders = reminders.where((r) => r['medication_id'] == medicationId).toList();

      // Cancel each notification
      for (final reminder in medicationReminders) {
        final notificationId = reminder['notification_id'] as int;
        await _notificationService.cancelNotification(notificationId);
      }

      // Deactivate reminders in database
      await _medicationService.deactivateMedicationReminders(medicationId);

      print('✅ Cancelled reminders for medication: $medicationId');
    } catch (e) {
      print('❌ Error cancelling medication reminders: $e');
      throw 'Failed to cancel medication reminders: $e';
    }
  }

  /// Snooze a medication reminder
  Future<void> snoozeMedicationReminder({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required Duration snoozeDuration,
    required int originalNotificationId,
  }) async {
    try {
      // Cancel the original notification
      await _notificationService.cancelNotification(originalNotificationId);

      // Create snoozed notification
      final snoozedTime = DateTime.now().add(snoozeDuration);
      final snoozedNotificationId = originalNotificationId + 1000;

      await _notificationService.scheduleMedicationReminderWithData(
        id: snoozedNotificationId,
        medicationName: medicationName,
        dosage: dosage,
        scheduledDate: snoozedTime,
        medicationId: medicationId,
      );

      // Store snoozed reminder in database
      await _medicationService.createMedicationReminder(
        medicationId,
        snoozedNotificationId,
        snoozedTime,
      );

      print('✅ Snoozed medication reminder for $medicationName');
    } catch (e) {
      print('❌ Error snoozing medication reminder: $e');
      throw 'Failed to snooze medication reminder: $e';
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Generate reminder times for a medication based on frequency and times
  List<DateTime> _generateReminderTimes(Medication medication) {
    final List<DateTime> reminderTimes = [];
    final now = DateTime.now();
    final startDate = medication.startDate.isAfter(now) ? medication.startDate : now;
    final endDate = medication.endDate ?? startDate.add(const Duration(days: 365));

    // Generate times for each day from start to end date
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      // Add reminder times for this day
      for (final time in medication.times) {
        final reminderTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          time.hour,
          time.minute,
        );

        // Only add if the time is in the future
        if (reminderTime.isAfter(now)) {
          reminderTimes.add(reminderTime);
        }
      }

      // Move to next day
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return reminderTimes;
  }

  /// Generate unique notification ID
  int _generateNotificationId(String medicationId, int timeIndex) {
    // Create a hash from medication ID and time index
    final hash = medicationId.hashCode + timeIndex;
    return hash.abs(); // Ensure positive ID
  }

  /// Handle timezone changes
  Future<void> handleTimezoneChange() async {
    try {
      // Get all active medications
      final medications = await _medicationService.getMedications();
      
      // Reschedule all reminders
      for (final medication in medications) {
        await updateMedicationReminders(medication);
      }

      print('✅ Rescheduled all reminders after timezone change');
    } catch (e) {
      print('❌ Error handling timezone change: $e');
      throw 'Failed to handle timezone change: $e';
    }
  }

  /// Check for missed medications and send notifications
  Future<void> checkMissedMedications() async {
    try {
      final today = DateTime.now();
      final missedCount = await _medicationService.getMissedMedicationsCount(today);

      if (missedCount > 0) {
        await _notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch,
          title: 'Missed Medications',
          body: 'You have $missedCount missed medication(s) today',
          payload: 'missed_medications',
        );
      }
    } catch (e) {
      print('❌ Error checking missed medications: $e');
    }
  }

  /// Get next medication reminder time
  Future<DateTime?> getNextMedicationReminder() async {
    try {
      final reminders = await _medicationService.getActiveReminders();
      
      if (reminders.isEmpty) {
        return null;
      }

      // Find the earliest future reminder
      final now = DateTime.now();
      DateTime? nextReminder;
      
      for (final reminder in reminders) {
        final scheduledTime = DateTime.parse(reminder['scheduled_time']);
        if (scheduledTime.isAfter(now)) {
          if (nextReminder == null || scheduledTime.isBefore(nextReminder)) {
            nextReminder = scheduledTime;
          }
        }
      }

      return nextReminder;
    } catch (e) {
      print('❌ Error getting next medication reminder: $e');
      return null;
    }
  }

  /// Reschedule missed reminders
  Future<void> rescheduleMissedReminders() async {
    try {
      final medications = await _medicationService.getMedications();
      
      for (final medication in medications) {
        // Check if medication is active and has missed times
        if (medication.isActive) {
          final today = DateTime.now();
          final missedTimes = _getMissedTimesForToday(medication, today);
          
          if (missedTimes.isNotEmpty) {
            // Reschedule missed reminders
            for (final missedTime in missedTimes) {
              final notificationId = _generateNotificationId(medication.id!, missedTimes.indexOf(missedTime));
              
              await _notificationService.scheduleMedicationReminderWithData(
                id: notificationId,
                medicationName: medication.name,
                dosage: medication.dosage,
                scheduledDate: missedTime,
                medicationId: medication.id,
                notes: 'Missed reminder rescheduled',
              );
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error rescheduling missed reminders: $e');
    }
  }

  /// Get missed times for today
  List<DateTime> _getMissedTimesForToday(Medication medication, DateTime today) {
    final List<DateTime> missedTimes = [];
    final now = DateTime.now();
    
    for (final time in medication.times) {
      final scheduledTime = DateTime(
        today.year,
        today.month,
        today.day,
        time.hour,
        time.minute,
      );
      
      // Check if this time has passed and medication wasn't taken
      if (scheduledTime.isBefore(now)) {
        // TODO: Check if medication was actually taken at this time
        // For now, we'll assume it was missed
        missedTimes.add(scheduledTime);
      }
    }
    
    return missedTimes;
  }

  /// Initialize reminder scheduler
  Future<void> initialize() async {
    try {
      // Set up timezone
      final String timeZoneName = DateTime.now().timeZoneName;
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // Check for missed medications
      await checkMissedMedications();

      print('✅ Reminder scheduler initialized');
    } catch (e) {
      print('❌ Error initializing reminder scheduler: $e');
      throw 'Failed to initialize reminder scheduler: $e';
    }
  }
} 