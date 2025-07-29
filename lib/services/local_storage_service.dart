import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/app_settings.dart';
import '../models/glucose_reading.dart';
import '../models/medication.dart';
import '../models/food_entry.dart';
import '../models/blood_pressure.dart';

class LocalStorageService {
  static const String _userKey = 'user';
  static const String _settingsKey = 'app_settings';
  static const String _glucoseReadingsKey = 'glucose_readings';
  static const String _medicationsKey = 'medications';
  static const String _foodEntriesKey = 'food_entries';
  static const String _authTokenKey = 'auth_token';
  static const String _isOnboardingCompleteKey = 'is_onboarding_complete';
  static const String _uniqueIdKey = 'unique_id';

  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // User Data Methods
  Future<void> saveUser(User user) async {
    if (_prefs != null) {
      await _prefs!.setString(_userKey, jsonEncode(user.toJson()));
    }
  }

  Future<User?> getUser() async {
    if (_prefs != null) {
      final userJson = _prefs!.getString(_userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
    }
    return null;
  }

  Future<void> deleteUser() async {
    if (_prefs != null) {
      await _prefs!.remove(_userKey);
    }
  }

  // App Settings Methods
  Future<void> saveAppSettings(AppSettings settings) async {
    if (_prefs != null) {
      await _prefs!.setString(_settingsKey, jsonEncode(settings.toJson()));
    }
  }

  Future<AppSettings> getAppSettings() async {
    if (_prefs != null) {
      final settingsJson = _prefs!.getString(_settingsKey);
      if (settingsJson != null) {
        return AppSettings.fromJson(jsonDecode(settingsJson));
      }
    }
    return const AppSettings(); // Return default settings
  }

  // Authentication Methods
  Future<void> saveAuthToken(String token) async {
    if (_prefs != null) {
      await _prefs!.setString(_authTokenKey, token);
    }
  }

  Future<String?> getAuthToken() async {
    if (_prefs != null) {
      return _prefs!.getString(_authTokenKey);
    }
    return null;
  }

  Future<void> deleteAuthToken() async {
    if (_prefs != null) {
      await _prefs!.remove(_authTokenKey);
    }
  }

  // Onboarding Methods
  Future<void> setOnboardingComplete(bool isComplete) async {
    if (_prefs != null) {
      await _prefs!.setBool(_isOnboardingCompleteKey, isComplete);
    }
  }

  Future<bool> isOnboardingComplete() async {
    if (_prefs != null) {
      return _prefs!.getBool(_isOnboardingCompleteKey) ?? false;
    }
    return false;
  }

  Future<void> saveUniqueId(String uniqueId) async {
    if (_prefs != null) {
      await _prefs!.setString(_uniqueIdKey, uniqueId);
    }
  }

  Future<String?> getUniqueId() async {
    if (_prefs != null) {
      return _prefs!.getString(_uniqueIdKey);
    }
    return null;
  }

  // Health Data Methods
  Future<void> saveGlucoseReadings(List<GlucoseReading> readings) async {
    if (_prefs != null) {
      final readingsJson = readings.map((r) => r.toJson()).toList();
      await _prefs!.setString(_glucoseReadingsKey, jsonEncode(readingsJson));
    }
  }

  Future<List<GlucoseReading>> getGlucoseReadings() async {
    if (_prefs != null) {
      final readingsJson = _prefs!.getString(_glucoseReadingsKey);
      if (readingsJson != null) {
        final List<dynamic> readingsList = jsonDecode(readingsJson);
        return readingsList.map((json) => GlucoseReading.fromJson(json)).toList();
      }
    }
    return [];
  }

  Future<void> saveMedications(List<Medication> medications) async {
    if (_prefs != null) {
      final medicationsJson = medications.map((m) => m.toJson()).toList();
      await _prefs!.setString(_medicationsKey, jsonEncode(medicationsJson));
    }
  }

  Future<List<Medication>> getMedications() async {
    if (_prefs != null) {
      final medicationsJson = _prefs!.getString(_medicationsKey);
      if (medicationsJson != null) {
        final List<dynamic> medicationsList = jsonDecode(medicationsJson);
        return medicationsList.map((json) => Medication.fromJson(json)).toList();
      }
    }
    return [];
  }

  Future<void> saveFoodEntries(List<FoodEntry> entries) async {
    if (_prefs != null) {
      final entriesJson = entries.map((e) => e.toJson()).toList();
      await _prefs!.setString(_foodEntriesKey, jsonEncode(entriesJson));
    }
  }

  Future<List<FoodEntry>> getFoodEntries() async {
    if (_prefs != null) {
      final entriesJson = _prefs!.getString(_foodEntriesKey);
      if (entriesJson != null) {
        final List<dynamic> entriesList = jsonDecode(entriesJson);
        return entriesList.map((json) => FoodEntry.fromJson(json)).toList();
      }
    }
    return [];
  }

  // Blood Pressure Readings
  Future<void> saveBloodPressureReadings(List<BloodPressure> readings) async {
    if (_prefs != null) {
      final readingsJson = readings.map((reading) => reading.toJson()).toList();
      await _prefs!.setString('blood_pressure_readings', jsonEncode(readingsJson));
    }
  }

  Future<List<BloodPressure>> getBloodPressureReadings() async {
    if (_prefs != null) {
      final readingsJson = _prefs!.getString('blood_pressure_readings');
      if (readingsJson != null) {
        final List<dynamic> readingsList = jsonDecode(readingsJson);
        return readingsList.map((json) => BloodPressure.fromJson(json)).toList();
      }
    }
    return [];
  }

  // Utility Methods
  Future<void> clearAllData() async {
    if (_prefs != null) {
      await _prefs!.clear();
    }
  }

  Future<void> clearHealthData() async {
    if (_prefs != null) {
      await _prefs!.remove(_glucoseReadingsKey);
      await _prefs!.remove(_medicationsKey);
      await _prefs!.remove(_foodEntriesKey);
    }
  }

  Future<bool> hasStoredData() async {
    if (_prefs != null) {
      return _prefs!.getString(_userKey) != null ||
             _prefs!.getString(_glucoseReadingsKey) != null ||
             _prefs!.getString(_medicationsKey) != null ||
             _prefs!.getString(_foodEntriesKey) != null;
    }
    return false;
  }

  // Migration Methods (for future app updates)
  Future<void> migrateData() async {
    // This method can be used to migrate data when app structure changes
    // For now, it's empty but can be implemented as needed
  }
} 