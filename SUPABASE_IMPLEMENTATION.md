# Supabase Implementation Guide

## Setup

1. Add dependencies to `pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^latest_version
  flutter_local_notifications: ^latest_version
```

2. Initialize Supabase in `main.dart`:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(const MyApp());
}
```

## Authentication Service

```dart
class AuthService {
  final supabase = Supabase.instance.client;

  // Sign up with email
  Future<void> signUpWithEmail(String email) async {
    await supabase.auth.signUp(
      email: email,
      data: {'role': 'patient'}, // Default role
    );
  }

  // Verify OTP
  Future<AuthResponse> verifyOTP(String email, String token) async {
    return await supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  // Sign in with email
  Future<void> signInWithEmail(String email) async {
    await supabase.auth.signInWithOtp(
      email: email,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Get current user
  User? get currentUser => supabase.auth.currentUser;

  // Check if user is admin
  bool get isAdmin => currentUser?.userMetadata?['role'] == 'admin';

  // Stream of auth changes
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
```

## Database Services

### Profile Service
```dart
class ProfileService {
  final supabase = Supabase.instance.client;

  Future<Profile> getProfile(String userId) async {
    final data = await supabase
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();
    return Profile.fromJson(data);
  }

  Future<void> updateProfile(Profile profile) async {
    await supabase
      .from('profiles')
      .upsert(profile.toJson());
  }
}
```

### Medication Service
```dart
class MedicationService {
  final supabase = Supabase.instance.client;

  // Get all medications for user
  Future<List<Medication>> getMedications() async {
    final data = await supabase
      .from('medications')
      .select()
      .order('created_at');
    return data.map((json) => Medication.fromJson(json)).toList();
  }

  // Get upcoming medications
  Future<List<Medication>> getUpcomingMedications() async {
    final now = DateTime.now();
    final data = await supabase
      .from('medications')
      .select()
      .gte('end_date', now.toIso8601String())
      .order('time_of_day');
    return data.map((json) => Medication.fromJson(json)).toList();
  }

  // Add medication
  Future<void> addMedication(Medication medication) async {
    await supabase
      .from('medications')
      .insert(medication.toJson());
  }

  // Update medication
  Future<void> updateMedication(Medication medication) async {
    await supabase
      .from('medications')
      .update(medication.toJson())
      .eq('id', medication.id);
  }

  // Delete medication
  Future<void> deleteMedication(String id) async {
    await supabase
      .from('medications')
      .delete()
      .eq('id', id);
  }

  // Log medication taken
  Future<void> logMedicationTaken(String medicationId) async {
    final now = DateTime.now();
    await supabase.from('medication_history').insert({
      'medication_id': medicationId,
      'status': 'taken',
      'taken_at': now.toIso8601String(),
      'scheduled_for': now.toIso8601String(),
    });
  }

  // Log medication skipped
  Future<void> logMedicationSkipped(String medicationId) async {
    final now = DateTime.now();
    await supabase.from('medication_history').insert({
      'medication_id': medicationId,
      'status': 'skipped',
      'scheduled_for': now.toIso8601String(),
    });
  }
}
```

### Health Readings Service
```dart
class HealthReadingsService {
  final supabase = Supabase.instance.client;

  // Glucose readings
  Future<void> addGlucoseReading(GlucoseReading reading) async {
    await supabase
      .from('glucose_readings')
      .insert(reading.toJson());
  }

  Future<List<GlucoseReading>> getGlucoseReadings({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = supabase
      .from('glucose_readings')
      .select();
    
    if (startDate != null) {
      query = query.gte('reading_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('reading_date', endDate.toIso8601String());
    }
    
    final data = await query.order('reading_date');
    return data.map((json) => GlucoseReading.fromJson(json)).toList();
  }

  // Blood pressure readings
  Future<void> addBloodPressureReading(BloodPressureReading reading) async {
    await supabase
      .from('blood_pressure_readings')
      .insert(reading.toJson());
  }

  Future<List<BloodPressureReading>> getBloodPressureReadings({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = supabase
      .from('blood_pressure_readings')
      .select();
    
    if (startDate != null) {
      query = query.gte('reading_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('reading_date', endDate.toIso8601String());
    }
    
    final data = await query.order('reading_date');
    return data.map((json) => BloodPressureReading.fromJson(json)).toList();
  }

  // Other vital readings
  Future<void> addVitalReading(VitalReading reading) async {
    await supabase
      .from('other_vital_readings')
      .insert(reading.toJson());
  }

  Future<List<VitalReading>> getVitalReadings({
    String? vitalType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = supabase
      .from('other_vital_readings')
      .select();
    
    if (vitalType != null) {
      query = query.eq('vital_type', vitalType);
    }
    if (startDate != null) {
      query = query.gte('reading_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('reading_date', endDate.toIso8601String());
    }
    
    final data = await query.order('reading_date');
    return data.map((json) => VitalReading.fromJson(json)).toList();
  }
}
```

## Reminder Implementation

### Local Notifications Setup
```dart
class NotificationService {
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await notifications.initialize(initializationSettings);
  }

  Future<void> scheduleMedicationReminder(
    String id,
    String title,
    String body,
    DateTime scheduledDate,
  ) async {
    await notifications.zonedSchedule(
      id.hashCode,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
```

### Reminder Service
```dart
class ReminderService {
  final supabase = Supabase.instance.client;
  final NotificationService _notificationService;

  ReminderService(this._notificationService);

  Future<void> setupReminders(Medication medication) async {
    // Create reminder settings
    await supabase.from('reminder_settings').insert({
      'medication_id': medication.id,
      'reminder_type': 'both',
      'reminder_time': '15 minutes',
      'is_enabled': true,
    });

    // Schedule local notification
    for (var time in medication.timeOfDay) {
      final scheduledDate = _getNextOccurrence(time);
      await _notificationService.scheduleMedicationReminder(
        '${medication.id}-${time.hour}-${time.minute}',
        'Medication Reminder',
        'Time to take ${medication.name} ${medication.dosage}',
        scheduledDate,
      );
    }
  }

  DateTime _getNextOccurrence(TimeOfDay time) {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
```

## Error Handling

```dart
class SupabaseErrorHandler {
  static String handleError(dynamic error) {
    if (error is AuthException) {
      return _handleAuthError(error);
    } else if (error is PostgrestException) {
      return _handleDatabaseError(error);
    } else {
      return 'An unexpected error occurred';
    }
  }

  static String _handleAuthError(AuthException error) {
    switch (error.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password';
      case 'Email not confirmed':
        return 'Please verify your email first';
      default:
        return error.message;
    }
  }

  static String _handleDatabaseError(PostgrestException error) {
    if (error.code == '23505') {
      return 'This record already exists';
    }
    return 'Database error: ${error.message}';
  }
}
```

## State Management with Provider

```dart
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isAdmin = false;

  AuthProvider(this._authService) {
    _init();
  }

  void _init() {
    _user = _authService.currentUser;
    _isAdmin = _authService.isAdmin;
    _authService.authStateChanges.listen((state) {
      _user = state.session?.user;
      _isAdmin = _authService.isAdmin;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAdmin => _isAdmin;
  bool get isAuthenticated => _user != null;
}
```

## Usage in Widgets

```dart
class MedicationScreen extends StatelessWidget {
  final MedicationService _medicationService = MedicationService();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        return FutureBuilder<List<Medication>>(
          future: _medicationService.getMedications(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(SupabaseErrorHandler.handleError(snapshot.error));
            }

            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final medication = snapshot.data![index];
                return MedicationCard(
                  medication: medication,
                  onTaken: () => _medicationService.logMedicationTaken(medication.id),
                  onSkipped: () => _medicationService.logMedicationSkipped(medication.id),
                );
              },
            );
          },
        );
      },
    );
  }
}
``` 