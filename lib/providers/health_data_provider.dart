import 'package:flutter/material.dart';
import '../models/glucose_reading.dart';
import '../models/medication.dart';
import '../models/food_entry.dart';
import '../models/blood_pressure.dart';
import '../services/local_storage_service.dart';

class HealthDataProvider extends ChangeNotifier {
  List<GlucoseReading> _glucoseReadings = [];
  List<Medication> _medications = [];
  List<FoodEntry> _foodEntries = [];
  List<BloodPressure> _bloodPressureReadings = [];
  bool _isLoading = false;
  LocalStorageService? _storageService;

  // Getters
  List<GlucoseReading> get glucoseReadings => _glucoseReadings;
  List<Medication> get medications => _medications;
  List<FoodEntry> get foodEntries => _foodEntries;
  List<BloodPressure> get bloodPressureReadings => _bloodPressureReadings;
  bool get isLoading => _isLoading;

  // Initialize health data from local storage
  Future<void> initialize() async {
    _isLoading = true;
    _storageService = await LocalStorageService.getInstance();
    await _loadStoredData();
    _isLoading = false;
  }

  Future<void> _loadStoredData() async {
    try {
      final storageService = await LocalStorageService.getInstance();
      final storedGlucoseReadings = await storageService.getGlucoseReadings();
      final storedMedications = await storageService.getMedications();
      final storedFoodEntries = await storageService.getFoodEntries();
      final storedBloodPressureReadings = await storageService.getBloodPressureReadings();
      
      _glucoseReadings = storedGlucoseReadings;
      _medications = storedMedications;
      _foodEntries = storedFoodEntries;
      _bloodPressureReadings = storedBloodPressureReadings;
    } catch (e) {
      print('Error loading stored health data: $e');
    }
  }

  Future<void> _saveGlucoseReadings() async {
    if (_storageService != null) {
      await _storageService!.saveGlucoseReadings(_glucoseReadings);
    }
  }

  Future<void> _saveMedications() async {
    if (_storageService != null) {
      await _storageService!.saveMedications(_medications);
    }
  }

  Future<void> _saveFoodEntries() async {
    if (_storageService != null) {
      await _storageService!.saveFoodEntries(_foodEntries);
    }
  }

  Future<void> _saveBloodPressureReadings() async {
    if (_storageService != null) {
      await _storageService!.saveBloodPressureReadings(_bloodPressureReadings);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Glucose Readings
  Future<void> addGlucoseReading(GlucoseReading reading) async {
    _glucoseReadings.add(reading);
    _glucoseReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _saveGlucoseReadings();
    notifyListeners();
  }

  Future<void> updateGlucoseReading(GlucoseReading reading) async {
    final index = _glucoseReadings.indexWhere((r) => r.id == reading.id);
    if (index != -1) {
      _glucoseReadings[index] = reading;
      _glucoseReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _saveGlucoseReadings();
      notifyListeners();
    }
  }

  Future<void> deleteGlucoseReading(String id) async {
    _glucoseReadings.removeWhere((reading) => reading.id == id);
    await _saveGlucoseReadings();
    notifyListeners();
  }

  List<GlucoseReading> getGlucoseReadingsByDate(DateTime date) {
    return _glucoseReadings.where((reading) {
      final readingDate = DateTime(
        reading.timestamp.year,
        reading.timestamp.month,
        reading.timestamp.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return readingDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  // Get glucose readings for a date range
  List<GlucoseReading> getGlucoseReadingsByDateRange(DateTime startDate, DateTime endDate) {
    return _glucoseReadings.where((reading) {
      return reading.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
             reading.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get latest glucose reading
  GlucoseReading? getLatestGlucoseReading() {
    if (_glucoseReadings.isNotEmpty) {
      return _glucoseReadings.first;
    }
    return null;
  }

  // Get average glucose for a date range
  double? getAverageGlucose(DateTime startDate, DateTime endDate) {
    final readings = getGlucoseReadingsByDateRange(startDate, endDate);
    if (readings.isEmpty) return null;
    
    final total = readings.fold<double>(0, (sum, reading) => sum + reading.value);
    return total / readings.length;
  }

  // Medications
  Future<void> addMedication(Medication medication) async {
    _medications.add(medication);
    _medications.sort((a, b) => a.time.compareTo(b.time));
    await _saveMedications();
    notifyListeners();
  }

  Future<void> updateMedication(Medication medication) async {
    final index = _medications.indexWhere((m) => m.id == medication.id);
    if (index != -1) {
      _medications[index] = medication;
      _medications.sort((a, b) => a.time.compareTo(b.time));
      await _saveMedications();
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String id) async {
    _medications.removeWhere((medication) => medication.id == id);
    await _saveMedications();
    notifyListeners();
  }

  Future<void> markMedicationAsTaken(String id) async {
    final index = _medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      _medications[index] = _medications[index].copyWith(
        isTaken: true,
        takenAt: DateTime.now(),
      );
      await _saveMedications();
      notifyListeners();
    }
  }

  List<Medication> getMedicationsByDate(DateTime date) {
    return _medications.where((medication) {
      // For now, return all medications. In a real app, you'd filter by date
      return true;
    }).toList();
  }

  // Get medications for today
  List<Medication> getTodayMedications() {
    final today = DateTime.now();
    return _medications.where((medication) {
      // For now, return all medications. In a real app, you'd filter by schedule
      return true;
    }).toList();
  }

  // Get medications that need to be taken
  List<Medication> getPendingMedications() {
    return _medications.where((medication) => !medication.isTaken).toList();
  }

  // Food Entries
  Future<void> addFoodEntry(FoodEntry entry) async {
    _foodEntries.add(entry);
    _foodEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _saveFoodEntries();
    notifyListeners();
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    final index = _foodEntries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _foodEntries[index] = entry;
      _foodEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _saveFoodEntries();
      notifyListeners();
    }
  }

  Future<void> deleteFoodEntry(String id) async {
    _foodEntries.removeWhere((entry) => entry.id == id);
    await _saveFoodEntries();
    notifyListeners();
  }

  List<FoodEntry> getFoodEntriesByDate(DateTime date) {
    return _foodEntries.where((entry) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return entryDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  // Get food entries for a date range
  List<FoodEntry> getFoodEntriesByDateRange(DateTime startDate, DateTime endDate) {
    return _foodEntries.where((entry) {
      return entry.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
             entry.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get total calories for a date
  double getTotalCaloriesForDate(DateTime date) {
    final entries = getFoodEntriesByDate(date);
    return entries.fold<double>(0, (sum, entry) => sum + entry.calories);
  }

  // Get total calories for a date range
  double getTotalCaloriesForDateRange(DateTime startDate, DateTime endDate) {
    final entries = getFoodEntriesByDateRange(startDate, endDate);
    return entries.fold<double>(0, (sum, entry) => sum + entry.calories);
  }

  // Get nutritional summary for a date
  Map<String, double> getNutritionalSummaryForDate(DateTime date) {
    final entries = getFoodEntriesByDate(date);
    double totalCalories = 0;
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (final entry in entries) {
      totalCalories += entry.calories;
      totalCarbs += entry.carbs;
      totalProtein += entry.protein;
      totalFat += entry.fat;
    }

    return {
      'calories': totalCalories,
      'carbs': totalCarbs,
      'protein': totalProtein,
      'fat': totalFat,
    };
  }

  // Loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Load sample data
  Future<void> loadSampleData() async {
    // Sample glucose readings
    _glucoseReadings = [
      GlucoseReading(
        id: '1',
        value: 120,
        type: GlucoseType.fasting,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        userId: '1',
        notes: 'Before breakfast',
      ),
      GlucoseReading(
        id: '2',
        value: 180,
        type: GlucoseType.postMeal,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        userId: '1',
        notes: 'After breakfast',
      ),
    ];

    // Sample medications
    _medications = [
      Medication(
        name: 'Metformin',
        dosage: '500mg',
        times: [TimeOfDay(hour: 12, minute: 30)],
        isTaken: false,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        medicineType: 'Tablet',
        frequency: 'Once daily',
      ),
      Medication(
        name: 'Omega 3',
        dosage: '1000mg',
        times: [TimeOfDay(hour: 21, minute: 0)],
        isTaken: false,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        medicineType: 'Capsule',
        frequency: 'Once daily',
      ),
    ];

    // Sample food entries
    _foodEntries = [
      FoodEntry(
        id: '1',
        name: 'Oatmeal',
        description: 'Healthy breakfast option',
        calories: 150,
        carbs: 27,
        protein: 5,
        fat: 3,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        mealType: 'Breakfast',
      ),
      FoodEntry(
        id: '2',
        name: 'Grilled Chicken',
        description: 'Lean protein source',
        calories: 200,
        carbs: 0,
        protein: 35,
        fat: 8,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        mealType: 'Lunch',
      ),
    ];

    // Save to local storage
    await _saveGlucoseReadings();
    await _saveMedications();
    await _saveFoodEntries();
    
    notifyListeners();
  }

  // Clear all data
  Future<void> clearAllData() async {
    _glucoseReadings.clear();
    _medications.clear();
    _foodEntries.clear();
    
    if (_storageService != null) {
      await _storageService!.clearHealthData();
    }
    
    notifyListeners();
  }

  // Export health data
  Map<String, dynamic> exportHealthData() {
    return {
      'glucoseReadings': _glucoseReadings.map((r) => r.toJson()).toList(),
      'medications': _medications.map((m) => m.toJson()).toList(),
      'foodEntries': _foodEntries.map((e) => e.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  // Import health data
  Future<void> importHealthData(Map<String, dynamic> data) async {
    if (data['glucoseReadings'] != null) {
      final readingsList = data['glucoseReadings'] as List;
      _glucoseReadings = readingsList.map((json) => GlucoseReading.fromJson(json)).toList();
    }
    
    if (data['medications'] != null) {
      final medicationsList = data['medications'] as List;
      _medications = medicationsList.map((json) => Medication.fromJson(json)).toList();
    }
    
    if (data['foodEntries'] != null) {
      final entriesList = data['foodEntries'] as List;
      _foodEntries = entriesList.map((json) => FoodEntry.fromJson(json)).toList();
    }
    
    // Save to local storage
    await _saveGlucoseReadings();
    await _saveMedications();
    await _saveFoodEntries();
    
    notifyListeners();
  }

  // Add blood pressure reading
  void addBloodPressure(BloodPressure bloodPressure) {
    _bloodPressureReadings.add(bloodPressure);
    _saveBloodPressureReadings();
    notifyListeners();
  }
} 