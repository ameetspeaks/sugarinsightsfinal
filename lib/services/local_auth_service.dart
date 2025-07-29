import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'database_service.dart';

class LocalAuthService extends ChangeNotifier {
  static final LocalAuthService _instance = LocalAuthService._internal();
  factory LocalAuthService() => _instance;
  LocalAuthService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  User? _currentUser;
  String? _currentToken;
  bool _isAuthenticated = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // Initialize the auth service
  Future<void> initialize() async {
    // Check for existing session token
    _currentToken = await _secureStorage.read(key: 'auth_token');
    if (_currentToken != null) {
      final userId = await _databaseService.getUserIdFromToken(_currentToken!);
      if (userId != null) {
        _currentUser = await _databaseService.getUserById(userId);
        _isAuthenticated = _currentUser != null;
        notifyListeners();
      } else {
        // Token is invalid, clear it
        await _secureStorage.delete(key: 'auth_token');
        _currentToken = null;
      }
    }
  }

  // Sign up with email and password
  Future<User> signUpWithEmail({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    // Check if email already exists
    final emailExists = await _databaseService.emailExists(email);
    if (emailExists) {
      throw Exception('Email already exists');
    }

    // Create user
    final user = await _databaseService.createUser(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );

    // Create session
    final token = await _databaseService.createSession(user.id);
    await _secureStorage.write(key: 'auth_token', value: token);

    _currentUser = user;
    _currentToken = token;
    _isAuthenticated = true;
    notifyListeners();

    return user;
  }

  // Sign in with email and password
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _databaseService.authenticateUser(email, password);
    if (user == null) {
      throw Exception('Invalid email or password');
    }

    // Create new session
    final token = await _databaseService.createSession(user.id);
    await _secureStorage.write(key: 'auth_token', value: token);

    _currentUser = user;
    _currentToken = token;
    _isAuthenticated = true;
    notifyListeners();

    return user;
  }

  // Sign out
  Future<void> signOut() async {
    if (_currentToken != null) {
      await _databaseService.deleteSession(_currentToken!);
    }
    await _secureStorage.delete(key: 'auth_token');

    _currentUser = null;
    _currentToken = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser != null) {
      await _databaseService.updateUser(_currentUser!.id, data);
      
      // Reload user data
      _currentUser = await _databaseService.getUserById(_currentUser!.id);
      notifyListeners();
    }
  }

  // Get onboarding progress
  Future<Map<String, bool>> getOnboardingProgress() async {
    if (_currentUser != null) {
      return await _databaseService.getOnboardingProgress(_currentUser!.id);
    }
    return {};
  }

  // Update onboarding progress
  Future<void> updateOnboardingProgress(String step, bool completed) async {
    if (_currentUser != null) {
      await _databaseService.updateOnboardingProgress(_currentUser!.id, step, completed);
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding() async {
    if (_currentUser != null) {
      await _databaseService.completeOnboarding(_currentUser!.id);
    }
  }

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    return await _databaseService.emailExists(email);
  }

  // Get current session token
  String? getCurrentToken() {
    return _currentToken;
  }

  // Refresh session (extend token validity)
  Future<void> refreshSession() async {
    if (_currentUser != null && _currentToken != null) {
      // Delete old session
      await _databaseService.deleteSession(_currentToken!);
      
      // Create new session
      final newToken = await _databaseService.createSession(_currentUser!.id);
      await _secureStorage.write(key: 'auth_token', value: newToken);
      
      _currentToken = newToken;
    }
  }
} 