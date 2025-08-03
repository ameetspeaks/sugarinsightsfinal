import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_package;
import 'package:timezone/data/latest.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/database_service.dart';
import 'core/config/supabase_config.dart';
import 'services/notification_service.dart';
import 'services/notification_action_handler.dart';
import 'services/background_service.dart';
import 'services/supabase_auth_service.dart';
import 'services/medication_service.dart';
import 'services/missed_medication_service.dart';
import 'services/medication_popup_service.dart';
import 'providers/app_state_provider.dart';
import 'providers/health_data_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/education_provider.dart';
import 'screens/onboarding/basic_details_screen.dart';
import 'screens/onboarding/height_weight_screen.dart';
import 'screens/onboarding/diabetes_status_screen.dart';
import 'screens/onboarding/diabetes_type_screen.dart';
import 'screens/onboarding/diagnosis_timeline_screen.dart';
import 'screens/onboarding/unique_id_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/education/education_screen.dart';
import 'screens/education/medical_nutrition_therapy_screen.dart';
import 'screens/education/blog_post_detail_screen.dart';
import 'screens/education/video_player_screen.dart';
import 'screens/education/article_view_screen.dart';
import 'screens/diet/diet_screen.dart';
import 'screens/medications/medications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/profile_details_screen.dart';
import 'screens/health/log_blood_pressure_screen.dart';
import 'screens/health/log_medication_screen.dart';
import 'screens/splash/simple_splash_screen.dart';
import 'screens/splash/welcome_splash_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'core/enums/dashboard_enums.dart';
import 'widgets/dashboard/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data first
  tz.initializeTimeZones();

  // Initialize Firebase (temporarily disabled due to missing config)
  // await Firebase.initializeApp();

  // Initialize Supabase
  print('Initializing Supabase with:');
  print('URL: ${SupabaseConfig.url}');
  print('Anon Key: ${SupabaseConfig.anonKey.substring(0, 20)}...');
  print('Full URL check: ${SupabaseConfig.url == 'YOUR_SUPABASE_URL' ? 'ERROR: Still using placeholder' : 'OK: Using actual URL'}');
  print('Full Anon Key check: ${SupabaseConfig.anonKey.contains('YOUR_SUPABASE') ? 'ERROR: Still using placeholder' : 'OK: Using actual key'}');
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    debug: true, // Enable debug mode to see what's happening
  );

  // Initialize services
  await DatabaseService().database; // Initialize database
  await NotificationService().init();
  await NotificationActionHandler().initialize();
  await BackgroundService().initialize();
  await MedicationPopupService().initialize();
  
  // Request all necessary permissions for medication alarms
  try {
    print('✅ All permissions requested successfully');
  } catch (e) {
    print('⚠️ Warning: Failed to request all permissions: $e');
  }
  
  // Initialize medication notification system
  try {
      final medicationService = MedicationService.create(Supabase.instance.client);
  await medicationService.initialize();
    print('✅ Medication notification system initialized successfully');
  } catch (e) {
    print('⚠️ Warning: Failed to initialize medication notification system: $e');
  }
  
  // Initialize Supabase auth service and session
  await SupabaseAuthService.instance.initializeSession();

  runApp(
    provider_package.MultiProvider(
      providers: [
        provider_package.ChangeNotifierProvider(create: (_) => SupabaseAuthService.instance),
        provider_package.ChangeNotifierProvider(create: (_) => AppStateProvider()),
        provider_package.ChangeNotifierProvider(create: (_) => HealthDataProvider()),
        provider_package.ChangeNotifierProvider(create: (_) => NavigationProvider()),
        provider_package.ChangeNotifierProvider(create: (_) => SettingsProvider()),
        provider_package.ChangeNotifierProvider(create: (_) => EducationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a global navigator key for popup dialogs
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    
    // Set the navigator key for the popup service
    MedicationPopupService.setNavigatorKey(navigatorKey);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Sugar Insights',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: provider_package.Consumer<SupabaseAuthService>(
        builder: (context, authService, child) {
          // Check if user has a current user
          final hasUser = authService.currentUser != null;
          final hasCompletedOnboarding = authService.hasCompletedOnboarding;
          
          if (hasUser) {
            // Check if onboarding is completed
            if (!hasCompletedOnboarding) {
              print('🔄 User exists but onboarding incomplete, redirecting to onboarding');
              // Redirect to onboarding if not completed
              return const BasicDetailsScreen();
            } else {
              print('✅ User exists and onboarding completed, showing main screen');
              // Show main screen if onboarding is completed
              return const MainScreen();
            }
          } else {
            // Only show splash screen if no user at all
            print('👤 No user found, showing splash screen');
            return const SimpleSplashScreen();
          }
        },
      ),
      routes: {
        '/welcome-splash': (context) => const WelcomeSplashScreen(),
        '/sign-in': (context) => const SignInScreen(),
        '/sign-up': (context) => const SignUpScreen(),
        '/otp-verification': (context) => const OtpVerificationScreen(),
        '/main': (context) => const MainScreen(),
        '/onboarding': (context) => const BasicDetailsScreen(),
        '/basic-details': (context) => const BasicDetailsScreen(),
        '/height-weight': (context) => const HeightWeightScreen(),
        '/diabetes-status': (context) => const DiabetesStatusScreen(),
        '/diabetes-type': (context) => const DiabetesTypeScreen(),
        '/diagnosis-timeline': (context) => const DiagnosisTimelineScreen(),
        '/unique-id': (context) => const UniqueIdScreen(),
        '/profile-details': (context) => const ProfileDetailsScreen(),
        '/log-medication': (context) => const LogMedicationScreen(),
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

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
    final appStateProvider = provider_package.Provider.of<AppStateProvider>(context, listen: false);
    final healthDataProvider = provider_package.Provider.of<HealthDataProvider>(context, listen: false);
    final settingsProvider = provider_package.Provider.of<SettingsProvider>(context, listen: false);

    // Initialize all providers
    await Future.wait<void>([
      appStateProvider.initialize(),
      healthDataProvider.initialize(),
      settingsProvider.initialize(),
    ]);

    // Notify listeners after initialization is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appStateProvider.notifyListeners();
      healthDataProvider.notifyListeners();
      settingsProvider.notifyListeners();
    });

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const SimpleSplashScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Map<NavItem, Widget> _screens = {
    NavItem.home: const DashboardScreen(),
    NavItem.medicine: const MedicationsScreen(),
    NavItem.diet: const DietScreen(),
    NavItem.education: const EducationScreen(),
    NavItem.profile: const ProfileScreen(),
  };

  @override
  void initState() {
    super.initState();
    // Check for missed medications when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMissedMedications();
    });
  }

  Future<void> _checkMissedMedications() async {
    try {
      final missedMedicationService = MissedMedicationService();
      await missedMedicationService.checkMissedMedicationsOnAppResume(context);
    } catch (e) {
      print('❌ Error checking missed medications on app start: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return provider_package.Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          body: _screens[navigationProvider.selectedNavItem]!,
          bottomNavigationBar: BottomNavBar(
            selectedItem: navigationProvider.selectedNavItem,
            onItemSelected: navigationProvider.setSelectedNavItem,
          ),
        );
      },
    );
  }
} 