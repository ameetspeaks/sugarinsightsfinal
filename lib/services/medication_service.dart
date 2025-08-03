import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'notification_service.dart';
import 'reminder_scheduler.dart';

class MedicationService {
  static MedicationService? _instance;
  final SupabaseClient _supabase;
  late final NotificationService _notificationService;
  late final ReminderScheduler _reminderScheduler;

  MedicationService._internal(this._supabase);

  static MedicationService get instance {
    if (_instance == null) {
      _instance = MedicationService._internal(Supabase.instance.client);
    }
    return _instance!;
  }

  static MedicationService create(SupabaseClient supabase) {
    if (_instance == null) {
      _instance = MedicationService._internal(supabase);
    }
    return _instance!;
  }

  /// Initialize the medication service
  Future<void> initialize() async {
    try {
      print('🔧 Initializing MedicationService...');
      
      // Initialize notification service
      _notificationService = NotificationService();
      await _notificationService.init();
      
      // Initialize reminder scheduler
      _reminderScheduler = ReminderScheduler(_supabase, _notificationService);
      await _reminderScheduler.initialize();
      
      print('✅ MedicationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing MedicationService: $e');
      throw 'Failed to initialize MedicationService: $e';
    }
  }

  // ============================================================================
  // NOTIFICATION INTEGRATION
  // ============================================================================

  /// Schedule notifications for a medication
  Future<void> scheduleMedicationNotifications(Medication medication) async {
    try {
      print('🔔 Scheduling notifications for medication: ${medication.name}');
      
      // Use the reminder scheduler to handle notification scheduling
      await _reminderScheduler.scheduleMedicationReminders(medication);
      
      print('✅ Successfully scheduled notifications for ${medication.name}');
    } catch (e) {
      print('❌ Error scheduling medication notifications: $e');
      throw 'Failed to schedule medication notifications: $e';
    }
  }

  /// Update notifications for a medication
  Future<void> updateMedicationNotifications(Medication medication) async {
    try {
      print('🔄 Updating notifications for medication: ${medication.name}');
      
      await _reminderScheduler.updateMedicationReminders(medication);
      
      print('✅ Successfully updated notifications for ${medication.name}');
    } catch (e) {
      print('❌ Error updating medication notifications: $e');
      throw 'Failed to update medication notifications: $e';
    }
  }

  /// Cancel notifications for a medication
  Future<void> cancelMedicationNotifications(String medicationId) async {
    try {
      print('❌ Cancelling notifications for medication: $medicationId');
      
      await _reminderScheduler.cancelMedicationReminders(medicationId);
      
      print('✅ Successfully cancelled notifications for medication: $medicationId');
    } catch (e) {
      print('❌ Error cancelling medication notifications: $e');
      throw 'Failed to cancel medication notifications: $e';
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
      
      await _reminderScheduler.snoozeMedicationReminder(
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        snoozeDuration: snoozeDuration,
        originalNotificationId: originalNotificationId,
      );
      
      print('✅ Successfully snoozed reminder for $medicationName');
    } catch (e) {
      print('❌ Error snoozing medication reminder: $e');
      throw 'Failed to snooze medication reminder: $e';
    }
  }

  /// Show medication taken notification
  Future<void> showMedicationTakenNotification(String medicationName) async {
    try {
      await _notificationService.showMedicationTakenNotification(
        medicationName: medicationName,
        dosage: 1,
        medicationId: 'taken-$medicationName',
      );
      print('✅ Showed medication taken notification for $medicationName');
    } catch (e) {
      print('❌ Error showing medication taken notification: $e');
    }
  }

  /// Show medication skipped notification
  Future<void> showMedicationSkippedNotification(String medicationName) async {
    try {
      await _notificationService.showMedicationSkippedNotification(
        medicationName: medicationName,
        dosage: 1,
        medicationId: 'skipped-$medicationName',
      );
      print('✅ Showed medication skipped notification for $medicationName');
    } catch (e) {
      print('❌ Error showing medication skipped notification: $e');
    }
  }

  /// Reschedule all active medications (for fixing notification issues)
  Future<void> rescheduleAllActiveMedications() async {
    try {
      print('🔄 Rescheduling all active medications...');
      
      // Get all active medications
      final medications = await getMedications();
      final activeMedications = medications.where((med) => med.isActive).toList();
      
      print('📋 Found ${activeMedications.length} active medications to reschedule');
      
      for (final medication in activeMedications) {
        try {
          print('🔄 Rescheduling notifications for: ${medication.name}');
          await scheduleMedicationNotifications(medication);
          print('✅ Successfully rescheduled notifications for: ${medication.name}');
        } catch (e) {
          print('❌ Error rescheduling notifications for ${medication.name}: $e');
        }
      }
      
      print('✅ Completed rescheduling all active medications');
    } catch (e) {
      print('❌ Error rescheduling all active medications: $e');
      throw 'Failed to reschedule all active medications: $e';
    }
  }

  /// Schedule immediate notifications for medications due soon
  Future<void> scheduleImmediateNotifications() async {
    try {
      print('🔔 Scheduling immediate notifications for medications due soon...');
      
      // Get all active medications
      final medications = await getMedications();
      final activeMedications = medications.where((med) => med.isActive).toList();
      
      print('📋 Found ${activeMedications.length} active medications to check');
      
      for (final medication in activeMedications) {
        try {
          await _reminderScheduler.scheduleImmediateNotifications(medication);
        } catch (e) {
          print('❌ Error scheduling immediate notifications for ${medication.name}: $e');
        }
      }
      
      print('✅ Completed scheduling immediate notifications');
    } catch (e) {
      print('❌ Error scheduling immediate notifications: $e');
      throw 'Failed to schedule immediate notifications: $e';
    }
  }

  /// Schedule next occurrence notifications for all medications
  Future<void> scheduleNextOccurrenceNotifications() async {
    try {
      print('🔔 Scheduling next occurrence notifications for all medications...');
      
      // Get all active medications
      final medications = await getMedications();
      final activeMedications = medications.where((med) => med.isActive).toList();
      
      print('📋 Found ${activeMedications.length} active medications to schedule');
      
      for (final medication in activeMedications) {
        try {
          await _reminderScheduler.scheduleNextOccurrenceNotifications(medication);
        } catch (e) {
          print('❌ Error scheduling next occurrence notifications for ${medication.name}: $e');
        }
      }
      
      print('✅ Completed scheduling next occurrence notifications');
    } catch (e) {
      print('❌ Error scheduling next occurrence notifications: $e');
      throw 'Failed to schedule next occurrence notifications: $e';
    }
  }

  /// Check and fix timezone issues for medication scheduling
  Future<void> checkAndFixTimezoneIssues() async {
    try {
      print('🌍 Checking and fixing timezone issues...');
      
      // Get current time in IST
      final now = DateTime.now();
      print('   Current time: $now');
      print('   Current timezone: ${now.timeZoneName}');
      
      // Check if we're in IST (UTC+5:30)
      final utcOffset = now.timeZoneOffset;
      final istOffset = const Duration(hours: 5, minutes: 30);
      
      if (utcOffset != istOffset) {
        print('   ⚠️ Warning: Not in IST timezone. Current offset: $utcOffset, Expected: $istOffset');
        print('   📝 This may cause notification timing issues');
      } else {
        print('   ✅ Timezone is correct (IST)');
      }
      
      // Reschedule all medications to ensure proper timing
      await rescheduleAllActiveMedications();
      
      print('✅ Timezone check and fix completed');
    } catch (e) {
      print('❌ Error checking and fixing timezone issues: $e');
      throw 'Failed to check and fix timezone issues: $e';
    }
  }

  /// Get next medication reminder time
  Future<DateTime?> getNextMedicationReminder() async {
    try {
      final nextReminder = await _reminderScheduler.getNextMedicationReminder();
      if (nextReminder != null && nextReminder['scheduled_time'] != null) {
        return DateTime.parse(nextReminder['scheduled_time']);
      }
      return null;
    } catch (e) {
      print('❌ Error getting next medication reminder: $e');
      return null;
    }
  }

  /// Check for missed medications
  Future<void> checkMissedMedications() async {
    try {
      await _reminderScheduler.checkMissedMedications();
    } catch (e) {
      print('❌ Error checking missed medications: $e');
    }
  }

  /// Initialize medication notification system
  Future<void> initializeMedicationNotifications() async {
    try {
      print('🔔 Initializing medication notification system');
      
      // Initialize notification service
      await _notificationService.init();
      
      // Initialize reminder scheduler
      await _reminderScheduler.initialize();
      
      // Check for missed medications
      await checkMissedMedications();
      
      // Schedule notifications for all active medications
      await scheduleNotificationsForAllMedications();
      
      print('✅ Medication notification system initialized');
    } catch (e) {
      print('❌ Error initializing medication notifications: $e');
      throw 'Failed to initialize medication notifications: $e';
    }
  }

  /// Schedule notifications for all active medications
  Future<void> scheduleNotificationsForAllMedications() async {
    try {
      print('🔔 Scheduling notifications for all active medications');
      
      final medications = await getMedications();
      print('📋 Found ${medications.length} active medications');
      
      for (final medication in medications) {
        if (medication.isActive) {
          try {
            await scheduleMedicationNotifications(medication);
            print('✅ Scheduled notifications for: ${medication.name}');
          } catch (e) {
            print('❌ Failed to schedule notifications for ${medication.name}: $e');
          }
        }
      }
      
      print('✅ Completed scheduling notifications for all medications');
    } catch (e) {
      print('❌ Error scheduling notifications for all medications: $e');
    }
  }

  // ============================================================================
  // CORE MEDICATION OPERATIONS
  // ============================================================================

  /// Get all medications for the current user
  Future<List<Medication>> getMedications() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      final userId = currentUser.id;
      print('🔍 Fetching medications for user: $userId');
      
      final response = await _supabase
          .from('medications')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      print('📊 Raw response from database: $response');
      
      final medications = (response as List)
          .map((json) => Medication.fromJson(json))
          .toList();
      
      print('✅ Parsed ${medications.length} medications');
      
      return medications;
    } catch (e) {
      print('❌ Error fetching medications: $e');
      throw 'Failed to load medications: $e';
    }
  }

  /// Get medication by ID
  Future<Medication> getMedicationById(String medicationId) async {
    try {
      final response = await _supabase
          .from('medications')
          .select()
          .eq('id', medicationId)
          .single();

      return Medication.fromJson(response);
    } catch (e) {
      throw 'Failed to load medication: $e';
    }
  }

  /// Create new medication
  Future<Medication> createMedication(Medication medication) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      final userId = currentUser.id;
      
      final data = {
        'user_id': userId,
        'name': medication.name,
        'dosage': medication.dosage,
        'medicine_type': medication.medicineType,
        'frequency': medication.frequency,
        'time_of_day': medication.times.map((time) => '${time.hour}:${time.minute}').toList(),
        'start_date': medication.startDate.toIso8601String().split('T')[0],
        'end_date': medication.endDate?.toIso8601String().split('T')[0],
        'notes': medication.notes,
        'is_active': medication.isActive,
      };

      print('Creating medication with data: $data');

      final response = await _supabase
          .from('medications')
          .insert(data)
          .select()
          .single();

      print('Response from database: $response');

      final createdMedication = Medication.fromJson(response);
      
      // Schedule notifications for the new medication
      if (createdMedication.isActive) {
        try {
          await scheduleMedicationNotifications(createdMedication);
          print('✅ Successfully scheduled notifications for new medication: ${createdMedication.name}');
        } catch (e) {
          print('⚠️ Warning: Failed to schedule notifications for new medication: $e');
          // Don't throw here as the medication was created successfully
        }
      }

      return createdMedication;
    } catch (e) {
      print('Error creating medication: $e');
      throw 'Failed to create medication: $e';
    }
  }

  /// Update medication
  Future<Medication> updateMedication(Medication medication) async {
    try {
      if (medication.id == null) {
        throw 'Medication ID is required for update';
      }

      final data = {
        'name': medication.name,
        'dosage': medication.dosage,
        'medicine_type': medication.medicineType,
        'frequency': medication.frequency,
        'time_of_day': medication.times.map((time) => '${time.hour}:${time.minute}').toList(),
        'start_date': medication.startDate.toIso8601String().split('T')[0],
        'end_date': medication.endDate?.toIso8601String().split('T')[0],
        'notes': medication.notes,
        'is_active': medication.isActive,
      };

      print('Updating medication with data: $data');

      final response = await _supabase
          .from('medications')
          .update(data)
          .eq('id', medication.id)
          .select()
          .single();

      print('Response from database: $response');

      final updatedMedication = Medication.fromJson(response);
      
      // Update notifications for the modified medication
      if (updatedMedication.isActive) {
        try {
          await updateMedicationNotifications(updatedMedication);
          print('✅ Successfully updated notifications for medication: ${updatedMedication.name}');
        } catch (e) {
          print('⚠️ Warning: Failed to update notifications for medication: $e');
          // Don't throw here as the medication was updated successfully
        }
      } else {
        // Cancel notifications if medication is deactivated
        try {
          await cancelMedicationNotifications(updatedMedication.id!);
          print('✅ Successfully cancelled notifications for deactivated medication: ${updatedMedication.name}');
        } catch (e) {
          print('⚠️ Warning: Failed to cancel notifications for deactivated medication: $e');
        }
      }

      return updatedMedication;
    } catch (e) {
      print('Error updating medication: $e');
      throw 'Failed to update medication: $e';
    }
  }

  /// Delete medication (soft delete by setting is_active to false)
  Future<void> deleteMedication(String medicationId) async {
    try {
      await _supabase
          .from('medications')
          .update({'is_active': false})
          .eq('id', medicationId);
      
      // Cancel notifications for the deleted medication
      try {
        await cancelMedicationNotifications(medicationId);
        print('✅ Successfully cancelled notifications for deleted medication: $medicationId');
      } catch (e) {
        print('⚠️ Warning: Failed to cancel notifications for deleted medication: $e');
      }
    } catch (e) {
      throw 'Failed to delete medication: $e';
    }
  }

  /// Permanently delete medication
  Future<void> permanentlyDeleteMedication(String medicationId) async {
    try {
      await _supabase
          .from('medications')
          .delete()
          .eq('id', medicationId);
    } catch (e) {
      throw 'Failed to permanently delete medication: $e';
    }
  }

  // ============================================================================
  // TODAY'S MEDICATIONS
  // ============================================================================

  /// Get today's medications with status
  Future<List<Map<String, dynamic>>> getTodayMedications(DateTime date) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      final userId = currentUser.id;
      final dateStr = date.toIso8601String().split('T')[0];
      
      print('📅 Fetching today\'s medications for date: $dateStr');
      
      final response = await _supabase
          .rpc('get_today_medications', params: {
        'p_user_id': userId,
        'p_date': dateStr,
      });

      print('📊 Today\'s medications response: $response');
      
      final result = (response as List).cast<Map<String, dynamic>>();
      print('✅ Found ${result.length} today medications');
      
      return result;
    } catch (e) {
      print('❌ Error fetching today\'s medications: $e');
      throw 'Failed to load today\'s medications: $e';
    }
  }

  /// Get past medications (taken or skipped) for today and yesterday
  Future<List<Map<String, dynamic>>> getPastMedications() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      final userId = currentUser.id;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      final todayStr = today.toIso8601String().split('T')[0];
      final yesterdayStr = yesterday.toIso8601String().split('T')[0];
      
      print('🔍 Debug: Fetching past medications for user: $userId');
      print('🔍 Debug: Date range: $yesterdayStr to $todayStr');
      
      // Get medications for today and yesterday that are taken or skipped
      final response = await _supabase
          .from('medication_history')
          .select('''
            id,
            medication_id,
            status,
            scheduled_for,
            taken_at,
            notes,
            medications!inner(
              id,
              name,
              dosage,
              medicine_type,
              frequency,
              time_of_day
            )
          ''')
          .eq('user_id', userId)
          .gte('scheduled_for', yesterdayStr)
          .lte('scheduled_for', todayStr)
          .order('scheduled_for', ascending: false);

      print('📊 Debug: Raw past medications response: $response');
      
      // Filter the results in Dart to only include taken or skipped medications
      final allResults = (response as List).cast<Map<String, dynamic>>();
      print('📋 Debug: Found ${allResults.length} total medication history entries');
      
      final filteredResults = allResults.where((med) => 
        med['status'] == 'taken' || med['status'] == 'skipped'
      ).toList();
      
      print('📚 Debug: Filtered to ${filteredResults.length} taken/skipped medications');
      
      return filteredResults;
    } catch (e) {
      print('❌ Debug: Error in getPastMedications: $e');
      throw 'Failed to load past medications: $e';
    }
  }

  // ============================================================================
  // MEDICATION HISTORY
  // ============================================================================

  /// Get medication history for a specific medication
  Future<List<Map<String, dynamic>>> getMedicationHistory(
    String medicationId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];
      
      final response = await _supabase
          .rpc('get_medication_history', params: {
        'p_medication_id': medicationId,
        'p_start_date': startDateStr,
        'p_end_date': endDateStr,
      });

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw 'Failed to load medication history: $e';
    }
  }

  /// Log medication as taken
  Future<String> logMedicationTaken(
    String medicationId,
    DateTime scheduledFor,
    DateTime? takenAt,
    String? notes,
  ) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      final userId = currentUser.id;
      
      print('🔧 Logging medication as taken:');
      print('  - Medication ID: $medicationId');
      print('  - User ID: $userId');
      print('  - Scheduled For: ${scheduledFor.toIso8601String()}');
      print('  - Taken At: ${takenAt?.toIso8601String()}');
      print('  - Notes: $notes');
      
      // Validate UUID format
      if (medicationId.isEmpty) {
        throw 'Medication ID cannot be empty';
      }
      
      final response = await _supabase
          .rpc('log_medication_taken', params: {
        'p_medication_id': medicationId,
        'p_user_id': userId,
        'p_scheduled_for': scheduledFor.toIso8601String(),
        'p_taken_at': takenAt?.toIso8601String(),
        'p_notes': notes,
      });

      print('✅ Medication logged successfully: $response');
      
      // Show medication taken notification
      try {
        // Get medication name for notification
        final medication = await getMedicationById(medicationId);
        await showMedicationTakenNotification(medication.name);
      } catch (e) {
        print('⚠️ Warning: Failed to show medication taken notification: $e');
      }
      
      return response.toString();
    } catch (e) {
      print('❌ Error logging medication as taken: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        print('❌ Exception details: ${e.toString()}');
      }
      
      // Handle specific frequency validation errors
      String errorMessage = 'Failed to log medication as taken: $e';
      if (e.toString().contains('once daily limit')) {
        errorMessage = 'This medication can only be marked once per day (once daily frequency)';
      } else if (e.toString().contains('twice daily limit')) {
        errorMessage = 'This medication can only be marked twice per day (twice daily frequency)';
      } else if (e.toString().contains('three times daily limit')) {
        errorMessage = 'This medication can only be marked three times per day (three times daily frequency)';
      } else if (e.toString().contains('four times daily limit')) {
        errorMessage = 'This medication can only be marked four times per day (four times daily frequency)';
      }
      
      throw errorMessage;
    }
  }

  /// Log medication as skipped
  Future<String> logMedicationSkipped(
    String medicationId,
    DateTime scheduledFor,
    String? notes,
  ) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      final userId = currentUser.id;
      
      final response = await _supabase
          .rpc('log_medication_skipped', params: {
        'p_medication_id': medicationId,
        'p_user_id': userId,
        'p_scheduled_for': scheduledFor.toIso8601String(),
        'p_notes': notes,
      });

      // Show medication skipped notification
      try {
        // Get medication name for notification
        final medication = await getMedicationById(medicationId);
        await showMedicationSkippedNotification(medication.name);
      } catch (e) {
        print('⚠️ Warning: Failed to show medication skipped notification: $e');
      }

      return response.toString();
    } catch (e) {
      // Handle specific frequency validation errors
      String errorMessage = 'Failed to log medication as skipped: $e';
      if (e.toString().contains('once daily limit')) {
        errorMessage = 'This medication can only be marked once per day (once daily frequency)';
      } else if (e.toString().contains('twice daily limit')) {
        errorMessage = 'This medication can only be marked twice per day (twice daily frequency)';
      } else if (e.toString().contains('three times daily limit')) {
        errorMessage = 'This medication can only be marked three times per day (three times daily frequency)';
      } else if (e.toString().contains('four times daily limit')) {
        errorMessage = 'This medication can only be marked four times per day (four times daily frequency)';
      }
      
      throw errorMessage;
    }
  }

  /// Get remaining doses for a medication on a specific date
  Future<Map<String, dynamic>> getRemainingDoses(
    String medicationId,
    DateTime date,
  ) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      final userId = currentUser.id;
      final dateStr = date.toIso8601String().split('T')[0];
      
      final response = await _supabase
          .rpc('get_remaining_doses', params: {
        'p_medication_id': medicationId,
        'p_user_id': userId,
        'p_date': dateStr,
      });

      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }
      
      return {
        'total_doses': 0,
        'taken_doses': 0,
        'skipped_doses': 0,
        'remaining_doses': 0,
        'frequency': 'unknown',
      };
    } catch (e) {
      throw 'Failed to get remaining doses: $e';
    }
  }

  // ============================================================================
  // ANALYTICS & COMPLIANCE
  // ============================================================================

  /// Get medication compliance rate
  Future<List<Map<String, dynamic>>> getMedicationComplianceRate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      final userId = currentUser.id;
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];
      
      final response = await _supabase
          .rpc('get_medication_compliance_rate', params: {
        'p_user_id': userId,
        'p_start_date': startDateStr,
        'p_end_date': endDateStr,
      });

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw 'Failed to get compliance rate: $e';
    }
  }

  /// Get missed medications count for a specific date
  Future<int> getMissedMedicationsCount(DateTime date) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      final userId = currentUser.id;
      final dateStr = date.toIso8601String().split('T')[0];
      
      final response = await _supabase
          .rpc('get_missed_medications_count', params: {
        'p_user_id': userId,
        'p_date': dateStr,
      });

      return response as int;
    } catch (e) {
      throw 'Failed to get missed medications count: $e';
    }
  }

  // ============================================================================
  // REMINDER MANAGEMENT
  // ============================================================================

  /// Get active reminders for a user
  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      final userId = currentUser.id;
      
      final response = await _supabase
          .from('medication_reminders')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .gte('scheduled_time', DateTime.now().toIso8601String())
          .order('scheduled_time');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw 'Failed to load active reminders: $e';
    }
  }

  /// Create medication reminder
  Future<void> createMedicationReminder(
    String medicationId,
    int notificationId,
    DateTime scheduledTime,
  ) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      final userId = currentUser.id;
      
      await _supabase.from('medication_reminders').insert({
        'medication_id': medicationId,
        'user_id': userId,
        'notification_id': notificationId,
        'scheduled_time': scheduledTime.toIso8601String(),
        'is_active': true,
      });
    } catch (e) {
      throw 'Failed to create medication reminder: $e';
    }
  }

  /// Update medication reminder
  Future<void> updateMedicationReminder(
    String reminderId,
    DateTime scheduledTime,
    bool isActive,
  ) async {
    try {
      await _supabase
          .from('medication_reminders')
          .update({
            'scheduled_time': scheduledTime.toIso8601String(),
            'is_active': isActive,
          })
          .eq('id', reminderId);
    } catch (e) {
      throw 'Failed to update medication reminder: $e';
    }
  }

  /// Delete medication reminder
  Future<void> deleteMedicationReminder(String reminderId) async {
    try {
      await _supabase
          .from('medication_reminders')
          .delete()
          .eq('id', reminderId);
    } catch (e) {
      throw 'Failed to delete medication reminder: $e';
    }
  }

  /// Deactivate all reminders for a medication
  Future<void> deactivateMedicationReminders(String medicationId) async {
    try {
      await _supabase
          .from('medication_reminders')
          .update({'is_active': false})
          .eq('medication_id', medicationId);
    } catch (e) {
      throw 'Failed to deactivate medication reminders: $e';
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Test database connection and function availability
  Future<void> testDatabaseConnection() async {
    try {
      print('🔍 Testing database connection...');
      
      // Test basic connection
      final response = await _supabase
          .from('medications')
          .select('count')
          .limit(1);
      
      print('✅ Database connection successful');
      
      // Test if the function exists by calling it with a valid medication ID
      try {
        // First, get a valid medication ID
        final medications = await getMedications();
        if (medications.isNotEmpty) {
          final testMedicationId = medications.first.id!;
          final currentUser = _supabase.auth.currentUser;
          if (currentUser != null) {
            final testResponse = await _supabase
                .rpc('log_medication_taken', params: {
              'p_medication_id': testMedicationId,
              'p_user_id': currentUser.id,
              'p_scheduled_for': DateTime.now().toIso8601String(),
              'p_taken_at': DateTime.now().toIso8601String(),
              'p_notes': 'Test call',
            });
            print('✅ log_medication_taken function exists and is accessible');
          } else {
            print('ℹ️ User not authenticated, skipping function test');
          }
        } else {
          print('ℹ️ No medications found, skipping function test');
        }
      } catch (e) {
        print('❌ log_medication_taken function error: $e');
      }
      
    } catch (e) {
      print('❌ Database connection test failed: $e');
      throw 'Database connection test failed: $e';
    }
  }

  /// Get medication statistics for dashboard
  Future<Map<String, dynamic>> getMedicationStatistics() async {
    try {
      final today = DateTime.now();
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      final complianceData = await getMedicationComplianceRate(startOfWeek, endOfWeek);
      final missedCount = await getMissedMedicationsCount(today);
      final activeMedications = await getMedications();
      
      return {
        'total_medications': activeMedications.length,
        'missed_today': missedCount,
        'compliance_rate': complianceData.isNotEmpty 
            ? complianceData.first['compliance_rate'] ?? 0.0 
            : 0.0,
        'weekly_compliance': complianceData,
      };
    } catch (e) {
      throw 'Failed to get medication statistics: $e';
    }
  }

  /// Create a test medication for debugging
  Future<Medication> createTestMedication() async {
    try {
      // Create a time that's in the future (next hour)
      final now = DateTime.now();
      final futureTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
      
      final testMedication = Medication(
        id: null,
        name: 'Test Medication',
        dosage: '100mg',
        medicineType: 'tablet',
        frequency: 'once daily',
        times: [futureTime],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        notes: 'Test medication for debugging',
        isActive: true,
      );

      print('🧪 Creating test medication with time: ${futureTime.hour}:${futureTime.minute.toString().padLeft(2, '0')}');
      final result = await createMedication(testMedication);
      print('✅ Test medication created: ${result.name}');
      return result;
    } catch (e) {
      print('❌ Error creating test medication: $e');
      throw 'Failed to create test medication: $e';
    }
  }

  /// Debug method to check all medications in database
  Future<void> debugCheckAllMedications() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ User not authenticated');
        return;
      }
      
      final userId = currentUser.id;
      print('🔍 Debug: Checking all medications for user: $userId');
      
      final response = await _supabase
          .from('medications')
          .select('*')
          .eq('user_id', userId);
      
      print('📊 Debug: Raw medications response: $response');
      
      if (response is List) {
        print('📋 Debug: Found ${response.length} medications in database');
        for (int i = 0; i < response.length; i++) {
          final med = response[i];
          print('📋 Debug: Medication $i: ${med['name']} - Active: ${med['is_active']} - Times: ${med['time_of_day']}');
        }
      }
    } catch (e) {
      print('❌ Debug: Error checking medications: $e');
    }
  }
} 