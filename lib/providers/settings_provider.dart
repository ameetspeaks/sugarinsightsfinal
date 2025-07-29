import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/local_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();
  bool _isLoading = false;
  LocalStorageService? _storageService;

  // Getters
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  // Initialize settings from local storage
  Future<void> initialize() async {
    _isLoading = true;
    _storageService = await LocalStorageService.getInstance();
    await _loadSettings();
    _isLoading = false;
  }

  Future<void> _loadSettings() async {
    if (_storageService != null) {
      _settings = await _storageService!.getAppSettings();
    }
  }

  Future<void> _saveSettings() async {
    if (_storageService != null) {
      await _storageService!.saveAppSettings(_settings);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Language Settings
  Future<void> setLanguage(String language) async {
    _settings = _settings.copyWith(language: language);
    await _saveSettings();
    notifyListeners();
  }

  // Theme Settings
  Future<void> setTheme(String theme) async {
    _settings = _settings.copyWith(theme: theme);
    await _saveSettings();
    notifyListeners();
  }

  // Notification Settings
  Future<void> setNotificationsEnabled(bool enabled) async {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setGlucoseRemindersEnabled(bool enabled) async {
    _settings = _settings.copyWith(glucoseRemindersEnabled: enabled);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setMedicationRemindersEnabled(bool enabled) async {
    _settings = _settings.copyWith(medicationRemindersEnabled: enabled);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setDietTrackingEnabled(bool enabled) async {
    _settings = _settings.copyWith(dietTrackingEnabled: enabled);
    await _saveSettings();
    notifyListeners();
  }

  // Unit Settings
  Future<void> setGlucoseUnit(String unit) async {
    _settings = _settings.copyWith(glucoseUnit: unit);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setWeightUnit(String unit) async {
    _settings = _settings.copyWith(weightUnit: unit);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setHeightUnit(String unit) async {
    _settings = _settings.copyWith(heightUnit: unit);
    await _saveSettings();
    notifyListeners();
  }

  // Reminder Time Settings
  Future<void> setGlucoseReminderTime(TimeOfDay? time) async {
    _settings = _settings.copyWith(glucoseReminderTime: time);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setMedicationReminderTime(TimeOfDay? time) async {
    _settings = _settings.copyWith(medicationReminderTime: time);
    await _saveSettings();
    notifyListeners();
  }

  // Feature Settings
  Future<void> setEnabledFeatures(List<String> features) async {
    _settings = _settings.copyWith(enabledFeatures: features);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleFeature(String feature) async {
    final currentFeatures = List<String>.from(_settings.enabledFeatures);
    if (currentFeatures.contains(feature)) {
      currentFeatures.remove(feature);
    } else {
      currentFeatures.add(feature);
    }
    await setEnabledFeatures(currentFeatures);
  }

  // Custom Preferences
  Future<void> setCustomPreference(String key, dynamic value) async {
    final customPrefs = Map<String, dynamic>.from(_settings.customPreferences);
    customPrefs[key] = value;
    _settings = _settings.copyWith(customPreferences: customPrefs);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> removeCustomPreference(String key) async {
    final customPrefs = Map<String, dynamic>.from(_settings.customPreferences);
    customPrefs.remove(key);
    _settings = _settings.copyWith(customPreferences: customPrefs);
    await _saveSettings();
    notifyListeners();
  }

  // Reset Settings
  Future<void> resetToDefaults() async {
    _settings = const AppSettings();
    await _saveSettings();
    notifyListeners();
  }

  // Export/Import Settings (for future use)
  Map<String, dynamic> exportSettings() {
    return _settings.toJson();
  }

  Future<void> importSettings(Map<String, dynamic> settingsJson) async {
    _settings = AppSettings.fromJson(settingsJson);
    await _saveSettings();
    notifyListeners();
  }

  // Utility Methods
  bool isFeatureEnabled(String feature) {
    return _settings.enabledFeatures.contains(feature);
  }

  String getGlucoseUnitDisplay() {
    return _settings.glucoseUnit == 'mg/dL' ? 'mg/dL' : 'mmol/L';
  }

  String getWeightUnitDisplay() {
    return _settings.weightUnit == 'kg' ? 'kg' : 'lbs';
  }

  String getHeightUnitDisplay() {
    return _settings.heightUnit == 'cm' ? 'cm' : 'ft';
  }

  // Convert glucose values between units
  double convertGlucoseValue(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;
    
    if (fromUnit == 'mg/dL' && toUnit == 'mmol/L') {
      return value / 18.0; // Convert mg/dL to mmol/L
    } else if (fromUnit == 'mmol/L' && toUnit == 'mg/dL') {
      return value * 18.0; // Convert mmol/L to mg/dL
    }
    
    return value; // Return original value if conversion not supported
  }

  // Convert weight values between units
  double convertWeightValue(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;
    
    if (fromUnit == 'kg' && toUnit == 'lbs') {
      return value * 2.20462; // Convert kg to lbs
    } else if (fromUnit == 'lbs' && toUnit == 'kg') {
      return value / 2.20462; // Convert lbs to kg
    }
    
    return value; // Return original value if conversion not supported
  }

  // Convert height values between units
  double convertHeightValue(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;
    
    if (fromUnit == 'cm' && toUnit == 'ft') {
      return value / 30.48; // Convert cm to ft
    } else if (fromUnit == 'ft' && toUnit == 'cm') {
      return value * 30.48; // Convert ft to cm
    }
    
    return value; // Return original value if conversion not supported
  }
} 