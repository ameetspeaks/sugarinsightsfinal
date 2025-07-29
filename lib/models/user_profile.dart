class UserProfile {
  final String? id;
  final String name;
  final String gender;
  final DateTime dateOfBirth;
  final List<String> languages;
  final double height;
  final double weight;
  final String uniqueId;
  final bool hasDiabetes;
  final String? diabetesType;
  final String? diagnosisTimeline;
  final double bmi;

  UserProfile({
    this.id,
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    required this.languages,
    required this.height,
    required this.weight,
    required this.uniqueId,
    required this.hasDiabetes,
    this.diabetesType,
    this.diagnosisTimeline,
    required this.bmi,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gender': gender,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'languages': languages,
        'height': height,
        'weight': weight,
        'uniqueId': uniqueId,
        'hasDiabetes': hasDiabetes,
        'diabetesType': diabetesType,
        'diagnosisTimeline': diagnosisTimeline,
        'bmi': bmi,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        name: json['name'],
        gender: json['gender'],
        dateOfBirth: DateTime.parse(json['dateOfBirth']),
        languages: List<String>.from(json['languages']),
        height: json['height'],
        weight: json['weight'],
        uniqueId: json['uniqueId'],
        hasDiabetes: json['hasDiabetes'],
        diabetesType: json['diabetesType'],
        diagnosisTimeline: json['diagnosisTimeline'],
        bmi: json['bmi'],
      );

  UserProfile copyWith({
    String? id,
    String? name,
    String? gender,
    DateTime? dateOfBirth,
    List<String>? languages,
    double? height,
    double? weight,
    String? uniqueId,
    bool? hasDiabetes,
    String? diabetesType,
    String? diagnosisTimeline,
    double? bmi,
  }) =>
      UserProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        languages: languages ?? this.languages,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        uniqueId: uniqueId ?? this.uniqueId,
        hasDiabetes: hasDiabetes ?? this.hasDiabetes,
        diabetesType: diabetesType ?? this.diabetesType,
        diagnosisTimeline: diagnosisTimeline ?? this.diagnosisTimeline,
        bmi: bmi ?? this.bmi,
      );
} 