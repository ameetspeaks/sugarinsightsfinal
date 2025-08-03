import 'dart:convert';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'medication_service.dart';
import 'missed_medication_service.dart';

class NotificationActionHandler {
  static final NotificationActionHandler _instance = NotificationActionHandler._internal();
  factory NotificationActionHandler() => _instance;
  NotificationActionHandler._internal();

  final NotificationService _notificationService = NotificationService();
  final MedicationService _medicationService = MedicationService.instance;
  final MissedMedicationService _missedMedicationService = MissedMedicationService();

  // Initialize action handlers
  Future<void> initialize() async {
    print('[NotificationActionHandler] Initialized');
  }

  /// Handle notification tap
  Future<void> handleNotificationTap(String? payload) async {
    if (payload == null) return;

    try {
      if (payload.startsWith('medication:')) {
        final medicationId = payload.substring('medication:'.length);
        await _handleMedicationNotificationTap(medicationId);
      } else if (payload == 'background_check') {
        await _handleBackgroundCheck();
      }
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  /// Handle medication notification tap
  Future<void> _handleMedicationNotificationTap(String medicationId) async {
    try {
      print('🔔 Handling medication notification tap for: $medicationId');
      
      // Get medication details
      final medication = await _medicationService.getMedicationById(medicationId);
      
      // Show dialog to take or skip medication
      // Note: This would need to be called from a context-aware location
      // For now, we'll just log the action
      print('📱 Medication notification tapped: ${medication.name}');
      
    } catch (e) {
      print('❌ Error handling medication notification tap: $e');
    }
  }

  /// Handle background check notification
  Future<void> _handleBackgroundCheck() async {
    try {
      print('🔄 Handling background check notification');
      
      // Trigger background check for new notifications
      // This would typically be handled by the ReminderScheduler
      print('✅ Background check completed');
      
    } catch (e) {
      print('❌ Error handling background check: $e');
    }
  }

    // Handle notification actions
  // Future<void> _handleNotificationAction(ReceivedAction receivedAction) async {
  // final payload = receivedAction.payload;
  // if (payload == null) return;

  // try {
  //   final data = json.decode(payload['data'] ?? '{}');
  //   final type = data['type'];
  //   final medicationId = data['medicationId'];

  //   switch (receivedAction.buttonKeyPressed) {
  //     case 'TAKE_MEDICATION':
  //       await _handleTakeMedication(medicationId);
  //       break;
  //     case 'SKIP_MEDICATION':
  //       await _handleSkipMedication(medicationId);
  //       break;
  //     case 'SNOOZE_MEDICATION':
  //       await _handleSnoozeMedication(medicationId);
  //       break;
  //     case 'VIEW_DETAILS':
  //       _handleViewDetails(medicationId);
  //       break;
  //   }
  // } catch (e) {
  //   print('Error handling notification action: $e');
  // }
  // }

  // Handle "Take" action
  // Future<void> _handleTakeMedication(String medicationId) async {
  //   try {
  //     // Update medication status in Supabase
  //     await _supabaseService.logMedicationHistory(
  //       medicationId: medicationId,
  //       userId: _supabaseService.client.auth.currentUser!.id,
  //       status: 'taken',
  //       scheduledFor: DateTime.now(),
  //       takenAt: DateTime.now(),
  //     );

  //     // Cancel the reminder notification
  //     await _notificationService.cancelNotification(
  //       _generateNotificationId(medicationId, DateTime.now(), isReminder: true),
  //     );

  //     // Show confirmation notification
  //     await _notificationService.showNotification(
  //       id: DateTime.now().millisecondsSinceEpoch,
  //       title: 'Medication Taken',
  //       body: 'Great job! Keep up with your medication schedule.',
  //     );
  //   } catch (e) {
  //     print('Error handling take medication: $e');
  //   }
  // }

  // Handle "Skip" action
  // Future<void> _handleSkipMedication(String medicationId) async {
  //   try {
  //     // Log skipped medication
  //     await _supabaseService.logMedicationHistory(
  //       medicationId: medicationId,
  //       userId: _supabaseService.client.auth.currentUser!.id,
  //       status: 'skipped',
  //       scheduledFor: DateTime.now(),
  //     );

  //     // Cancel the reminder notification
  //     await _notificationService.cancelNotification(
  //       _generateNotificationId(medicationId, DateTime.now(), isReminder: true),
  //     );
  //   } catch (e) {
  //     print('Error handling skip medication: $e');
  //   }
  // }

  // Handle "Snooze" action
  Future<void> _handleSnoozeMedication(String medicationId) async {
    try {
      // Reschedule reminder for 10 minutes later
      final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
      await _notificationService.scheduleMedicationReminderWithData(
        id: _generateNotificationId(medicationId, snoozeTime, isReminder: true),
        title: 'Medication Reminder',
        body: 'Snoozed reminder: Time to take your medication',
        scheduledDate: snoozeTime,
        medicationId: medicationId,
        medicationName: 'Medication',
        dosage: '1',
        isAlarm: true,
      );
    } catch (e) {
      print('Error handling snooze medication: $e');
    }
  }

  // Handle "View Details" action
  void _handleViewDetails(String medicationId) {
    // TODO: Navigate to medication details screen
    // This will be handled by the navigation service or state management
  }

  // Static methods for Awesome Notifications
  // @pragma('vm:entry-point')
  // static Future<void> _onActionReceivedMethod(ReceivedAction receivedAction) async {
  //   final instance = NotificationActionHandler();
  //   await instance._handleNotificationAction(receivedAction);
  // }

  // @pragma('vm:entry-point')
  // static Future<void> _onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
  //   // Handle notification creation
  // }

  // @pragma('vm:entry-point')
  // static Future<void> _onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
  //   // Handle notification display
  // }

  // @pragma('vm:entry-point')
  // static Future<void> _onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
  //   // Handle notification dismissal
  // }

  // Helper method to generate notification ID
  int _generateNotificationId(String medicationId, DateTime date, {required bool isReminder}) {
    final baseId = medicationId.hashCode;
    final dateId = date.day + (date.month * 100) + (date.year * 10000);
    final typeId = isReminder ? 1 : 2;
    return (baseId + dateId + typeId).abs();
  }
} 