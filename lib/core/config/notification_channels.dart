import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannels {
  static const Color defaultColor = Color(0xFF9D50DD);

  static final List<AndroidNotificationChannel> channels = [
    // Medication Alarms - High priority, alarm sound, critical alerts
    const AndroidNotificationChannel(
      'medication_alarms',
      'Medication Alarms',
      description: 'Critical alerts for medication reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('medication_alarm'),
    ),

    // Medication Reminders - High priority, notification sound
    const AndroidNotificationChannel(
      'medication_reminders',
      'Medication Reminders',
      description: 'Regular reminders for medications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ),

    // Health Readings - Medium priority
    const AndroidNotificationChannel(
      'health_readings',
      'Health Readings',
      description: 'Reminders for blood sugar, blood pressure readings',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ),

    // Appointment Reminders - High priority
    const AndroidNotificationChannel(
      'appointments',
      'Appointment Reminders',
      description: 'Reminders for upcoming medical appointments',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ),

    // Health Tips - Low priority
    const AndroidNotificationChannel(
      'health_tips',
      'Health Tips',
      description: 'Daily health tips and educational content',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    ),

    // Progress Updates - Default priority
    const AndroidNotificationChannel(
      'progress_updates',
      'Progress Updates',
      description: 'Updates about your health goals and achievements',
      importance: Importance.low,
      playSound: true,
      enableVibration: true,
    ),

    // System Messages - High priority
    const AndroidNotificationChannel(
      'system_messages',
      'System Messages',
      description: 'Important system updates and messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ),

    // Basic Notifications - Default priority
    const AndroidNotificationChannel(
      'basic_notifications',
      'Basic Notifications',
      description: 'Regular app notifications',
      importance: Importance.low,
    ),
  ];

  // Channel keys for easy reference
  static const String medicationAlarms = 'medication_alarms';
  static const String medicationReminders = 'medication_reminders';
  static const String healthReadings = 'health_readings';
  static const String appointments = 'appointments';
  static const String healthTips = 'health_tips';
  static const String progressUpdates = 'progress_updates';
  static const String systemMessages = 'system_messages';
  static const String basicNotifications = 'basic_notifications';
} 