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
        'image_url': imageUrl,
        'calories': calories,
        'carbs': carbs,
        'protein': protein,
        'fat': fat,
        'meal_type': mealType,
      };

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        timestamp: DateTime.parse(json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
        imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
        calories: (json['calories'] is int) ? json['calories'] : int.tryParse(json['calories']?.toString() ?? '0') ?? 0,
        carbs: (json['carbs'] is double) ? json['carbs'] : double.tryParse(json['carbs']?.toString() ?? '0.0') ?? 0.0,
        protein: (json['protein'] is double) ? json['protein'] : double.tryParse(json['protein']?.toString() ?? '0.0') ?? 0.0,
        fat: (json['fat'] is double) ? json['fat'] : double.tryParse(json['fat']?.toString() ?? '0.0') ?? 0.0,
        mealType: json['meal_type']?.toString() ?? json['mealType']?.toString() ?? 'Breakfast',
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