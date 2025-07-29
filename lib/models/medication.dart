import 'package:flutter/material.dart';

class Medication {
  final String? id;
  final String name;
  final String dosage;
  final TimeOfDay time;
  final bool isTaken;
  final DateTime? takenAt;
  final DateTime startDate;
  final DateTime endDate;
  final String medicineType;
  final String frequency;
  final List<MedicationHistory> history;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.time,
    this.isTaken = false,
    this.takenAt,
    required this.startDate,
    required this.endDate,
    required this.medicineType,
    required this.frequency,
    this.history = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'time': '${time.hour}:${time.minute}',
      'isTaken': isTaken,
      'takenAt': takenAt?.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'medicineType': medicineType,
      'frequency': frequency,
      'history': history.map((h) => h.toJson()).toList(),
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      time: TimeOfDay(
        hour: int.parse(json['time'].split(':')[0]),
        minute: int.parse(json['time'].split(':')[1]),
      ),
      isTaken: json['isTaken'] ?? false,
      takenAt: json['takenAt'] != null ? DateTime.parse(json['takenAt']) : null,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      medicineType: json['medicineType'],
      frequency: json['frequency'],
      history: (json['history'] as List?)
          ?.map((h) => MedicationHistory.fromJson(h))
          .toList() ?? [],
    );
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    TimeOfDay? time,
    bool? isTaken,
    DateTime? takenAt,
    DateTime? startDate,
    DateTime? endDate,
    String? medicineType,
    String? frequency,
    List<MedicationHistory>? history,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      isTaken: isTaken ?? this.isTaken,
      takenAt: takenAt ?? this.takenAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      medicineType: medicineType ?? this.medicineType,
      frequency: frequency ?? this.frequency,
      history: history ?? this.history,
    );
  }
}

class MedicationHistory {
  final DateTime date;
  final TimeOfDay time;
  final String status; // 'Taken' or 'Skipped'

  const MedicationHistory({
    required this.date,
    required this.time,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'status': status,
    };
  }

  factory MedicationHistory.fromJson(Map<String, dynamic> json) {
    return MedicationHistory(
      date: DateTime.parse(json['date']),
      time: TimeOfDay(
        hour: int.parse(json['time'].split(':')[0]),
        minute: int.parse(json['time'].split(':')[1]),
      ),
      status: json['status'],
    );
  }
} 