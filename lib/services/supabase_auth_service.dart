import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Added for Timer

class SupabaseAuthService extends ChangeNotifier {
  static SupabaseAuthService? _instance;
  late final SupabaseClient _client;
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _hasCompletedOnboarding = false;
  bool _isLoading = false;

  // Singleton pattern
  static SupabaseAuthService get instance {
    _instance ??= SupabaseAuthService._();
    return _instance!;
  }

  SupabaseAuthService._() {
    _client = Supabase.instance.client;
    _initialize();
  }

  // Getters
  SupabaseClient get client => _client;
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isLoading => _isLoading;

  void _initialize() async {
    print('Initializing Supabase auth service...');
    
    // Test connection
    try {
      await _client.from('user_profiles').select('count').limit(1);
      print('Supabase connection test successful');
    } catch (e) {
      print('❌ Supabase connection test failed: $e');
    }

    // Start periodic session validation
    _startSessionValidationTimer();

    // Listen to auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      print('**** onAuthStateChange: ${data.event}');
      if (data.event == AuthChangeEvent.signedIn) {
        _currentUser = data.session?.user;
        if (_currentUser != null) {
          print('👤 User signed in: ${_currentUser!.id}');
          // Only load profile if we have a valid session
          if (data.session != null) {
            _loadUserProfile().then((_) {
              // Check onboarding completion after loading profile
              checkOnboardingCompletion();
            });
          }
        }
      } else if (data.event == AuthChangeEvent.signedOut) {
        print('👤 User signed out');
        // Clear all state immediately
        _currentUser = null;
        _userProfile = null;
        _hasCompletedOnboarding = false;
        notifyListeners();
      } else if (data.event == AuthChangeEvent.tokenRefreshed) {
        print('🔄 Token refreshed');
        _currentUser = data.session?.user;
        if (_currentUser != null && data.session != null) {
          _loadUserProfile().then((_) {
            // Check onboarding completion after loading profile
            checkOnboardingCompletion();
          });
        }
      } else if (data.event == AuthChangeEvent.userUpdated) {
        print('👤 User updated');
        _currentUser = data.session?.user;
        if (_currentUser != null && data.session != null) {
          _loadUserProfile().then((_) {
            // Check onboarding completion after loading profile
            checkOnboardingCompletion();
          });
        }
      } else if (data.event == AuthChangeEvent.mfaChallengeVerified) {
        print('🔐 MFA challenge verified');
        // Handle MFA if needed
      } else if (data.event == AuthChangeEvent.passwordRecovery) {
        print('🔐 Password recovery');
        // Handle password recovery if needed
      }
    });
  }

  // Load user profile from simplified schema
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) {
      print('⚠️ No current user found, cannot load profile');
      return;
    }

    try {
      print('🔄 Loading user profile for user ID: ${_currentUser!.id}');
      
      // Get user profile from user_profiles table
      final response = await _client
          .from('user_profiles')
          .select('*')
          .eq('user_id', _currentUser!.id)
          .limit(1);

      if (response.isNotEmpty) {
        final profile = response.first;
        
        // Map email from auth.users table (current user)
        final updatedProfile = {
          ...profile,
          'email': _currentUser!.email, // Always use email from auth.users
        };
        
        print('✅ User profile loaded successfully: $updatedProfile');
        
        _userProfile = Map<String, dynamic>.from(updatedProfile);
        _hasCompletedOnboarding = updatedProfile['onboarding_completed'] ?? false;
        
        print('👤 Current user set: ${_currentUser?.id}');
        print('📧 Email mapped from auth.users: ${_currentUser!.email}');
        print('📊 Onboarding completed: $_hasCompletedOnboarding');
        
        notifyListeners();
      } else {
        // No profile found - don't automatically create one
        // Only create profile when explicitly requested (e.g., after OTP verification)
        print('⚠️ No user profile found for user ID: ${_currentUser!.id}');
        print('ℹ️ Profile will be created when user completes signup process');
        
        // Set basic state without profile but with email from auth
        _userProfile = Map<String, dynamic>.from({
          'user_id': _currentUser!.id,
          'email': _currentUser!.email,
          'onboarding_completed': false,
        });
        _hasCompletedOnboarding = false;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
      
      // Check if this is an authentication error
      if (e.toString().contains('JWT') || e.toString().contains('unauthorized')) {
        print('🔐 Authentication error, user may not be properly authenticated');
        _currentUser = null;
        _userProfile = null;
        _hasCompletedOnboarding = false;
        notifyListeners();
        return;
      }
      
      // Don't automatically try to create profile on error
      print('⚠️ Not attempting to create profile due to error');
      _userProfile = null;
      _hasCompletedOnboarding = false;
      notifyListeners();
    }
  }

  // Check if user exists in auth.users table
  Future<bool> _userExistsInAuth(String userId) async {
    try {
      // First check if we have a valid session
      final session = _client.auth.currentSession;
      if (session == null) {
        print('❌ No active session found');
        return false;
      }
      
      // Check if the session user ID matches the requested user ID
      if (session.user?.id != userId) {
        print('❌ Session user ID (${session.user?.id}) does not match requested user ID ($userId)');
        return false;
      }
      
      // Try to access a protected resource to verify the user exists
      final testResponse = await _client
          .from('user_profiles')
          .select('id')
          .eq('user_id', userId)
          .limit(1);
      
      print('✅ User exists in auth and can access protected resources');
      return true;
    } catch (e) {
      print('❌ Error checking if user exists in auth: $e');
      return false;
    }
  }

  // Check if user profile exists
  Future<bool> _userProfileExists(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('id')
          .eq('user_id', userId)
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('❌ Error checking if user profile exists: $e');
      return false;
    }
  }

  // Create initial user profile with retry mechanism
  Future<void> createInitialUserProfile(String userId) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        // Check if profile already exists
        final exists = await _userProfileExists(userId);
        if (exists) {
          print('⚠️ User profile already exists for user ID: $userId');
          return;
        }
        
        // Check if user exists in auth.users before creating profile
        final userExists = await _userExistsInAuth(userId);
        if (!userExists) {
          print('❌ User does not exist in auth.users table: $userId');
          print('⚠️ Cannot create profile for non-existent user');
          return;
        }
        
        print('🔄 Creating initial user profile for user ID: $userId (attempt ${retryCount + 1})');
        
        final profileData = {
          'user_id': userId,
          'email': _currentUser?.email ?? '', // Get email from auth.users
          'onboarding_completed': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        print('📧 Creating profile with email: ${_currentUser?.email}');
        await _client.from('user_profiles').insert(profileData);
        
        print('✅ Initial user profile created successfully');
        print('📧 Email mapped from auth.users: ${_currentUser?.email}');
        
        // Set the profile data directly instead of reloading
        _userProfile = Map<String, dynamic>.from(profileData);
        _hasCompletedOnboarding = false;
        
        print('👤 Current user set: ${_currentUser?.id}');
        print('📊 Onboarding completed: $_hasCompletedOnboarding');
        
        notifyListeners();
        return; // Success, exit retry loop
      } catch (e) {
        retryCount++;
        print('❌ Error creating initial user profile (attempt $retryCount): $e');
        
        if (retryCount < maxRetries) {
          final delay = Duration(seconds: retryCount * 2); // Exponential backoff: 2s, 4s, 6s
          print('⏳ Retrying in ${delay.inSeconds} seconds...');
          await Future.delayed(delay);
        } else {
          print('❌ Failed to create user profile after $maxRetries attempts');
          print('⚠️ User may not exist in auth.users table. This is normal for new signups.');
        }
      }
    }
  }

  // Sign up with email
  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      
      // Don't create profile here - wait for OTP verification
      // Profile will be created in OTP verification screen
      
      return response;
    } catch (e) {
      print('❌ Sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _currentUser = response.user;
        await _loadUserProfile();
      }
      
      return response;
    } catch (e) {
      print('❌ Sign in error: $e');
      rethrow;
    }
  }

  // Sign out with proper cleanup
  Future<void> signOut() async {
    try {
      print('🔄 Signing out user...');
      
      // Clear local state first
      _currentUser = null;
      _userProfile = null;
      _hasCompletedOnboarding = false;
      notifyListeners();
      
      // Sign out from Supabase
      await _client.auth.signOut();
      
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error during sign out: $e');
      // Even if there's an error, clear local state
      _currentUser = null;
      _userProfile = null;
      _hasCompletedOnboarding = false;
      notifyListeners();
    }
  }

  // Check if email exists (simplified)
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('email')
          .eq('email', email)
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('❌ Error checking email existence: $e');
      return false;
    }
  }

  // Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) {
      print('❌ No current user found for profile update');
      return;
    }

    try {
      print('🔄 Updating user profile for user ID: ${_currentUser!.id}');
      print('📊 Update data: $data');
      
      // Always include email from auth.users if not already in data
      Map<String, dynamic> updateData = Map<String, dynamic>.from(data);
      if (!updateData.containsKey('email') && _currentUser!.email != null) {
        updateData['email'] = _currentUser!.email;
        print('📧 Adding email from auth.users: ${_currentUser!.email}');
      }
      
      await _client
          .from('user_profiles')
          .update(updateData)
          .eq('user_id', _currentUser!.id);
      
      print('✅ User profile updated successfully');
      
      // Reload profile
      await _loadUserProfile();
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  // Update onboarding progress (simplified)
  Future<void> updateOnboardingProgress(String stepName, bool completed, Map<String, dynamic> data) async {
    // Check if we have a current user (less strict than session validation)
    if (_currentUser == null) {
      print('❌ No current user found for onboarding progress update');
      return;
    }

    // Check session validity but don't clear state immediately
    if (!isSessionValidSync()) {
      print('⚠️ Session may be invalid, but continuing with onboarding update');
      print('🔐 Current user: ${_currentUser?.id}');
      print('🔐 Session valid: ${isSessionValidSync()}');
    }

    try {
      print('🔄 Starting updateOnboardingProgress for step: $stepName');
      print('👤 Current user ID: ${_currentUser!.id}');
      print('✅ Completed: $completed');
      print('📊 Data: $data');
      
      // Update the user profile with onboarding data
      Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
        ...data,
      };
      
      // Always include email from auth.users if not already in data
      if (!updateData.containsKey('email') && _currentUser!.email != null) {
        updateData['email'] = _currentUser!.email;
        print('📧 Adding email from auth.users: ${_currentUser!.email}');
      }
      
      // If this is the final step, mark onboarding as completed
      if (stepName == 'unique_id') {
        updateData['onboarding_completed'] = true;
        _hasCompletedOnboarding = true;
        print('🎉 Onboarding completed! Setting _hasCompletedOnboarding = true');
      }
      
      print('💾 Updating profile with data: $updateData');
      await _client
          .from('user_profiles')
          .update(updateData)
          .eq('user_id', _currentUser!.id);
      
      print('✅ Successfully saved onboarding progress for step: $stepName');
      
      // Reload profile to get updated data
      await _loadUserProfile();
      
      // Notify listeners about the change
      notifyListeners();
    } catch (e) {
      print('❌ Error updating onboarding progress: $e');
      print('❌ Error details: ${e.toString()}');
      rethrow;
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding() async {
    if (_currentUser == null) return;

    try {
      await _client
          .from('user_profiles')
          .update({
            'onboarding_completed': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _currentUser!.id);
      
      _hasCompletedOnboarding = true;
      notifyListeners();
    } catch (e) {
      print('❌ Error completing onboarding: $e');
      rethrow;
    }
  }

  // Get onboarding status
  bool getOnboardingStatus() {
    return _hasCompletedOnboarding;
  }

  // Get user profile data
  Map<String, dynamic>? getUserProfile() {
    return _userProfile;
  }

  // Initialize session on app start
  Future<void> initializeSession() async {
    try {
      print('🔄 Initializing session...');
      
      final session = _client.auth.currentSession;
      if (session != null) {
        print('👤 Found existing session for user: ${session.user?.id}');
        
        // Check if session is valid
        final isValid = await isSessionValid();
        if (isValid) {
          print('✅ Session is valid, loading user profile');
          _currentUser = session.user;
          await _loadUserProfile();
          
          // Check onboarding completion after loading profile
          checkOnboardingCompletion();
        } else {
          print('🔐 Session has expired');
          print('❌ Session is invalid, clearing state');
          _currentUser = null;
          _userProfile = null;
          _hasCompletedOnboarding = false;
          notifyListeners();
        }
      } else {
        print('🔐 No existing session found');
        _currentUser = null;
        _userProfile = null;
        _hasCompletedOnboarding = false;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error initializing session: $e');
      _currentUser = null;
      _userProfile = null;
      _hasCompletedOnboarding = false;
      notifyListeners();
    }
  }

  // Check current session status (synchronous)
  bool isSessionValidSync() {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        return false;
      }
      
      // Check if session is expired
      if (session.expiresAt != null) {
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt!);
        if (DateTime.now().isAfter(expiresAt)) {
          // Session is expired, but don't clear state here to avoid setState during build
          return false;
        }
      }
      
      // Additional check: ensure we have a user
      if (session.user == null) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check current session status (asynchronous)
  Future<bool> isSessionValid() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        print('🔐 No active session found');
        return false;
      }
      
      // Check if session is expired
      if (session.expiresAt != null) {
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt!);
        if (DateTime.now().isAfter(expiresAt)) {
          print('🔐 Session has expired');
          return false;
        }
      }
      
      print('✅ Session is valid');
      return true;
    } catch (e) {
      print('❌ Error checking session: $e');
      return false;
    }
  }

  // Start periodic session validation timer
  void _startSessionValidationTimer() {
    // Check session validity every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_currentUser != null && !isSessionValidSync()) {
        print('🔐 Periodic check: Session is invalid, forcing logout');
        forceLogout();
      }
    });
  }

  // Safely handle session cleanup without causing setState issues
  void handleInvalidSession() {
    if (_currentUser != null && !isSessionValidSync()) {
      print('🔐 Invalid session detected, clearing state safely');
      _currentUser = null;
      _userProfile = null;
      _hasCompletedOnboarding = false;
      // Use a microtask to avoid setState during build
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  // Force redirect to onboarding if incomplete
  void checkOnboardingCompletion() {
    if (_currentUser != null && !_hasCompletedOnboarding) {
      print('🔄 Onboarding incomplete for user: ${_currentUser!.id}');
      print('📊 Onboarding status: $_hasCompletedOnboarding');
      // The main.dart will handle the redirect based on this status
    }
  }

  // Force logout when session is invalid
  Future<void> forceLogout() async {
    print('🔐 Force logout - clearing all state');
    _currentUser = null;
    _userProfile = null;
    _hasCompletedOnboarding = false;
    notifyListeners();
    
    try {
      await _client.auth.signOut();
      print('✅ Force logout completed');
    } catch (e) {
      print('❌ Error during force logout: $e');
      // State is already cleared, so we're good
    }
  }

  // Handle session expiration and force logout
  void handleSessionExpiration() {
    print('🔐 Session expired, forcing logout');
    _currentUser = null;
    _userProfile = null;
    _hasCompletedOnboarding = false;
    // Use a microtask to avoid setState during build
    Future.microtask(() {
      notifyListeners();
    });
  }
} 