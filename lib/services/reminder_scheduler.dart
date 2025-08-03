import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import '../models/medication.dart';

class ReminderScheduler {
  final SupabaseClient _supabase;
  final NotificationService _notificationService;

  // Configuration constants
  static const int _schedulingWindowDays = 30; // Schedule notifications for next 30 days
  static const int _maxNotificationsPerMedication = 100; // Safety limit
  static const Duration _backgroundCheckInterval = Duration(hours: 6); // Check every 6 hours

  ReminderScheduler(this._supabase, this._notificationService);

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize the reminder scheduler
  Future<void> initialize() async {
    try {
      print('🔔 Initializing ReminderScheduler...');
      
      // Ensure notification service is initialized
      await _notificationService.init();
      
      // Schedule background task to check and create new notifications
      await _scheduleBackgroundCheck();
      
      print('✅ ReminderScheduler initialized successfully');
    } catch (e) {
      print('❌ Error initializing ReminderScheduler: $e');
      throw 'Failed to initialize ReminderScheduler: $e';
    }
  }

  // ============================================================================
  // SCHEDULING METHODS
  // ============================================================================

  /// Schedule reminders for a medication (efficient approach)
  Future<void> scheduleMedicationReminders(Medication medication) async {
    try {
      print('🔔 Scheduling reminders for medication: ${medication.name}');
      
      // Cancel existing reminders for this medication
      await cancelMedicationReminders(medication.id!);

      // Generate reminder times for the scheduling window only
      final reminderTimes = _generateReminderTimesForWindow(medication);
      print('📅 Generated ${reminderTimes.length} reminder times for ${medication.name}');

      // Schedule each reminder
      for (int i = 0; i < reminderTimes.length; i++) {
        final scheduledTime = reminderTimes[i];
        final notificationId = _generateNotificationId(medication.id!, scheduledTime);

        print('⏰ Scheduling reminder $i for ${medication.name}:');
        print('   Time: $scheduledTime');
        print('   Notification ID: $notificationId');

        // Schedule the notification
        await _notificationService.scheduleMedicationReminderWithData(
          id: notificationId,
          title: 'Medication Reminder',
          body: 'Time to take ${medication.name} - ${medication.dosage}',
          scheduledDate: scheduledTime,
          medicationId: medication.id ?? '',
          medicationName: medication.name,
          dosage: medication.dosage,
          isAlarm: true,
        );

        // Get current user ID
        final currentUser = _supabase.auth.currentUser;
        if (currentUser == null) {
          throw 'User not authenticated';
        }

        // Store reminder in database
        await _supabase.from('medication_reminders').insert({
          'medication_id': medication.id,
          'user_id': currentUser.id,
          'notification_id': notificationId,
          'scheduled_time': scheduledTime.toIso8601String(),
          'is_active': true,
        });

        print('✅ Scheduled reminder $i for ${medication.name}');
      }

      print('✅ Successfully scheduled ${reminderTimes.length} reminders for ${medication.name}');
    } catch (e) {
      print('❌ Error scheduling medication reminders: $e');
      throw 'Failed to schedule medication reminders: $e';
    }
  }

  /// Update reminders for a medication
  Future<void> updateMedicationReminders(Medication medication) async {
    try {
      print('🔄 Updating reminders for medication: ${medication.name}');
      
      // Cancel existing reminders
      await cancelMedicationReminders(medication.id!);

      // Schedule new reminders
      await scheduleMedicationReminders(medication);
      
      print('✅ Successfully updated reminders for ${medication.name}');
    } catch (e) {
      print('❌ Error updating medication reminders: $e');
      throw 'Failed to update medication reminders: $e';
    }
  }

  /// Cancel all reminders for a medication
  Future<void> cancelMedicationReminders(String medicationId) async {
    try {
      print('❌ Cancelling reminders for medication: $medicationId');
      
      // Get active reminders for this medication
      final reminders = await _supabase
          .from('medication_reminders')
          .select('*')
          .eq('medication_id', medicationId)
          .eq('is_active', true);
      
      final medicationReminders = List<Map<String, dynamic>>.from(reminders);
      print('📋 Found ${medicationReminders.length} active reminders to cancel');

      // Cancel each notification
      for (final reminder in medicationReminders) {
        final notificationId = reminder['notification_id'] as int;
        await _notificationService.cancelNotification(notificationId);
        print('   Cancelled notification ID: $notificationId');
      }

      // Deactivate reminders in database
      await _supabase
          .from('medication_reminders')
          .update({'is_active': false})
          .eq('medication_id', medicationId);

      print('✅ Successfully cancelled reminders for medication: $medicationId');
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
      print('⏰ Snoozing medication reminder for: $medicationName');
      print('   Original notification ID: $originalNotificationId');
      print('   Snooze duration: $snoozeDuration');
      
      // Cancel the original notification
      await _notificationService.cancelNotification(originalNotificationId);

      // Create snoozed notification
      final snoozedTime = DateTime.now().add(snoozeDuration);
      final snoozedNotificationId = originalNotificationId + 1000;

      print('   Snoozed time: $snoozedTime');
      print('   Snoozed notification ID: $snoozedNotificationId');

      await _notificationService.scheduleMedicationReminderWithData(
        id: snoozedNotificationId,
        title: 'Medication Reminder (Snoozed)',
        body: 'Time to take $medicationName - $dosage',
        scheduledDate: snoozedTime,
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        isAlarm: true,
      );

      // Get current user ID
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Store snoozed reminder in database
      await _supabase.from('medication_reminders').insert({
        'medication_id': medicationId,
        'user_id': currentUser.id,
        'notification_id': snoozedNotificationId,
        'scheduled_time': snoozedTime.toIso8601String(),
        'is_active': true,
      });

      print('✅ Successfully snoozed medication reminder for $medicationName');
    } catch (e) {
      print('❌ Error snoozing medication reminder: $e');
      throw 'Failed to snooze medication reminder: $e';
    }
  }

  // ============================================================================
  // BACKGROUND TASKS
  // ============================================================================

  /// Schedule background check for new notifications
  Future<void> _scheduleBackgroundCheck() async {
    try {
      print('⏰ Scheduling background check for medication reminders...');
      
      // Schedule a notification to trigger background check
      final checkTime = DateTime.now().add(_backgroundCheckInterval);
      final checkId = DateTime.now().millisecondsSinceEpoch % 2147483647;
      
      await _notificationService.scheduleMedicationReminderWithData(
        id: checkId,
        title: 'Background Check',
        body: 'Checking for new medication reminders',
        scheduledDate: checkTime,
        medicationId: 'background-check',
        medicationName: 'Background Check',
        dosage: '1',
        isAlarm: false,
      );
      
      print('✅ Background check scheduled for $checkTime');
    } catch (e) {
      print('❌ Error scheduling background check: $e');
    }
  }

  /// Check and create new notifications for all active medications
  Future<void> checkAndCreateNewNotifications() async {
    try {
      print('🔍 Checking for new medication notifications...');
      
      // Get all active medications
      final medications = await _supabase
          .from('medications')
          .select('*')
          .eq('is_active', true);
      
      final activeMedications = List<Map<String, dynamic>>.from(medications);
      print('📋 Found ${activeMedications.length} active medications');

      for (final medicationData in activeMedications) {
        final medication = Medication.fromJson(medicationData);
        
        // Check if this medication needs new notifications
        final needsNewNotifications = await _checkIfMedicationNeedsNewNotifications(medication);
        
        if (needsNewNotifications) {
          print('🔄 Creating new notifications for ${medication.name}');
          await _createNewNotificationsForMedication(medication);
        } else {
          print('✅ ${medication.name} has sufficient notifications scheduled');
        }
      }
      
      // Schedule next background check
      await _scheduleBackgroundCheck();
      
      print('✅ Background check completed');
    } catch (e) {
      print('❌ Error in background check: $e');
    }
  }

  /// Check if a medication needs new notifications
  Future<bool> _checkIfMedicationNeedsNewNotifications(Medication medication) async {
    try {
      // Get the latest scheduled notification for this medication
      final latestReminder = await _supabase
          .from('medication_reminders')
          .select('scheduled_time')
          .eq('medication_id', medication.id)
          .eq('is_active', true)
          .gt('scheduled_time', DateTime.now().toIso8601String())
          .order('scheduled_time', ascending: false)
          .limit(1)
          .single();

      if (latestReminder == null) {
        print('   No future notifications found for ${medication.name}');
        return true;
      }

      final latestTime = DateTime.parse(latestReminder['scheduled_time']);
      final daysUntilLatest = latestTime.difference(DateTime.now()).inDays;
      
      print('   Latest notification for ${medication.name}: $latestTime (${daysUntilLatest} days away)');
      
      // If the latest notification is within 7 days, we need to create more
      return daysUntilLatest < 7;
    } catch (e) {
      print('   Error checking notifications for ${medication.name}: $e');
      return true; // Default to creating new notifications if there's an error
    }
  }

  /// Create new notifications for a medication
  Future<void> _createNewNotificationsForMedication(Medication medication) async {
    try {
      // Get the latest scheduled notification time
      final latestReminder = await _supabase
          .from('medication_reminders')
          .select('scheduled_time')
          .eq('medication_id', medication.id)
          .eq('is_active', true)
          .order('scheduled_time', ascending: false)
          .limit(1)
          .single();

      DateTime startDate;
      if (latestReminder != null) {
        // Start from the day after the latest notification
        startDate = DateTime.parse(latestReminder['scheduled_time']).add(const Duration(days: 1));
      } else {
        // Start from today
        startDate = DateTime.now();
      }

      // Generate new reminder times
      final newReminderTimes = _generateReminderTimesFromDate(medication, startDate);
      print('   Generated ${newReminderTimes.length} new reminder times for ${medication.name}');

      // Schedule new notifications
      for (int i = 0; i < newReminderTimes.length; i++) {
        final scheduledTime = newReminderTimes[i];
        final notificationId = _generateNotificationId(medication.id!, scheduledTime);

        await _notificationService.scheduleMedicationReminderWithData(
          id: notificationId,
          title: 'Medication Reminder',
          body: 'Time to take ${medication.name} - ${medication.dosage}',
          scheduledDate: scheduledTime,
          medicationId: medication.id ?? '',
          medicationName: medication.name,
          dosage: medication.dosage,
          isAlarm: true,
        );

        // Get current user ID
        final currentUser = _supabase.auth.currentUser;
        if (currentUser == null) {
          throw 'User not authenticated';
        }

        // Store reminder in database
        await _supabase.from('medication_reminders').insert({
          'medication_id': medication.id ?? '',
          'user_id': currentUser.id,
          'notification_id': notificationId,
          'scheduled_time': scheduledTime.toIso8601String(),
          'is_active': true,
        });
      }

      print('   ✅ Created ${newReminderTimes.length} new notifications for ${medication.name}');
    } catch (e) {
      print('   ❌ Error creating new notifications for ${medication.name}: $e');
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Generate reminder times for the scheduling window only
  List<DateTime> _generateReminderTimesForWindow(Medication medication) {
    final List<DateTime> reminderTimes = [];
    final now = DateTime.now();
    final startDate = medication.startDate.isAfter(now) ? medication.startDate : now;
    
    // Only schedule for the next 30 days
    final endDate = startDate.add(Duration(days: _schedulingWindowDays));

    print('🔔 Generating reminder times for ${medication.name} (window approach)');
    print('   Current time: $now');
    print('   Start date: $startDate');
    print('   End date: $endDate (${_schedulingWindowDays} days window)');
    print('   Medication times: ${medication.times}');

    // Generate times for each day from start to end date
    DateTime currentDate = startDate;
    int dayCount = 0;
    
    while (currentDate.isBefore(endDate) && dayCount < _schedulingWindowDays) {
      // Check if this is today
      final isToday = currentDate.year == now.year && 
                     currentDate.month == now.month && 
                     currentDate.day == now.day;
      
      // Add reminder times for this day
      for (final time in medication.times) {
        // Create DateTime in IST timezone
        final reminderTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          time.hour,
          time.minute,
        );

        // For today: only add if the time hasn't passed yet (with 5 minute buffer)
        // For future days: add all times
        if (isToday) {
          final bufferTime = now.add(const Duration(minutes: 5));
          if (reminderTime.isAfter(bufferTime)) {
            reminderTimes.add(reminderTime);
            print('   ✅ Added today reminder: $reminderTime');
          } else {
            print('   ⏰ Skipped past time: $reminderTime (now: $now)');
          }
        } else {
          // Future day - add all times
          reminderTimes.add(reminderTime);
          print('   ✅ Added future reminder: $reminderTime');
        }
      }

      // Move to next day
      currentDate = currentDate.add(const Duration(days: 1));
      dayCount++;
    }

    print('   Total reminder times generated: ${reminderTimes.length}');
    
    // Safety check: limit the number of notifications
    if (reminderTimes.length > _maxNotificationsPerMedication) {
      print('⚠️ Warning: Generated ${reminderTimes.length} reminders, limiting to $_maxNotificationsPerMedication');
      reminderTimes.removeRange(_maxNotificationsPerMedication, reminderTimes.length);
    }
    
    return reminderTimes;
  }

  /// Generate reminder times from a specific start date
  List<DateTime> _generateReminderTimesFromDate(Medication medication, DateTime startDate) {
    final List<DateTime> reminderTimes = [];
    final now = DateTime.now();
    
    // Only schedule for the next 30 days from start date
    final endDate = startDate.add(Duration(days: _schedulingWindowDays));

    print('   Generating reminder times from $startDate to $endDate');

    // Generate times for each day from start to end date
    DateTime currentDate = startDate;
    int dayCount = 0;
    
    while (currentDate.isBefore(endDate) && dayCount < _schedulingWindowDays) {
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
      dayCount++;
    }

    print('   Generated ${reminderTimes.length} new reminder times');
    
    // Safety check: limit the number of notifications
    if (reminderTimes.length > _maxNotificationsPerMedication) {
      print('   ⚠️ Warning: Generated ${reminderTimes.length} reminders, limiting to $_maxNotificationsPerMedication');
      reminderTimes.removeRange(_maxNotificationsPerMedication, reminderTimes.length);
    }
    
    return reminderTimes;
  }

  /// Generate unique notification ID based on medication ID and time
  int _generateNotificationId(String medicationId, DateTime scheduledTime) {
    // Create a hash from medication ID and scheduled time
    final hash = medicationId.hashCode + scheduledTime.millisecondsSinceEpoch;
    return hash.abs() % 2147483647; // Ensure 32-bit integer
  }

  /// Handle timezone changes
  Future<void> handleTimezoneChange() async {
    try {
      // Get all active medications
      final medications = await _supabase.from('medications').select('*').eq('is_active', true);
      
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

  /// Check for missed medications
  Future<void> checkMissedMedications() async {
    try {
      print('🔍 Checking for missed medications...');
      
      // Get medications that should have been taken but weren't
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      
      // Get all active medications
      final medications = await _supabase
          .from('medications')
          .select('*')
          .eq('is_active', true);
      
      final activeMedications = List<Map<String, dynamic>>.from(medications);
      print('📋 Found ${activeMedications.length} active medications');

      for (final medicationData in activeMedications) {
        final medication = Medication.fromJson(medicationData);
        
        // Check if this medication needs immediate scheduling
        await scheduleImmediateNotifications(medication);
      }
      
      print('✅ Missed medication check completed');
    } catch (e) {
      print('❌ Error checking missed medications: $e');
    }
  }

  /// Schedule notifications for medications due within the next hour
  Future<void> scheduleImmediateNotifications(Medication medication) async {
    try {
      final now = DateTime.now();
      final oneHourFromNow = now.add(const Duration(hours: 1));
      
      print('🔔 Checking immediate notifications for ${medication.name}');
      print('   Current time: $now');
      print('   Current timezone: ${now.timeZoneName}');
      print('   UTC offset: ${now.timeZoneOffset}');
      print('   One hour from now: $oneHourFromNow');
      
      // Check each medication time
      for (final time in medication.times) {
        final todayScheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
        
        print('   Checking time: ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
        print('   Scheduled time: $todayScheduledTime');
        print('   Is in future: ${todayScheduledTime.isAfter(now)}');
        print('   Is within next hour: ${todayScheduledTime.isBefore(oneHourFromNow)}');
        print('   Time difference: ${todayScheduledTime.difference(now).inMinutes} minutes');
        
        // Only schedule if the time is in the future AND within the next hour
        if (todayScheduledTime.isAfter(now) && todayScheduledTime.isBefore(oneHourFromNow)) {
          print('   ⏰ Scheduling immediate notification for ${medication.name} at $todayScheduledTime');
          
          try {
            final notificationId = _generateNotificationId(medication.id!, todayScheduledTime);
            
            // Cancel any existing notification with the same ID first
            await _notificationService.cancelNotification(notificationId);
            
            await _notificationService.scheduleMedicationReminderWithData(
              id: notificationId,
              title: 'Medication Reminder',
              body: 'Time to take ${medication.name} - ${medication.dosage}',
              scheduledDate: todayScheduledTime,
              medicationId: medication.id ?? '',
              medicationName: medication.name,
              dosage: medication.dosage,
              isAlarm: true,
            );
            
            print('   ✅ Immediate notification scheduled for ${medication.name}');
          } catch (e) {
            print('   ❌ Error scheduling immediate notification for ${medication.name}: $e');
          }
        } else {
          if (todayScheduledTime.isBefore(now)) {
            print('   ⏰ Skipped past time: $todayScheduledTime (already passed by ${now.difference(todayScheduledTime).inMinutes} minutes)');
          } else {
            print('   ⏰ Skipped future time: $todayScheduledTime (more than 1 hour away)');
          }
        }
      }
    } catch (e) {
      print('❌ Error scheduling immediate notifications for ${medication.name}: $e');
    }
  }

  /// Schedule notifications for the next occurrence of each medication time
  Future<void> scheduleNextOccurrenceNotifications(Medication medication) async {
    try {
      final now = DateTime.now();
      
      print('🔔 Scheduling next occurrence notifications for ${medication.name}');
      print('   Current time: $now');
      print('   Current timezone: ${now.timeZoneName}');
      print('   UTC offset: ${now.timeZoneOffset}');
      
      // Check each medication time
      for (final time in medication.times) {
        final todayScheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
        
        print('   Checking time: ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
        print('   Today scheduled time: $todayScheduledTime');
        print('   Is today\'s time in past: ${todayScheduledTime.isBefore(now)}');
        
        // If today's time has passed, schedule for tomorrow
        DateTime nextOccurrence;
        if (todayScheduledTime.isBefore(now)) {
          nextOccurrence = todayScheduledTime.add(const Duration(days: 1));
          print('   ⏰ Today\'s time ${time.hour}:${time.minute.toString().padLeft(2, '0')} has passed, scheduling for tomorrow: $nextOccurrence');
        } else {
          nextOccurrence = todayScheduledTime;
          print('   ⏰ Scheduling for today: $nextOccurrence');
        }
        
        final notificationId = _generateNotificationId(medication.id!, nextOccurrence);
        
        // Schedule the notification
        await _notificationService.scheduleMedicationReminderWithData(
          id: notificationId,
          title: 'Medication Reminder',
          body: 'Time to take ${medication.name} - ${medication.dosage}',
          scheduledDate: nextOccurrence,
          medicationId: medication.id ?? '',
          medicationName: medication.name,
          dosage: medication.dosage,
          isAlarm: true,
        );
        
        print('   ✅ Next occurrence notification scheduled for ${medication.name} at $nextOccurrence');
      }
    } catch (e) {
      print('❌ Error scheduling next occurrence notifications for ${medication.name}: $e');
    }
  }

  /// Get next medication reminder
  Future<Map<String, dynamic>?> getNextMedicationReminder() async {
    try {
      final nextReminder = await _supabase
          .from('medication_reminders')
          .select('*, medications(*)')
          .eq('is_active', true)
          .gt('scheduled_time', DateTime.now().toIso8601String())
          .order('scheduled_time', ascending: true)
          .limit(1)
          .single();

      return nextReminder;
    } catch (e) {
      print('❌ Error getting next medication reminder: $e');
      return null;
    }
  }

  /// Reschedule missed reminders
  Future<void> rescheduleMissedReminders() async {
    try {
      print('🔄 Rescheduling missed reminders...');
      
      // Get all active medications
      final medications = await _supabase.from('medications').select('*').eq('is_active', true);
      
      for (final medicationData in medications) {
        final medication = Medication.fromJson(medicationData);
        
        // Check if this medication needs rescheduling
        final needsRescheduling = await _checkIfMedicationNeedsNewNotifications(medication);
        
        if (needsRescheduling) {
          print('   Rescheduling ${medication.name}');
          await _createNewNotificationsForMedication(medication);
        }
      }

      print('✅ Rescheduled missed reminders');
    } catch (e) {
      print('❌ Error rescheduling missed reminders: $e');
    }
  }
} 