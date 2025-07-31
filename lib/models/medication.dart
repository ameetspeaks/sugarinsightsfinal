import 'package:flutter/material.dart';

class Medication {
  final String? id;
  final String name;
  final String dosage;
  final List<TimeOfDay> times; // Changed from single time to multiple times
  final bool isTaken;
  final DateTime? takenAt;
  final DateTime startDate;
  final DateTime? endDate; // Made nullable
  final String medicineType;
  final String frequency;
  final String? notes; // Added notes field
  final bool isActive; // Added active status
  final List<MedicationHistory> history;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.times, // Changed from time to times
    this.isTaken = false,
    this.takenAt,
    required this.startDate,
    this.endDate, // Made nullable
    required this.medicineType,
    required this.frequency,
    this.notes, // Added notes
    this.isActive = true, // Added active status
    this.history = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'times': times.map((time) => '${time.hour}:${time.minute}').toList(),
      'isTaken': isTaken,
      'takenAt': takenAt?.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'medicineType': medicineType,
      'frequency': frequency,
      'notes': notes,
      'isActive': isActive,
      'history': history.map((h) => h.toJson()).toList(),
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    // Handle time_of_day array from database
    List<TimeOfDay> times = [];
    if (json['time_of_day'] != null) {
      final timeArray = json['time_of_day'] as List;
      times = timeArray.map((timeStr) {
        final parts = timeStr.toString().split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
    } else if (json['times'] != null) {
      // Handle times array from toJson
      final timeArray = json['times'] as List;
      times = timeArray.map((timeStr) {
        final parts = timeStr.toString().split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
    } else if (json['time'] != null) {
      // Handle legacy single time format
      final timeStr = json['time'].toString();
      final parts = timeStr.split(':');
      times = [TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      )];
    }

    return Medication(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      times: times.isNotEmpty ? times : [const TimeOfDay(hour: 9, minute: 0)],
      isTaken: json['isTaken'] ?? json['is_taken'] ?? false,
      takenAt: json['takenAt'] != null ? DateTime.parse(json['takenAt']) : null,
      startDate: DateTime.parse(json['startDate'] ?? json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: json['endDate'] != null || json['end_date'] != null 
          ? DateTime.parse(json['endDate'] ?? json['end_date'] ?? '')
          : null,
      medicineType: json['medicineType'] ?? json['medicine_type'] ?? '',
      frequency: json['frequency']?.toString() ?? '',
      notes: json['notes']?.toString(),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      history: (json['history'] as List?)
          ?.map((h) => MedicationHistory.fromJson(h))
          .toList() ?? [],
    );
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    List<TimeOfDay>? times,
    bool? isTaken,
    DateTime? takenAt,
    DateTime? startDate,
    DateTime? endDate,
    String? medicineType,
    String? frequency,
    String? notes,
    bool? isActive,
    List<MedicationHistory>? history,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      times: times ?? this.times,
      isTaken: isTaken ?? this.isTaken,
      takenAt: takenAt ?? this.takenAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      medicineType: medicineType ?? this.medicineType,
      frequency: frequency ?? this.frequency,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      history: history ?? this.history,
    );
  }

  // Convenience getter for backward compatibility
  TimeOfDay get time => times.isNotEmpty ? times.first : const TimeOfDay(hour: 9, minute: 0);
  
  // Ensure times is never null
  List<TimeOfDay> get safeTimes => times.isNotEmpty ? times : [const TimeOfDay(hour: 9, minute: 0)];
}

class MedicationHistory {
  final String? id; // Added ID field
  final DateTime date;
  final TimeOfDay time;
  final String status; // 'taken', 'skipped', 'missed'
  final DateTime? scheduledFor; // Added scheduled time
  final DateTime? takenAt; // Added taken time
  final String? notes; // Added notes

  const MedicationHistory({
    this.id,
    required this.date,
    required this.time,
    required this.status,
    this.scheduledFor,
    this.takenAt,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'status': status,
      'scheduledFor': scheduledFor?.toIso8601String(),
      'takenAt': takenAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory MedicationHistory.fromJson(Map<String, dynamic> json) {
    TimeOfDay time;
    if (json['time'] != null) {
      final timeStr = json['time'].toString();
      final parts = timeStr.split(':');
      time = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      time = TimeOfDay.now();
    }

    return MedicationHistory(
      id: json['id']?.toString(),
      date: DateTime.parse(json['date'] ?? json['scheduled_for'] ?? DateTime.now().toIso8601String()),
      time: time,
      status: json['status']?.toString() ?? 'pending',
      scheduledFor: json['scheduledFor'] != null || json['scheduled_for'] != null
          ? DateTime.parse(json['scheduledFor'] ?? json['scheduled_for'] ?? '')
          : null,
      takenAt: json['takenAt'] != null || json['taken_at'] != null
          ? DateTime.parse(json['takenAt'] ?? json['taken_at'] ?? '')
          : null,
      notes: json['notes']?.toString(),
    );
  }
} 