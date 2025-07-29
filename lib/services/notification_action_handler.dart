import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'notification_service.dart';
// import 'supabase_service.dart';

class NotificationActionHandler {
  static final NotificationActionHandler _instance = NotificationActionHandler._internal();
  factory NotificationActionHandler() => _instance;
  NotificationActionHandler._internal();

  final NotificationService _notificationService = NotificationService();
  // final SupabaseService _supabaseService = SupabaseService();

  // Initialize action handlers
  Future<void> initialize() async {
    // Simplified notification action handler without awesome_notifications
    print('[NotificationActionHandler] Initialized');
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
      await _notificationService.scheduleMedicationReminder(
        id: _generateNotificationId(medicationId, snoozeTime, isReminder: true),
        title: 'Medication Reminder',
        body: 'Snoozed reminder: Time to take your medication',
        scheduledDate: snoozeTime,
        payload: json.encode({
          'type': 'reminder',
          'medicationId': medicationId,
        }),
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