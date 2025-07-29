import 'package:supabase_flutter/supabase_flutter.dart';

class GlucoseService {
  static final GlucoseService _instance = GlucoseService._internal();
  factory GlucoseService() => _instance;
  GlucoseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ===========================================
  // CRUD Operations
  // ===========================================

  /// Add a new glucose reading
  Future<Map<String, dynamic>> addGlucoseReading({
    required String readingType,
    required int glucoseValue,
    required String unit,
    String? mealContext,
    String? notes,
    DateTime? readingDate,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final data = {
        'user_id': currentUser.id,
        'reading_type': readingType,
        'glucose_value': glucoseValue,
        'unit': unit,
        'meal_context': mealContext,
        'notes': notes,
        'reading_date': readingDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

      print('🔄 Adding glucose reading: $data');
      
      final response = await _client
          .from('glucose_readings')
          .insert(data)
          .select()
          .single();

      print('✅ Glucose reading added successfully: ${response['id']}');
      return response;
    } catch (e) {
      print('❌ Error adding glucose reading: $e');
      rethrow;
    }
  }

  /// Get all glucose readings for the current user
  Future<List<Map<String, dynamic>>> getGlucoseReadings({
    int? limit,
    String? readingType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Build the entire query in one chain
      var query = _client
          .from('glucose_readings')
          .select()
          .eq('user_id', currentUser.id);

      if (readingType != null) {
        query = query.eq('reading_type', readingType);
      }

      if (startDate != null) {
        query = query.gte('reading_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('reading_date', endDate.toIso8601String());
      }

      // Execute the query first, then apply order and limit
      var response = await query;
      
      // Convert to list and sort by date
      var readings = List<Map<String, dynamic>>.from(response);
      readings.sort((a, b) => DateTime.parse(b['reading_date']).compareTo(DateTime.parse(a['reading_date'])));
      
      // Apply limit if specified
      if (limit != null && readings.length > limit) {
        readings = readings.take(limit).toList();
      }

      print('✅ Retrieved ${readings.length} glucose readings');
      return readings;
    } catch (e) {
      print('❌ Error getting glucose readings: $e');
      rethrow;
    }
  }

  /// Get latest glucose readings for the current user
  Future<Map<String, dynamic>?> getLatestGlucoseReadings() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get all glucose readings for the user
      final allReadings = await _client
          .from('glucose_readings')
          .select()
          .eq('user_id', currentUser.id);

      // Convert to list and sort by date
      var readings = List<Map<String, dynamic>>.from(allReadings);
      readings.sort((a, b) => DateTime.parse(b['reading_date']).compareTo(DateTime.parse(a['reading_date'])));

      // Find latest fasting and post-meal readings
      Map<String, dynamic>? latestFasting;
      Map<String, dynamic>? latestPostMeal;

      for (var reading in readings) {
        if (reading['reading_type'] == 'fasting' && latestFasting == null) {
          latestFasting = reading;
        } else if (reading['reading_type'] == 'post_meal' && latestPostMeal == null) {
          latestPostMeal = reading;
        }

        // Break if we found both
        if (latestFasting != null && latestPostMeal != null) {
          break;
        }
      }

      final result = {
        'fasting': latestFasting,
        'post_meal': latestPostMeal,
      };

      print('✅ Retrieved latest glucose readings');
      return result;
    } catch (e) {
      print('❌ Error getting latest glucose readings: $e');
      rethrow;
    }
  }

  /// Update a glucose reading
  Future<Map<String, dynamic>> updateGlucoseReading({
    required String id,
    String? readingType,
    int? glucoseValue,
    String? unit,
    String? mealContext,
    String? notes,
    DateTime? readingDate,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final data = <String, dynamic>{};
      if (readingType != null) data['reading_type'] = readingType;
      if (glucoseValue != null) data['glucose_value'] = glucoseValue;
      if (unit != null) data['unit'] = unit;
      if (mealContext != null) data['meal_context'] = mealContext;
      if (notes != null) data['notes'] = notes;
      if (readingDate != null) data['reading_date'] = readingDate.toIso8601String();

      print('🔄 Updating glucose reading $id: $data');

      final response = await _client
          .from('glucose_readings')
          .update(data)
          .eq('id', id)
          .eq('user_id', currentUser.id)
          .select()
          .single();

      print('✅ Glucose reading updated successfully');
      return response;
    } catch (e) {
      print('❌ Error updating glucose reading: $e');
      rethrow;
    }
  }

  /// Delete a glucose reading
  Future<void> deleteGlucoseReading(String id) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('🔄 Deleting glucose reading: $id');

      await _client
          .from('glucose_readings')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUser.id);

      print('✅ Glucose reading deleted successfully');
    } catch (e) {
      print('❌ Error deleting glucose reading: $e');
      rethrow;
    }
  }

  // ===========================================
  // Analytics and Statistics
  // ===========================================

  /// Get glucose statistics for a time period
  Future<Map<String, dynamic>> getGlucoseStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? readingType,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      var query = _client
          .from('glucose_readings')
          .select('glucose_value, reading_type')
          .eq('user_id', currentUser.id);

      if (readingType != null) {
        query = query.eq('reading_type', readingType);
      }

      if (startDate != null) {
        query = query.gte('reading_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('reading_date', endDate.toIso8601String());
      }

      final response = await query;
      final readings = List<Map<String, dynamic>>.from(response);

      if (readings.isEmpty) {
        return {
          'average': 0,
          'min': 0,
          'max': 0,
          'count': 0,
        };
      }

      final values = readings.map((r) => r['glucose_value'] as int).toList();
      final average = values.reduce((a, b) => a + b) / values.length;
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);

      final result = {
        'average': average.round(),
        'min': min,
        'max': max,
        'count': readings.length,
      };

      print('✅ Retrieved glucose statistics: $result');
      return result;
    } catch (e) {
      print('❌ Error getting glucose statistics: $e');
      rethrow;
    }
  }

  // ===========================================
  // Utility Methods
  // ===========================================

  /// Get available reading types
  List<String> getReadingTypes() {
    return ['fasting', 'post_meal', 'random', 'before_meal', 'after_meal'];
  }

  /// Get available units
  List<String> getUnits() {
    return ['mg/dL', 'mmol/L'];
  }

  /// Get available meal contexts
  List<String> getMealContexts() {
    return ['breakfast', 'lunch', 'dinner', 'snack'];
  }

  /// Convert glucose value between units
  double convertGlucoseValue(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;
    
    if (fromUnit == 'mg/dL' && toUnit == 'mmol/L') {
      return value / 18.0;
    } else if (fromUnit == 'mmol/L' && toUnit == 'mg/dL') {
      return value * 18.0;
    }
    
    return value;
  }
} 