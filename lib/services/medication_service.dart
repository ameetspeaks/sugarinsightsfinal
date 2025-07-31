import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';

class MedicationService {
  final SupabaseClient _supabase;

  MedicationService(this._supabase);

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

      return Medication.fromJson(response);
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

      return Medication.fromJson(response);
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