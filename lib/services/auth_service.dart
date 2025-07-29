import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  // Initialize the auth service
  Future<void> initialize() async {
    // Check for existing session
    final session = _supabaseService.client.auth.currentSession;
    if (session != null) {
      await _loadUserProfile(session.user.id);
    }

    // Listen for auth state changes
    _supabaseService.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session != null) {
            _loadUserProfile(session.user.id);
          }
          break;
        case AuthChangeEvent.signedOut:
          _currentUser = null;
          notifyListeners();
          break;
        case AuthChangeEvent.tokenRefreshed:
          // Handle token refresh if needed
          break;
        case AuthChangeEvent.userUpdated:
          if (session != null) {
            _loadUserProfile(session.user.id);
          }
          break;
        default:
          break;
      }
    });
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      final response = await _supabaseService.signUpWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null && userData != null) {
        // Create user profile
        await _supabaseService.createProfile(
          userId: response.user!.id,
          data: userData,
        );

        // Load user profile
        await _loadUserProfile(response.user!.id);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseService.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.sugarinsights://reset-callback/',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabaseService.client.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      if (_currentUser != null) {
        await _supabaseService.updateProfile(
          userId: _currentUser!.id,
          data: data,
        );
        await _loadUserProfile(_currentUser!.id);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Load user profile
  Future<void> _loadUserProfile(String userId) async {
    try {
      final profileData = await _supabaseService.getProfile(userId);
      if (profileData != null) {
        _currentUser = User.fromJson({
          'id': userId,
          ...profileData,
        });
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Store auth token
  Future<void> _storeAuthToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  // Get stored auth token
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  // Delete stored auth token
  Future<void> _deleteAuthToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _supabaseService.client.rpc(
        'check_email_exists',
        params: {'email_address': email},
      );
      return response as bool;
    } catch (e) {
      return false;
    }
  }

  // Get current session
  Session? getCurrentSession() {
    return _supabaseService.client.auth.currentSession;
  }

  // Refresh session
  Future<void> refreshSession() async {
    try {
      await _supabaseService.client.auth.refreshSession();
    } catch (e) {
      rethrow;
    }
  }
} 