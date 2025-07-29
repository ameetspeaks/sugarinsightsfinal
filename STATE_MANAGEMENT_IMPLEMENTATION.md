# State Management & Local Storage Implementation

## Overview

The Sugar Insights app now has a comprehensive state management system with full local storage integration using the Provider pattern and SharedPreferences. This ensures all user data, settings, and preferences are preserved across app sessions.

## Architecture

### Core Components

1. **Models** - Data structures for app entities
2. **Providers** - State management using ChangeNotifier
3. **Services** - Local storage and data persistence
4. **Screens** - UI components that consume state

## Models

### AppSettings
```dart
class AppSettings {
  final String language;           // 'en' or 'hi'
  final String theme;              // 'light' or 'dark'
  final bool notificationsEnabled;
  final bool glucoseRemindersEnabled;
  final bool medicationRemindersEnabled;
  final bool dietTrackingEnabled;
  final String glucoseUnit;        // 'mg/dL' or 'mmol/L'
  final String weightUnit;         // 'kg' or 'lbs'
  final String heightUnit;         // 'cm' or 'ft'
  final TimeOfDay? glucoseReminderTime;
  final TimeOfDay? medicationReminderTime;
  final List<String> enabledFeatures;
  final Map<String, dynamic> customPreferences;
}
```

### User
```dart
class User {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? uniqueId;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? height;
  final double? weight;
  final String? bloodType;
  final List<String>? allergies;
  final List<String>? medications;
  final Map<String, dynamic>? preferences;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

## Providers

### AppStateProvider
Manages user authentication, onboarding status, and user profile data.

**Key Features:**
- ✅ User authentication state
- ✅ Onboarding completion tracking
- ✅ User profile management
- ✅ Local storage integration
- ✅ Data export/import functionality

**Methods:**
```dart
// Authentication
Future<void> signIn(String email, String password)
Future<void> signUp(String email, String password)
Future<void> verifyOtp(String otp)
Future<void> signOut()

// User Management
Future<void> updateUserProfile({...})
Future<void> clearAllUserData()
Map<String, dynamic>? exportUserData()
Future<void> importUserData(Map<String, dynamic> data)

// State Queries
bool get hasCompletedOnboarding
Future<bool> hasStoredUser()
```

### HealthDataProvider
Manages all health-related data including glucose readings, medications, and food entries.

**Key Features:**
- ✅ Glucose readings with date filtering
- ✅ Medication tracking and reminders
- ✅ Food entry management with nutritional data
- ✅ Statistical calculations (averages, summaries)
- ✅ Local storage persistence

**Methods:**
```dart
// Glucose Readings
Future<void> addGlucoseReading(GlucoseReading reading)
Future<void> updateGlucoseReading(GlucoseReading reading)
Future<void> deleteGlucoseReading(String id)
List<GlucoseReading> getGlucoseReadingsByDate(DateTime date)
List<GlucoseReading> getGlucoseReadingsByDateRange(DateTime start, DateTime end)
GlucoseReading? getLatestGlucoseReading()
double? getAverageGlucose(DateTime start, DateTime end)

// Medications
Future<void> addMedication(Medication medication)
Future<void> updateMedication(Medication medication)
Future<void> deleteMedication(String id)
Future<void> markMedicationAsTaken(String id)
List<Medication> getTodayMedications()
List<Medication> getPendingMedications()

// Food Entries
Future<void> addFoodEntry(FoodEntry entry)
Future<void> updateFoodEntry(FoodEntry entry)
Future<void> deleteFoodEntry(String id)
List<FoodEntry> getFoodEntriesByDate(DateTime date)
double getTotalCaloriesForDate(DateTime date)
Map<String, double> getNutritionalSummaryForDate(DateTime date)

// Data Management
Future<void> clearAllData()
Map<String, dynamic> exportHealthData()
Future<void> importHealthData(Map<String, dynamic> data)
```

### SettingsProvider
Manages app preferences, units, notifications, and feature toggles.

**Key Features:**
- ✅ Language and theme settings
- ✅ Health unit preferences
- ✅ Notification settings
- ✅ Feature toggles
- ✅ Unit conversion utilities
- ✅ Custom preferences storage

**Methods:**
```dart
// Settings Management
Future<void> setLanguage(String language)
Future<void> setTheme(String theme)
Future<void> setNotificationsEnabled(bool enabled)
Future<void> setGlucoseUnit(String unit)
Future<void> setWeightUnit(String unit)
Future<void> setHeightUnit(String unit)

// Feature Management
Future<void> toggleFeature(String feature)
bool isFeatureEnabled(String feature)

// Unit Conversions
double convertGlucoseValue(double value, String fromUnit, String toUnit)
double convertWeightValue(double value, String fromUnit, String toUnit)
double convertHeightValue(double value, String fromUnit, String toUnit)

// Data Management
Future<void> resetToDefaults()
Map<String, dynamic> exportSettings()
Future<void> importSettings(Map<String, dynamic> settingsJson)
```

### NavigationProvider
Manages bottom navigation state and screen transitions.

## Local Storage Service

### LocalStorageService
Singleton service for persistent data storage using SharedPreferences.

**Storage Keys:**
- `user` - User profile data
- `app_settings` - App preferences
- `glucose_readings` - Glucose measurement history
- `medications` - Medication list
- `food_entries` - Food tracking data
- `auth_token` - Authentication token
- `is_onboarding_complete` - Onboarding status
- `unique_id` - User unique identifier

**Methods:**
```dart
// User Data
Future<void> saveUser(User user)
Future<User?> getUser()
Future<void> deleteUser()

// Settings
Future<void> saveAppSettings(AppSettings settings)
Future<AppSettings> getAppSettings()

// Health Data
Future<void> saveGlucoseReadings(List<GlucoseReading> readings)
Future<List<GlucoseReading>> getGlucoseReadings()
Future<void> saveMedications(List<Medication> medications)
Future<List<Medication>> getMedications()
Future<void> saveFoodEntries(List<FoodEntry> entries)
Future<List<FoodEntry>> getFoodEntries()

// Authentication
Future<void> saveAuthToken(String token)
Future<String?> getAuthToken()
Future<void> deleteAuthToken()

// Onboarding
Future<void> setOnboardingComplete(bool isComplete)
Future<bool> isOnboardingComplete()
Future<void> saveUniqueId(String uniqueId)
Future<String?> getUniqueId()

// Utilities
Future<void> clearAllData()
Future<void> clearHealthData()
Future<bool> hasStoredData()
Future<void> migrateData()
```

## App Initialization

### AppInitializer
Ensures all providers are properly initialized with local storage before the app starts.

```dart
class AppInitializer extends StatefulWidget {
  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    final healthDataProvider = Provider.of<HealthDataProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    await Future.wait([
      appStateProvider.initialize(),
      healthDataProvider.initialize(),
      settingsProvider.initialize(),
    ]);

    setState(() {
      _isInitialized = true;
    });
  }
}
```

## Settings Screen

### Features
- **App Preferences**: Language, theme selection
- **Health Units**: Glucose, weight, height unit preferences
- **Notifications**: Enable/disable various reminder types
- **Features**: Toggle app features on/off
- **Data Management**: Export, clear data, reset settings

### Implementation
```dart
class SettingsScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        // Settings UI with real-time updates
      },
    );
  }
}
```

## Data Flow

### 1. App Startup
```
App starts → AppInitializer → Load data from SharedPreferences → Initialize providers → Show app
```

### 2. User Authentication
```
User signs in → AppStateProvider.signIn() → Save to local storage → Update UI
```

### 3. Health Data Entry
```
User adds data → Provider method → Save to local storage → Update UI
```

### 4. Settings Changes
```
User changes setting → SettingsProvider method → Save to local storage → Update UI
```

## Usage Examples

### Adding Glucose Reading
```dart
final healthDataProvider = Provider.of<HealthDataProvider>(context, listen: false);
await healthDataProvider.addGlucoseReading(
  GlucoseReading(
    id: '1',
    value: 120,
    type: GlucoseType.fasting,
    timestamp: DateTime.now(),
    userId: '1',
    notes: 'Before breakfast',
  ),
);
```

### Changing App Settings
```dart
final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
await settingsProvider.setGlucoseUnit('mmol/L');
await settingsProvider.setNotificationsEnabled(false);
```

### Exporting User Data
```dart
final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
final userData = appStateProvider.exportUserData();
// Save userData to file or cloud storage
```

## Benefits

### 1. Data Persistence
- ✅ All data survives app restarts
- ✅ User preferences are remembered
- ✅ Health data is preserved
- ✅ Authentication state is maintained

### 2. Performance
- ✅ Fast app startup with cached data
- ✅ Efficient state updates
- ✅ Minimal memory usage

### 3. User Experience
- ✅ Seamless app experience
- ✅ No data loss between sessions
- ✅ Real-time settings updates
- ✅ Offline functionality

### 4. Maintainability
- ✅ Clean separation of concerns
- ✅ Easy to test and debug
- ✅ Scalable architecture
- ✅ Future-proof design

## Future Enhancements

### 1. Cloud Sync
- Implement cloud storage for data backup
- Sync data across multiple devices
- Offline-first with conflict resolution

### 2. Advanced Analytics
- Health trend analysis
- Predictive insights
- Custom reports generation

### 3. Notifications
- Local push notifications
- Medication reminders
- Glucose check reminders

### 4. Data Export
- PDF report generation
- CSV data export
- Integration with health apps

## Testing

### Provider Testing
```dart
test('AppStateProvider should save user data', () async {
  final provider = AppStateProvider();
  await provider.initialize();
  
  final user = User(...);
  await provider.completeOnboarding(user);
  
  expect(provider.currentUser, equals(user));
  expect(provider.isAuthenticated, isTrue);
});
```

### Local Storage Testing
```dart
test('LocalStorageService should save and retrieve data', () async {
  final service = await LocalStorageService.getInstance();
  
  final user = User(...);
  await service.saveUser(user);
  
  final retrievedUser = await service.getUser();
  expect(retrievedUser, equals(user));
});
```

## Conclusion

The state management and local storage implementation provides a robust foundation for the Sugar Insights app. It ensures data persistence, provides excellent user experience, and maintains clean, maintainable code architecture. The implementation follows Flutter best practices and is ready for future enhancements and scaling. 