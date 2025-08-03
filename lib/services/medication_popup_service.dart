import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/medication.dart';
import 'medication_service.dart';

class MedicationPopupService {
  static final MedicationPopupService _instance = MedicationPopupService._internal();
  factory MedicationPopupService() => _instance;
  MedicationPopupService._internal();

  final MedicationService _medicationService = MedicationService.instance;
  
  // Global key for showing dialogs from anywhere
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Initialize the popup service
  Future<void> initialize() async {
    print('🔔 Initializing MedicationPopupService...');
    
    // Request overlay permission for Android
    await _requestOverlayPermission();
    
    print('✅ MedicationPopupService initialized');
  }

  /// Request overlay permission for Android
  Future<void> _requestOverlayPermission() async {
    try {
      print('🔐 Requesting overlay permission...');
      
      // Check if overlay permission is granted
      final status = await Permission.systemAlertWindow.status;
      print('📱 Overlay permission status: $status');
      
      if (!status.isGranted) {
        // Request overlay permission
        final result = await Permission.systemAlertWindow.request();
        print('📱 Overlay permission request result: $result');
        
        if (!result.isGranted) {
          print('⚠️ Overlay permission not granted. Popups may not work properly.');
          // Show guidance to user
          _showOverlayPermissionDialog();
        }
      }
    } catch (e) {
      print('❌ Error requesting overlay permission: $e');
    }
  }

  /// Show dialog to guide user to enable overlay permission
  void _showOverlayPermissionDialog() {
    if (navigatorKey?.currentContext == null) return;
    
    showDialog(
      context: navigatorKey!.currentContext!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Permission Required'),
          ],
        ),
        content: Text(
          'To show medication reminders as popups, please enable "Display over other apps" permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Show medication popup at scheduled time
  Future<void> showMedicationPopup({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    try {
      print('🔔 Showing medication popup for: $medicationName at ${scheduledTime.toString()}');
      
      // Ensure we have a navigator context
      if (navigatorKey?.currentContext == null) {
        print('❌ No navigator context available for popup');
        return;
      }

      // Show the popup dialog
      await _showMedicationActionDialog(
        context: navigatorKey!.currentContext!,
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        scheduledTime: scheduledTime,
        notes: notes,
      );
      
    } catch (e) {
      print('❌ Error showing medication popup: $e');
    }
  }

  /// Show medication action dialog
  Future<void> _showMedicationActionDialog({
    required BuildContext context,
    required String medicationId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.medication, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text('Medication Reminder'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time to take your medication:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicationName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Dosage: $dosage',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Scheduled for: ${_formatTime(scheduledTime)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    if (notes != null && notes.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        'Notes: $notes',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ],
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
                  'Skipped via scheduled popup',
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
                  'Taken via scheduled popup',
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
        
        // Show confirmation notification (temporarily disabled)
        print('🔔 Would show medication taken notification');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medication marked as taken'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (action == 'skip') {
        await _medicationService.logMedicationSkipped(
          medicationId,
          scheduledTime,
          notes,
        );
        
        // Show confirmation notification (temporarily disabled)
        print('🔔 Would show medication skipped notification');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medication marked as skipped'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Error handling medication action: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Set the navigator key for showing dialogs
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }
} 