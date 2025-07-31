import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../core/config/notification_channels.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotifications =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request notification permissions
    await _requestPermissions();

    // Initialize timezone
    final String timeZoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC if timezone location is not found
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Initialize local notifications
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle iOS notification when app is in foreground
      },
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );



    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    // Request notification permission
    await Permission.notification.request();

    // For iOS, request permissions through local notifications plugin
    if (await Permission.notification.isGranted) {
      await _flutterLocalNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    if (response.payload != null) {
      // Navigate to appropriate screen based on payload
    }
  }

  // Schedule a medication reminder
  Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    bool isAlarm = false,
  }) async {
      await _flutterLocalNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationChannels.medicationReminders,
            'Medication Reminders',
            channelDescription: 'Notifications for medication reminders',
            importance: Importance.high,
            priority: Priority.high,
            actions: [
              const AndroidNotificationAction(
                'TAKE_MEDICATION',
                'Take',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'SKIP_MEDICATION',
                'Skip',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'SNOOZE_MEDICATION',
                'Snooze',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
  }

  // Schedule medication reminder with medication data
  Future<void> scheduleMedicationReminderWithData({
    required int id,
    required String medicationName,
    required String dosage,
    required DateTime scheduledDate,
    String? medicationId,
    String? notes,
  }) async {
    final title = 'Medication Reminder';
    final body = 'Time to take $medicationName - $dosage';
    final payload = medicationId != null ? 'medication:$medicationId' : null;

    await scheduleMedicationReminder(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
    );
  }

  // Show medication taken notification
  Future<void> showMedicationTakenNotification({
    required String medicationName,
    String? notes,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Medication Taken',
      body: 'Successfully logged $medicationName',
      payload: 'medication_taken',
    );
  }

  // Show medication skipped notification
  Future<void> showMedicationSkippedNotification({
    required String medicationName,
    String? notes,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Medication Skipped',
      body: '$medicationName was skipped',
      payload: 'medication_skipped',
    );
  }

  // Snooze medication reminder
  Future<void> snoozeMedicationReminder({
    required int originalId,
    required String medicationName,
    required String dosage,
    required Duration snoozeDuration,
    String? medicationId,
  }) async {
    final newId = originalId + 1000; // Create unique ID for snoozed notification
    final newScheduledTime = DateTime.now().add(snoozeDuration);
    
    await scheduleMedicationReminderWithData(
      id: newId,
      medicationName: medicationName,
      dosage: dosage,
      scheduledDate: newScheduledTime,
      medicationId: medicationId,
    );
  }

  // Show a health reading reminder
  Future<void> showHealthReadingReminder({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _flutterLocalNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.healthReadings,
          'Health Readings',
          channelDescription: 'Notifications for health readings',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // Show an appointment reminder
  Future<void> showAppointmentReminder({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _flutterLocalNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.appointments,
          'Appointments',
          channelDescription: 'Notifications for appointments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // Show a health tip
  Future<void> showHealthTip({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _flutterLocalNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.healthTips,
          'Health Tips',
          channelDescription: 'Notifications for health tips',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // Show a progress update
  Future<void> showProgressUpdate({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _flutterLocalNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.progressUpdates,
          'Progress Updates',
          channelDescription: 'Notifications for progress updates',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // Show a system message
  Future<void> showSystemMessage({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _flutterLocalNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.systemMessages,
          'System Messages',
          channelDescription: 'Notifications for system messages',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotifications.cancelAll();
  }

  // Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _flutterLocalNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.basicNotifications,
          'Basic Notifications',
          channelDescription: 'Regular app notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotifications.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await Permission.notification.isGranted;
  }
} 