import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class BloodPressureService {
  static final BloodPressureService _instance = BloodPressureService._internal();
  factory BloodPressureService() => _instance;
  BloodPressureService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ===========================================
  // CRUD Operations
  // ===========================================

  /// Add a new blood pressure reading
  Future<Map<String, dynamic>> addBloodPressureReading({
    required int systolic,
    required int diastolic,
    int? pulseRate,
    String? readingType,
    String? position,
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
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse_rate': pulseRate,
        'reading_type': readingType ?? 'manual',
        'position': position ?? 'sitting',
        'notes': notes,
        'reading_date': readingDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

      print('🔄 Adding blood pressure reading: $data');
      
      final response = await _client
          .from('blood_pressure_readings')
          .insert(data)
          .select()
          .single();

      print('✅ Blood pressure reading added successfully: ${response['id']}');
      return response;
    } catch (e) {
      print('❌ Error adding blood pressure reading: $e');
      rethrow;
    }
  }

  /// Get all blood pressure readings for the current user
  Future<List<Map<String, dynamic>>> getBloodPressureReadings({
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
          .from('blood_pressure_readings')
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

      print('✅ Retrieved ${readings.length} blood pressure readings');
      return readings;
    } catch (e) {
      print('❌ Error getting blood pressure readings: $e');
      rethrow;
    }
  }

  /// Get latest blood pressure reading for dashboard
  Future<Map<String, dynamic>?> getLatestBloodPressureReading() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get all blood pressure readings for the user
      final allReadings = await _client
          .from('blood_pressure_readings')
          .select()
          .eq('user_id', currentUser.id);

      // Convert to list and sort by date
      var readings = List<Map<String, dynamic>>.from(allReadings);
      readings.sort((a, b) => DateTime.parse(b['reading_date']).compareTo(DateTime.parse(a['reading_date'])));

      if (readings.isNotEmpty) {
        print('✅ Retrieved latest blood pressure reading');
        return readings.first;
      } else {
        print('ℹ️ No blood pressure readings found');
        return null;
      }
    } catch (e) {
      print('❌ Error getting latest blood pressure reading: $e');
      rethrow;
    }
  }

  /// Update a blood pressure reading
  Future<Map<String, dynamic>> updateBloodPressureReading({
    required String id,
    int? systolic,
    int? diastolic,
    int? pulseRate,
    String? readingType,
    String? position,
    String? notes,
    DateTime? readingDate,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final data = <String, dynamic>{};
      if (systolic != null) data['systolic'] = systolic;
      if (diastolic != null) data['diastolic'] = diastolic;
      if (pulseRate != null) data['pulse_rate'] = pulseRate;
      if (readingType != null) data['reading_type'] = readingType;
      if (position != null) data['position'] = position;
      if (notes != null) data['notes'] = notes;
      if (readingDate != null) data['reading_date'] = readingDate.toIso8601String();

      print('🔄 Updating blood pressure reading $id: $data');

      final response = await _client
          .from('blood_pressure_readings')
          .update(data)
          .eq('id', id)
          .eq('user_id', currentUser.id)
          .select()
          .single();

      print('✅ Blood pressure reading updated successfully');
      return response;
    } catch (e) {
      print('❌ Error updating blood pressure reading: $e');
      rethrow;
    }
  }

  /// Delete a blood pressure reading
  Future<void> deleteBloodPressureReading(String id) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('🔄 Deleting blood pressure reading: $id');

      await _client
          .from('blood_pressure_readings')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUser.id);

      print('✅ Blood pressure reading deleted successfully');
    } catch (e) {
      print('❌ Error deleting blood pressure reading: $e');
      rethrow;
    }
  }

  // ===========================================
  // Analytics and Statistics
  // ===========================================

  /// Get blood pressure statistics for a time period
  Future<Map<String, dynamic>> getBloodPressureStatistics({
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
          .from('blood_pressure_readings')
          .select('systolic, diastolic, pulse_rate, reading_type')
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
          'systolic_avg': 0,
          'diastolic_avg': 0,
          'pulse_avg': 0,
          'count': 0,
        };
      }

      final systolicValues = readings.map((r) => r['systolic'] as int).toList();
      final diastolicValues = readings.map((r) => r['diastolic'] as int).toList();
      final pulseValues = readings.where((r) => r['pulse_rate'] != null)
          .map((r) => r['pulse_rate'] as int).toList();

      final systolicAvg = systolicValues.reduce((a, b) => a + b) / systolicValues.length;
      final diastolicAvg = diastolicValues.reduce((a, b) => a + b) / diastolicValues.length;
      final pulseAvg = pulseValues.isNotEmpty 
          ? pulseValues.reduce((a, b) => a + b) / pulseValues.length 
          : 0;

      final result = {
        'systolic_avg': systolicAvg.round(),
        'diastolic_avg': diastolicAvg.round(),
        'pulse_avg': pulseAvg.round(),
        'count': readings.length,
      };

      print('✅ Retrieved blood pressure statistics: $result');
      return result;
    } catch (e) {
      print('❌ Error getting blood pressure statistics: $e');
      rethrow;
    }
  }

  /// Get blood pressure category based on systolic and diastolic values
  String getBloodPressureCategory(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) {
      return 'Normal';
    } else if (systolic < 130 && diastolic < 80) {
      return 'Elevated';
    } else if (systolic < 140 && diastolic < 90) {
      return 'Stage 1 Hypertension';
    } else if (systolic < 180 && diastolic < 110) {
      return 'Stage 2 Hypertension';
    } else {
      return 'Crisis';
    }
  }

  /// Get blood pressure category color
  Color getBloodPressureCategoryColor(String category) {
    switch (category) {
      case 'Normal':
        return Colors.green;
      case 'Elevated':
        return Colors.orange;
      case 'Stage 1 Hypertension':
        return Colors.red;
      case 'Stage 2 Hypertension':
        return Colors.red[700]!;
      case 'Crisis':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  // ===========================================
  // Utility Methods
  // ===========================================

  /// Get available reading types
  List<String> getReadingTypes() {
    return ['manual', 'automatic', 'ambulatory'];
  }

  /// Get available positions
  List<String> getPositions() {
    return ['sitting', 'standing', 'lying', 'walking'];
  }

  /// Validate blood pressure values
  bool isValidBloodPressure(int systolic, int diastolic) {
    return systolic > 0 && systolic <= 300 && 
           diastolic > 0 && diastolic <= 200 && 
           systolic > diastolic;
  }
} 