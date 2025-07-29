class User {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? role;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? height;
  final double? weight;
  final String? diabetesType;
  final DateTime? diagnosisDate;
  final String? uniqueId;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.role,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.diabetesType,
    this.diagnosisDate,
    this.uniqueId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      diabetesType: json['diabetes_type'],
      diagnosisDate: json['diagnosis_date'] != null
          ? DateTime.parse(json['diagnosis_date'])
          : null,
      uniqueId: json['unique_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'diabetes_type': diabetesType,
      'diagnosis_date': diagnosisDate?.toIso8601String(),
      'unique_id': uniqueId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    String? phone,
    String? role,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? diabetesType,
    DateTime? diagnosisDate,
    String? uniqueId,
  }) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      diabetesType: diabetesType ?? this.diabetesType,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      uniqueId: uniqueId ?? this.uniqueId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 