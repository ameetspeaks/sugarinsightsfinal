import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/glucose_reading.dart';

class ApiService {
  static const String baseUrl = 'https://api.sugarinsights.com/v1';
  static const Duration timeout = Duration(seconds: 30);

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;

  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  // Get headers for requests
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // Generic GET request
  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('GET request failed: $e');
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('POST request failed: $e');
    }
  }

  // Generic PUT request
  Future<Map<String, dynamic>> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('PUT request failed: $e');
    }
  }

  // Generic DELETE request
  Future<Map<String, dynamic>> _delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('DELETE request failed: $e');
    }
  }

  // Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException(
        'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _post('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    return await _post('/auth/register', userData);
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return await _post('/auth/refresh', {
      'refreshToken': refreshToken,
    });
  }

  Future<void> logout() async {
    await _post('/auth/logout', {});
    clearAuthToken();
  }

  // User methods
  Future<User> getCurrentUser() async {
    final response = await _get('/user/profile');
    return User.fromJson(response['data']);
  }

  Future<User> updateUser(Map<String, dynamic> userData) async {
    final response = await _put('/user/profile', userData);
    return User.fromJson(response['data']);
  }

  Future<void> deleteUser() async {
    await _delete('/user/profile');
  }

  // Glucose reading methods
  Future<List<GlucoseReading>> getGlucoseReadings({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, String>{};
    
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }
    if (offset != null) {
      queryParams['offset'] = offset.toString();
    }

    final queryString = queryParams.isNotEmpty 
        ? '?${Uri(queryParameters: queryParams).query}'
        : '';

    final response = await _get('/glucose-readings$queryString');
    final List<dynamic> data = response['data'];
    return data.map((json) => GlucoseReading.fromJson(json)).toList();
  }

  Future<GlucoseReading> createGlucoseReading(Map<String, dynamic> readingData) async {
    final response = await _post('/glucose-readings', readingData);
    return GlucoseReading.fromJson(response['data']);
  }

  Future<GlucoseReading> updateGlucoseReading(String id, Map<String, dynamic> readingData) async {
    final response = await _put('/glucose-readings/$id', readingData);
    return GlucoseReading.fromJson(response['data']);
  }

  Future<void> deleteGlucoseReading(String id) async {
    await _delete('/glucose-readings/$id');
  }

  // Analytics methods
  Future<Map<String, dynamic>> getGlucoseAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final queryString = queryParams.isNotEmpty 
        ? '?${Uri(queryParameters: queryParams).query}'
        : '';

    return await _get('/analytics/glucose$queryString');
  }

  // Health insights methods
  Future<Map<String, dynamic>> getHealthInsights() async {
    return await _get('/insights/health');
  }

  // Notifications methods
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _get('/notifications');
    return List<Map<String, dynamic>>.from(response['data']);
  }

  Future<void> markNotificationAsRead(String id) async {
    await _put('/notifications/$id/read', {});
  }

  // Settings methods
  Future<Map<String, dynamic>> getUserSettings() async {
    return await _get('/user/settings');
  }

  Future<Map<String, dynamic>> updateUserSettings(Map<String, dynamic> settings) async {
    return await _put('/user/settings', settings);
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
} 