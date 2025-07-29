import 'package:flutter/material.dart';

class AppSettings {
  final String language;
  final String theme;
  final bool notificationsEnabled;
  final bool glucoseRemindersEnabled;
  final bool medicationRemindersEnabled;
  final bool dietTrackingEnabled;
  final String glucoseUnit; // mg/dL or mmol/L
  final String weightUnit; // kg or lbs
  final String heightUnit; // cm or ft
  final TimeOfDay? glucoseReminderTime;
  final TimeOfDay? medicationReminderTime;
  final List<String> enabledFeatures;
  final Map<String, dynamic> customPreferences;

  const AppSettings({
    this.language = 'en',
    this.theme = 'light',
    this.notificationsEnabled = true,
    this.glucoseRemindersEnabled = true,
    this.medicationRemindersEnabled = true,
    this.dietTrackingEnabled = true,
    this.glucoseUnit = 'mg/dL',
    this.weightUnit = 'kg',
    this.heightUnit = 'cm',
    this.glucoseReminderTime,
    this.medicationReminderTime,
    this.enabledFeatures = const ['glucose', 'medications', 'diet', 'education'],
    this.customPreferences = const {},
  });

  AppSettings copyWith({
    String? language,
    String? theme,
    bool? notificationsEnabled,
    bool? glucoseRemindersEnabled,
    bool? medicationRemindersEnabled,
    bool? dietTrackingEnabled,
    String? glucoseUnit,
    String? weightUnit,
    String? heightUnit,
    TimeOfDay? glucoseReminderTime,
    TimeOfDay? medicationReminderTime,
    List<String>? enabledFeatures,
    Map<String, dynamic>? customPreferences,
  }) {
    return AppSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      glucoseRemindersEnabled: glucoseRemindersEnabled ?? this.glucoseRemindersEnabled,
      medicationRemindersEnabled: medicationRemindersEnabled ?? this.medicationRemindersEnabled,
      dietTrackingEnabled: dietTrackingEnabled ?? this.dietTrackingEnabled,
      glucoseUnit: glucoseUnit ?? this.glucoseUnit,
      weightUnit: weightUnit ?? this.weightUnit,
      heightUnit: heightUnit ?? this.heightUnit,
      glucoseReminderTime: glucoseReminderTime ?? this.glucoseReminderTime,
      medicationReminderTime: medicationReminderTime ?? this.medicationReminderTime,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      customPreferences: customPreferences ?? this.customPreferences,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      language: json['language'] as String? ?? 'en',
      theme: json['theme'] as String? ?? 'light',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      glucoseRemindersEnabled: json['glucoseRemindersEnabled'] as bool? ?? true,
      medicationRemindersEnabled: json['medicationRemindersEnabled'] as bool? ?? true,
      dietTrackingEnabled: json['dietTrackingEnabled'] as bool? ?? true,
      glucoseUnit: json['glucoseUnit'] as String? ?? 'mg/dL',
      weightUnit: json['weightUnit'] as String? ?? 'kg',
      heightUnit: json['heightUnit'] as String? ?? 'cm',
      glucoseReminderTime: json['glucoseReminderTime'] != null
          ? TimeOfDay(
              hour: json['glucoseReminderTime']['hour'] as int,
              minute: json['glucoseReminderTime']['minute'] as int,
            )
          : null,
      medicationReminderTime: json['medicationReminderTime'] != null
          ? TimeOfDay(
              hour: json['medicationReminderTime']['hour'] as int,
              minute: json['medicationReminderTime']['minute'] as int,
            )
          : null,
      enabledFeatures: json['enabledFeatures'] != null
          ? List<String>.from(json['enabledFeatures'] as List)
          : ['glucose', 'medications', 'diet', 'education'],
      customPreferences: json['customPreferences'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'theme': theme,
      'notificationsEnabled': notificationsEnabled,
      'glucoseRemindersEnabled': glucoseRemindersEnabled,
      'medicationRemindersEnabled': medicationRemindersEnabled,
      'dietTrackingEnabled': dietTrackingEnabled,
      'glucoseUnit': glucoseUnit,
      'weightUnit': weightUnit,
      'heightUnit': heightUnit,
      'glucoseReminderTime': glucoseReminderTime != null
          ? {
              'hour': glucoseReminderTime!.hour,
              'minute': glucoseReminderTime!.minute,
            }
          : null,
      'medicationReminderTime': medicationReminderTime != null
          ? {
              'hour': medicationReminderTime!.hour,
              'minute': medicationReminderTime!.minute,
            }
          : null,
      'enabledFeatures': enabledFeatures,
      'customPreferences': customPreferences,
    };
  }

  @override
  String toString() {
    return 'AppSettings(language: $language, theme: $theme, notificationsEnabled: $notificationsEnabled)';
  }
} 