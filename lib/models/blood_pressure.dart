class BloodPressure {
  final String? id;
  final int systolic;
  final int diastolic;
  final DateTime timestamp;
  final String userId;
  final String? notes;

  BloodPressure({
    this.id,
    required this.systolic,
    required this.diastolic,
    required this.timestamp,
    required this.userId,
    this.notes,
  });

  String get reading => '$systolic/$diastolic';

  String get status {
    if (systolic < 120 && diastolic < 80) return 'Normal';
    if (systolic < 130 && diastolic < 80) return 'Elevated';
    if (systolic < 140 || diastolic < 90) return 'Stage 1';
    return 'Stage 2';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'systolic': systolic,
        'diastolic': diastolic,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        'notes': notes,
      };

  factory BloodPressure.fromJson(Map<String, dynamic> json) => BloodPressure(
        id: json['id'],
        systolic: json['systolic'],
        diastolic: json['diastolic'],
        timestamp: DateTime.parse(json['timestamp']),
        userId: json['userId'],
        notes: json['notes'],
      );

  BloodPressure copyWith({
    String? id,
    int? systolic,
    int? diastolic,
    DateTime? timestamp,
    String? userId,
    String? notes,
  }) =>
      BloodPressure(
        id: id ?? this.id,
        systolic: systolic ?? this.systolic,
        diastolic: diastolic ?? this.diastolic,
        timestamp: timestamp ?? this.timestamp,
        userId: userId ?? this.userId,
        notes: notes ?? this.notes,
      );
} 