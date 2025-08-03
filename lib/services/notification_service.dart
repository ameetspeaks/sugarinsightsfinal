import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../core/config/notification_channels.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('🔔 Initializing notification service...');
      
      // Set timezone to IST
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      print('🌍 Timezone set to IST (Asia/Kolkata)');

      // Request permissions
      await _requestPermissions();

      // Initialize Android settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Initialize iOS settings
      const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

      // Initialize settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      await _flutterLocalNotifications.initialize(
        initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels
    await _createNotificationChannels();

    _isInitialized = true;
      print('✅ Notification service initialized successfully');
      
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
    final status = await Permission.notification.request();
    print('📱 Notification permission status: $status');
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
    }
  }

  /// Create notification channels
  Future<void> _createNotificationChannels() async {
    try {
      // Medication alarms channel
      final medicationAlarmsChannel = AndroidNotificationChannel(
        'medication_alarms',
        'Medication Alarms',
        description: 'High priority medication reminders with sound',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      );

        await _flutterLocalNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(medicationAlarmsChannel);

      // General notifications channel
      const generalChannel = AndroidNotificationChannel(
        'general_notifications',
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      );

      await _flutterLocalNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(generalChannel);

      print('✅ Notification channels created successfully');
    } catch (e) {
      print('❌ Error creating notification channels: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('👆 Notification tapped: ${response.payload}');
    // Handle notification tap
    if (response.payload != null) {
      print('🔔 Would handle notification tap for payload: ${response.payload}');
      
      // If it's a medication notification, show popup
      if (response.payload!.startsWith('medication:')) {
        _handleMedicationNotification(response.payload!);
      }
    }
  }

  /// Handle medication notification by showing popup
  Future<void> _handleMedicationNotification(String payload) async {
    try {
      final medicationId = payload.substring('medication:'.length);
      print('🔔 Handling medication notification for: $medicationId');
      print('🔔 Would show medication popup for medication ID: $medicationId');
    } catch (e) {
      print('❌ Error handling medication notification: $e');
    }
  }

  /// Schedule medication reminder with data
  Future<void> scheduleMedicationReminderWithData({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String medicationId,
    required String medicationName,
    required String dosage,
    bool isAlarm = true,
  }) async {
    try {
      await init();

      // Cancel any existing notification with same ID
      await _flutterLocalNotifications.cancel(id);
      
      print('🔔 Scheduling notification:');
      print('   ID: $id');
      print('   Title: $title');
      print('   Body: $body');
      print('   Scheduled Date: $scheduledDate');
      print('   TZ Scheduled Date: ${tz.TZDateTime.from(scheduledDate, tz.local)}');
      print('   Is Alarm: $isAlarm');
      print('   Channel: medication_alarms');
      
      // Check if time is in the past
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);
      
      if (scheduledTime.isBefore(now)) {
        print('⚠️ Scheduled time is in the past, adjusting to 5 seconds from now');
        final adjustedTime = now.add(const Duration(seconds: 5));
        await _scheduleNotification(
          id: id,
          title: title,
          body: body,
          scheduledDate: adjustedTime,
          payload: 'medication:$medicationId',
          isAlarm: isAlarm,
        );
      } else {
        await _scheduleNotification(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledTime,
          payload: 'medication:$medicationId',
          isAlarm: isAlarm,
        );
      }

      print('✅ Notification scheduled successfully with exact timing');
    } catch (e) {
      print('❌ Error scheduling medication reminder: $e');
    }
  }

  /// Schedule notification with exact timing
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
    bool isAlarm = false,
  }) async {
    try {
    print('🔔 Scheduling notification with exact timing:');
    print('   ID: $id');
    print('   Title: $title');
      print('   Scheduled Time: $scheduledDate');
    print('   Is Alarm: $isAlarm');
      print('   Sound: alarm');
      print('   Timezone: IST');

      final androidDetails = AndroidNotificationDetails(
        isAlarm ? 'medication_alarms' : 'general_notifications',
        isAlarm ? 'Medication Alarms' : 'General Notifications',
        channelDescription: isAlarm 
            ? 'High priority medication reminders with sound'
            : 'General app notifications',
        importance: isAlarm ? Importance.high : Importance.defaultImportance,
        priority: isAlarm ? Priority.high : Priority.defaultPriority,
        playSound: isAlarm,
        sound: isAlarm ? const RawResourceAndroidNotificationSound('alarm') : null,
        enableVibration: true,
        vibrationPattern: isAlarm 
            ? Int64List.fromList([0, 500, 200, 500])
            : Int64List.fromList([0, 250, 100, 250]),
        category: isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.message,
        autoCancel: true,
        ongoing: false,
        showWhen: true,
        when: scheduledDate.millisecondsSinceEpoch,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: isAlarm,
        sound: isAlarm ? 'alarm.wav' : null,
        categoryIdentifier: isAlarm ? 'medication_alarm' : 'general_notification',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
    
    await _flutterLocalNotifications.zonedSchedule(
      id,
      title,
      body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
    
      print('✅ Notification scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isAlarm = false,
  }) async {
    try {
      await init();

      final androidDetails = AndroidNotificationDetails(
        isAlarm ? 'medication_alarms' : 'general_notifications',
        isAlarm ? 'Medication Alarms' : 'General Notifications',
        channelDescription: isAlarm 
            ? 'High priority medication reminders with sound'
            : 'General app notifications',
        importance: isAlarm ? Importance.high : Importance.defaultImportance,
        priority: isAlarm ? Priority.high : Priority.defaultPriority,
        playSound: isAlarm,
        sound: isAlarm ? const RawResourceAndroidNotificationSound('alarm') : null,
            enableVibration: true,
        vibrationPattern: isAlarm 
            ? Int64List.fromList([0, 500, 200, 500])
            : Int64List.fromList([0, 250, 100, 250]),
        category: isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.message,
        autoCancel: true,
        ongoing: false,
            showWhen: true,
      );

      final iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
        presentSound: isAlarm,
        sound: isAlarm ? 'alarm.wav' : null,
        categoryIdentifier: isAlarm ? 'medication_alarm' : 'general_notification',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

    await _flutterLocalNotifications.show(
      id,
      title,
      body,
        notificationDetails,
      payload: payload,
    );

      print('✅ Immediate notification shown successfully');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  /// Show medication taken notification
  Future<void> showMedicationTakenNotification({
    required String medicationName,
    required int dosage,
    required String medicationId,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 1000000,
      title: 'Medication Taken',
      body: 'You took $medicationName - $dosage',
      payload: 'medication_taken:$medicationId',
      isAlarm: true,
    );
  }

  /// Show medication skipped notification
  Future<void> showMedicationSkippedNotification({
    required String medicationName,
    required int dosage,
    required String medicationId,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 1000000,
      title: 'Medication Skipped',
      body: 'You skipped $medicationName - $dosage',
      payload: 'medication_skipped:$medicationId',
      isAlarm: true,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotifications.cancel(id);
      print('✅ Notification with ID $id cancelled successfully');
    } catch (e) {
      print('❌ Error cancelling notification $id: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      print('🗑️ Cancelling all pending notifications...');
      
      final pendingNotifications = await _flutterLocalNotifications.pendingNotificationRequests();
      print('📋 Found ${pendingNotifications.length} notifications to cancel');
      
      await _flutterLocalNotifications.cancelAll();
      
      print('✅ All notifications cancelled successfully');
      
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  /// Check pending notifications
  Future<void> checkPendingNotifications() async {
    try {
      print('📋 Checking pending notifications...');
      
      final pendingNotifications = await _flutterLocalNotifications.pendingNotificationRequests();
      print('📋 Found ${pendingNotifications.length} pending notifications:');
      
      for (final notification in pendingNotifications) {
        print('   ID: ${notification.id}');
        print('   Title: ${notification.title}');
        print('   Body: ${notification.body}');
        print('   ---');
      }
      
    } catch (e) {
      print('❌ Error checking pending notifications: $e');
    }
  }

  /// Test immediate notification
  Future<void> testImmediateNotification() async {
    try {
      print('🧪 Testing immediate notification...');
      
      await showNotification(
        id: 999999,
        title: 'Test Notification',
        body: 'This is a test notification with alarm sound',
        payload: 'test:immediate',
        isAlarm: true,
      );
      
      print('✅ Test notification scheduled successfully');
    } catch (e) {
      print('❌ Error testing immediate notification: $e');
    }
  }

  /// Test scheduled notification (10 seconds from now)
  Future<void> testScheduledNotification() async {
    try {
      print('🧪 Testing scheduled notification (10 seconds)...');
      
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
      
      await scheduleMedicationReminderWithData(
        id: 999998,
        title: 'Test Scheduled Notification',
        body: 'This is a test scheduled notification with alarm sound',
        scheduledDate: scheduledTime,
        medicationId: 'test-medication',
        medicationName: 'Test Medication',
        dosage: '1',
        isAlarm: true,
      );
      
      print('✅ Test scheduled notification scheduled successfully');
    } catch (e) {
      print('❌ Error testing scheduled notification: $e');
    }
  }

  /// Check timezone information
  Future<void> checkTimezoneInfo() async {
    try {
      print('🌍 Checking timezone information...');
      
      final now = tz.TZDateTime.now(tz.local);
      final utcNow = DateTime.now().toUtc();
      
      print('   Current local time: $now');
      print('   Current UTC time: $utcNow');
      print('   Timezone offset: ${now.timeZoneName}');
      print('   Location: ${tz.local.name}');
      
    } catch (e) {
      print('❌ Error checking timezone info: $e');
    }
  }

  /// Test notification scheduling
  Future<void> testNotificationScheduling() async {
    try {
      print('🧪 Testing notification scheduling (30 seconds)...');
      
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 30));
      
      await scheduleMedicationReminderWithData(
        id: 999997,
        title: 'Test Scheduling',
        body: 'This is a test scheduled notification',
        scheduledDate: scheduledTime,
        medicationId: 'test-scheduling',
        medicationName: 'Test Scheduling',
        dosage: '1',
        isAlarm: true,
      );
      
      print('✅ Test scheduling completed successfully');
    } catch (e) {
      print('❌ Error testing notification scheduling: $e');
    }
  }

  /// Comprehensive notification test with timezone
  Future<void> comprehensiveNotificationTestWithTimezone() async {
    try {
      print('🧪 Comprehensive notification test with timezone...');
      
      await checkTimezoneInfo();
      await testImmediateNotification();
      await testScheduledNotification();
      
      print('✅ Comprehensive test completed successfully');
    } catch (e) {
      print('❌ Error in comprehensive test: $e');
    }
  }

  /// Test alarm sound
  Future<void> testAlarmSound() async {
    await testImmediateNotification();
  }

  /// Test medication popup
  Future<void> testMedicationPopup() async {
    try {
      print('🧪 Testing medication popup...');
      await _handleMedicationNotification('medication:test-popup');
      print('✅ Medication popup test completed');
    } catch (e) {
      print('❌ Error testing medication popup: $e');
    }
  }

  /// Comprehensive notification test
  Future<void> comprehensiveNotificationTest() async {
    await comprehensiveNotificationTestWithTimezone();
  }

  /// Test medication taken sound
  Future<void> testMedicationTakenSound() async {
    await showMedicationTakenNotification(
      medicationName: 'Test Medication',
      dosage: 1,
      medicationId: 'test-taken',
    );
  }

  /// Test alarm sound file
  Future<void> testAlarmSoundFile() async {
    await testImmediateNotification();
  }

  /// Test default system sound
  Future<void> testDefaultSystemSound() async {
    await showNotification(
      id: 999996,
      title: 'Test System Sound',
      body: 'This uses default system sound',
      payload: 'test:system_sound',
      isAlarm: false,
    );
  }
} 