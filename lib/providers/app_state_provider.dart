import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/local_storage_service.dart';
import '../services/local_auth_service.dart';

class AppStateProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isOnboardingComplete = false;
  String? _uniqueId;
  bool _isLoading = false;
  LocalStorageService? _storageService;
  LocalAuthService? _authService;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isOnboardingComplete => _isOnboardingComplete;
  String? get uniqueId => _uniqueId;
  bool get isLoading => _isLoading;

  // Initialize app state from local storage
  Future<void> initialize() async {
    _isLoading = true;
    _storageService = await LocalStorageService.getInstance();
    _authService = LocalAuthService();
    await _loadStoredData();
    _isLoading = false;
  }

  Future<void> _loadStoredData() async {
    if (_storageService != null) {
      // Check if user is authenticated via AuthService
      if (_authService != null && _authService!.isAuthenticated) {
        _currentUser = _authService!.currentUser;
        _isAuthenticated = true;
      } else {
        // Load user data from local storage as fallback
        final storedUser = await _storageService!.getUser();
        if (storedUser != null) {
          _currentUser = storedUser;
          _isAuthenticated = true;
        }
      }

      // Load onboarding status
      _isOnboardingComplete = await _storageService!.isOnboardingComplete();

      // Load unique ID
      _uniqueId = await _storageService!.getUniqueId();
    }
  }

  Future<void> _saveUserData() async {
    if (_storageService != null && _currentUser != null) {
      await _storageService!.saveUser(_currentUser!);
    }
  }

  Future<void> _saveOnboardingStatus() async {
    if (_storageService != null) {
      await _storageService!.setOnboardingComplete(_isOnboardingComplete);
    }
  }

  Future<void> _saveUniqueId() async {
    if (_storageService != null && _uniqueId != null) {
      await _storageService!.saveUniqueId(_uniqueId!);
    }
  }

  // Authentication methods
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    
    try {
      if (_authService != null) {
        await _authService!.signInWithEmail(
          email: email,
          password: password,
        );
        
        // Update local state
        _currentUser = _authService!.currentUser;
        _isAuthenticated = _authService!.isAuthenticated;
        
        // Save to local storage as backup
        if (_currentUser != null) {
          await _saveUserData();
          await _saveOnboardingStatus();
        }
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    
    try {
      if (_authService != null) {
        await _authService!.signUpWithEmail(
          email: email,
          password: password,
        );
        
        // User will be created after onboarding completion
        _isAuthenticated = false; // Will be true after OTP verification
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String otp) async {
    _setLoading(true);
    
    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 2));
    
    // OTP verified, user can proceed to onboarding
    _setLoading(false);
    notifyListeners();
  }

  void completeOnboarding(User user) {
    _currentUser = user;
    _isAuthenticated = true;
    _isOnboardingComplete = true;
    
    // Save to local storage
    _saveUserData();
    _saveOnboardingStatus();
    
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      if (_authService != null) {
        await _authService!.signOut();
      }
    } catch (e) {
      print('Error signing out: $e');
    }
    
    _currentUser = null;
    _isAuthenticated = false;
    _isOnboardingComplete = false;
    _uniqueId = null;
    
    // Clear local storage
    if (_storageService != null) {
      await _storageService!.deleteUser();
      await _storageService!.setOnboardingComplete(false);
      await _storageService!.saveUniqueId('');
    }
    
    notifyListeners();
  }

  void setUniqueId(String uniqueId) {
    _uniqueId = uniqueId;
    _saveUniqueId();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // User data update methods
  Future<void> updateUserProfile({
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? bloodType,
    List<String>? allergies,
    List<String>? medications,
    Map<String, dynamic>? preferences,
  }) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        height: height,
        weight: weight,
        uniqueId: _currentUser!.uniqueId,
      );
      
      // Save to local storage
      await _saveUserData();
      notifyListeners();
    }
  }

  // Check if user has completed onboarding
  bool get hasCompletedOnboarding {
    return _isAuthenticated && _isOnboardingComplete && _currentUser != null;
  }

  // Check if user exists in local storage
  Future<bool> hasStoredUser() async {
    if (_storageService != null) {
      return await _storageService!.getUser() != null;
    }
    return false;
  }

  // Clear all user data
  Future<void> clearAllUserData() async {
    if (_storageService != null) {
      await _storageService!.clearAllData();
    }
    
    _currentUser = null;
    _isAuthenticated = false;
    _isOnboardingComplete = false;
    _uniqueId = null;
    
    notifyListeners();
  }

  // Export user data (for backup purposes)
  Map<String, dynamic>? exportUserData() {
    if (_currentUser != null) {
      return {
        'user': _currentUser!.toJson(),
        'isOnboardingComplete': _isOnboardingComplete,
        'uniqueId': _uniqueId,
        'exportedAt': DateTime.now().toIso8601String(),
      };
    }
    return null;
  }

  // Import user data (for restore purposes)
  Future<void> importUserData(Map<String, dynamic> data) async {
    if (data['user'] != null) {
      _currentUser = User.fromJson(data['user']);
      _isOnboardingComplete = data['isOnboardingComplete'] ?? false;
      _uniqueId = data['uniqueId'];
      _isAuthenticated = _currentUser != null;
      
      // Save to local storage
      await _saveUserData();
      await _saveOnboardingStatus();
      await _saveUniqueId();
      
      notifyListeners();
    }
  }
} 