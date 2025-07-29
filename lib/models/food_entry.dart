class FoodEntry {
  final String? id;
  final String name;
  final String description;
  final DateTime timestamp;
  final String? imageUrl;
  final int calories; // Added missing calories parameter
  final double carbs; // Added missing carbs parameter
  final double protein; // Added missing protein parameter
  final double fat; // Added missing fat parameter
  final String mealType; // Added missing mealType parameter

  FoodEntry({
    this.id,
    required this.name,
    required this.description,
    required this.timestamp,
    this.imageUrl,
    required this.calories, // Added to constructor
    required this.carbs, // Added to constructor
    required this.protein, // Added to constructor
    required this.fat, // Added to constructor
    required this.mealType, // Added to constructor
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'imageUrl': imageUrl,
        'calories': calories, // Added to toJson
        'carbs': carbs, // Added to toJson
        'protein': protein, // Added to toJson
        'fat': fat, // Added to toJson
        'mealType': mealType, // Added to toJson
      };

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        timestamp: DateTime.parse(json['timestamp']),
        imageUrl: json['imageUrl'],
        calories: json['calories'], // Added to fromJson
        carbs: json['carbs'], // Added to fromJson
        protein: json['protein'], // Added to fromJson
        fat: json['fat'], // Added to fromJson
        mealType: json['mealType'], // Added to fromJson
      );

  FoodEntry copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? timestamp,
    String? imageUrl,
    int? calories, // Added to copyWith
    double? carbs, // Added to copyWith
    double? protein, // Added to copyWith
    double? fat, // Added to copyWith
    String? mealType, // Added to copyWith
  }) =>
      FoodEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        timestamp: timestamp ?? this.timestamp,
        imageUrl: imageUrl ?? this.imageUrl,
        calories: calories ?? this.calories, // Added to copyWith body
        carbs: carbs ?? this.carbs, // Added to copyWith body
        protein: protein ?? this.protein, // Added to copyWith body
        fat: fat ?? this.fat, // Added to copyWith body
        mealType: mealType ?? this.mealType, // Added to copyWith body
      );
} 