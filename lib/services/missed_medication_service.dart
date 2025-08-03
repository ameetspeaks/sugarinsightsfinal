import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'medication_service.dart';

class MissedMedicationService {
  static final MissedMedicationService _instance = MissedMedicationService._internal();
  factory MissedMedicationService() => _instance;
  MissedMedicationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final MedicationService _medicationService = MedicationService.instance;

  /// Check for missed medications and return them
  Future<List<Map<String, dynamic>>> getMissedMedications() async {
    try {
      print('🔍 Checking for missed medications...');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ User not authenticated');
        return [];
      }

      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final yesterday = now.subtract(const Duration(days: 1));
      
      // Get medications that were scheduled in the past hour but not taken
      final missedReminders = await _supabase
          .from('medication_reminders')
          .select('''
            *,
            medications!inner(
              id,
              name,
              dosage,
              medicine_type,
              frequency,
              time_of_day
            )
          ''')
          .eq('user_id', currentUser.id)
          .eq('is_active', true)
          .lt('scheduled_time', oneHourAgo.toIso8601String())
          .gt('scheduled_time', yesterday.toIso8601String());

      final missedList = List<Map<String, dynamic>>.from(missedReminders);
      print('📋 Found ${missedList.length} potentially missed medications');

      final actuallyMissed = <Map<String, dynamic>>[];

      for (final reminder in missedList) {
        final medicationId = reminder['medication_id'];
        final scheduledTime = DateTime.parse(reminder['scheduled_time']);
        
        // Check if there's a history entry for this time
        try {
          final historyEntry = await _supabase
              .from('medication_history')
              .select('*')
              .eq('medication_id', medicationId)
              .eq('scheduled_for', scheduledTime.toIso8601String())
              .single();

          // If no history entry exists, the medication was missed
          if (historyEntry == null) {
            actuallyMissed.add(reminder);
            print('   ⚠️ Missed medication: ${reminder['medications']['name']} at $scheduledTime');
          }
        } catch (e) {
          // No history entry found, so medication was missed
          actuallyMissed.add(reminder);
          print('   ⚠️ Missed medication: ${reminder['medications']['name']} at $scheduledTime');
        }
      }

      print('✅ Found ${actuallyMissed.length} actually missed medications');
      return actuallyMissed;
    } catch (e) {
      print('❌ Error checking missed medications: $e');
      return [];
    }
  }

  /// Show missed medication popup
  Future<void> showMissedMedicationPopup(BuildContext context) async {
    try {
      final missedMedications = await getMissedMedications();
      
      if (missedMedications.isNotEmpty) {
        print('📱 Showing missed medication popup for ${missedMedications.length} medications');
        
        // Show popup for each missed medication
        for (final missedMed in missedMedications) {
          await _showSingleMissedMedicationDialog(context, missedMed);
        }
      }
    } catch (e) {
      print('❌ Error showing missed medication popup: $e');
    }
  }

  /// Show dialog for a single missed medication
  Future<void> _showSingleMissedMedicationDialog(
    BuildContext context,
    Map<String, dynamic> missedMedication,
  ) async {
    final medication = missedMedication['medications'] as Map<String, dynamic>;
    final scheduledTime = DateTime.parse(missedMedication['scheduled_time']);
    final medicationId = medication['id'] as String;
    final medicationName = medication['name'] as String;
    final dosage = medication['dosage'] as String;

    return showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 20),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Missed Medication',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You missed taking your medication:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicationName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Dosage: $dosage',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Scheduled for: ${_formatTime(scheduledTime)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'What would you like to do?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleMedicationAction(
                  context,
                  medicationId,
                  scheduledTime,
                  'skip',
                  'Skipped via missed medication popup',
                );
              },
              child: Text(
                'Skip',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleMedicationAction(
                  context,
                  medicationId,
                  scheduledTime,
                  'take',
                  'Taken via missed medication popup',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Take Now'),
            ),
          ],
        );
      },
    );
  }

  /// Handle medication action (take or skip)
  Future<void> _handleMedicationAction(
    BuildContext context,
    String medicationId,
    DateTime scheduledTime,
    String action,
    String notes,
  ) async {
    try {
      if (action == 'take') {
        await _medicationService.logMedicationTaken(
          medicationId,
          scheduledTime,
          DateTime.now(),
          notes,
        );
        
        // Use a try-catch to handle context issues
        try {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Medication marked as taken'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (contextError) {
          print('⚠️ Context error showing snackbar: $contextError');
        }
      } else if (action == 'skip') {
        await _medicationService.logMedicationSkipped(
          medicationId,
          scheduledTime,
          notes,
        );
        
        // Use a try-catch to handle context issues
        try {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Medication marked as skipped'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (contextError) {
          print('⚠️ Context error showing snackbar: $contextError');
        }
      }
    } catch (e) {
      print('❌ Error handling medication action: $e');
      try {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (contextError) {
        print('⚠️ Context error showing error snackbar: $contextError');
      }
    }
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Check for missed medications when app becomes active
  Future<void> checkMissedMedicationsOnAppResume(BuildContext context) async {
    try {
      print('🔍 Checking for missed medications on app resume...');
      
      // Wait a moment for the app to fully load
      await Future.delayed(Duration(seconds: 2));
      
      // Show popup for missed medications
      await showMissedMedicationPopup(context);
      
    } catch (e) {
      print('❌ Error checking missed medications on app resume: $e');
    }
  }

  /// Get missed medications count for display
  Future<int> getMissedMedicationsCount() async {
    try {
      final missedMedications = await getMissedMedications();
      return missedMedications.length;
    } catch (e) {
      print('❌ Error getting missed medications count: $e');
      return 0;
    }
  }
} 