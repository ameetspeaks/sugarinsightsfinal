enum GlucoseType {
  fasting,
  postMeal,
}

class GlucoseReading {
  final String? id;
  final double value;
  final GlucoseType type;
  final DateTime timestamp;
  final String userId;
  final String? notes;

  GlucoseReading({
    this.id,
    required this.value,
    required this.type,
    required this.timestamp,
    required this.userId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
        'type': type.toString(),
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        'notes': notes,
      };

  factory GlucoseReading.fromJson(Map<String, dynamic> json) => GlucoseReading(
        id: json['id'],
        value: json['value'],
        type: GlucoseType.values.firstWhere(
            (e) => e.toString() == json['type'],
            orElse: () => GlucoseType.fasting),
        timestamp: DateTime.parse(json['timestamp']),
        userId: json['userId'],
        notes: json['notes'],
      );

  GlucoseReading copyWith({
    String? id,
    double? value,
    GlucoseType? type,
    DateTime? timestamp,
    String? userId,
    String? notes,
  }) =>
      GlucoseReading(
        id: id ?? this.id,
        value: value ?? this.value,
        type: type ?? this.type,
        timestamp: timestamp ?? this.timestamp,
        userId: userId ?? this.userId,
        notes: notes ?? this.notes,
      );
} 