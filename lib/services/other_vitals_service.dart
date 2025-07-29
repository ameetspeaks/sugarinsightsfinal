import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class OtherVitalsService {
  static final OtherVitalsService _instance = OtherVitalsService._internal();
  factory OtherVitalsService() => _instance;
  OtherVitalsService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ===========================================
  // CRUD Operations
  // ===========================================

  /// Add a new vital reading
  Future<Map<String, dynamic>> addVitalReading({
    required String vitalType,
    required double value,
    required String unit,
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
        'vital_type': vitalType,
        'value': value,
        'unit': unit,
        'notes': notes,
        'reading_date': readingDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

      print('🔄 Adding vital reading: $data');
      
      final response = await _client
          .from('other_vitals_readings')
          .insert(data)
          .select()
          .single();

      print('✅ Vital reading added successfully: ${response['id']}');
      return response;
    } catch (e) {
      print('❌ Error adding vital reading: $e');
      rethrow;
    }
  }

  /// Get all vital readings for the current user
  Future<List<Map<String, dynamic>>> getVitalReadings({
    int? limit,
    String? vitalType,
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
          .from('other_vitals_readings')
          .select()
          .eq('user_id', currentUser.id);

      if (vitalType != null) {
        query = query.eq('vital_type', vitalType);
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

      print('✅ Retrieved ${readings.length} vital readings');
      return readings;
    } catch (e) {
      print('❌ Error getting vital readings: $e');
      rethrow;
    }
  }

  /// Get latest vital readings for dashboard
  Future<Map<String, dynamic>> getLatestVitalReadings() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get all vital readings for the user
      final allReadings = await _client
          .from('other_vitals_readings')
          .select()
          .eq('user_id', currentUser.id);

      // Convert to list and sort by date
      var readings = List<Map<String, dynamic>>.from(allReadings);
      readings.sort((a, b) => DateTime.parse(b['reading_date']).compareTo(DateTime.parse(a['reading_date'])));

      // Find latest readings for each vital type
      Map<String, dynamic>? latestHba1c;
      Map<String, dynamic>? latestUacr;
      Map<String, dynamic>? latestHb;

      for (var reading in readings) {
        if (reading['vital_type'] == 'hba1c' && latestHba1c == null) {
          latestHba1c = reading;
        } else if (reading['vital_type'] == 'uacr' && latestUacr == null) {
          latestUacr = reading;
        } else if (reading['vital_type'] == 'hb' && latestHb == null) {
          latestHb = reading;
        }

        // Break if we found all three
        if (latestHba1c != null && latestUacr != null && latestHb != null) {
          break;
        }
      }

      final result = {
        'hba1c': latestHba1c,
        'uacr': latestUacr,
        'hb': latestHb,
      };

      print('✅ Retrieved latest vital readings');
      return result;
    } catch (e) {
      print('❌ Error getting latest vital readings: $e');
      rethrow;
    }
  }

  /// Update a vital reading
  Future<Map<String, dynamic>> updateVitalReading({
    required String id,
    String? vitalType,
    double? value,
    String? unit,
    String? notes,
    DateTime? readingDate,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final data = <String, dynamic>{};
      if (vitalType != null) data['vital_type'] = vitalType;
      if (value != null) data['value'] = value;
      if (unit != null) data['unit'] = unit;
      if (notes != null) data['notes'] = notes;
      if (readingDate != null) data['reading_date'] = readingDate.toIso8601String();

      print('🔄 Updating vital reading $id: $data');

      final response = await _client
          .from('other_vitals_readings')
          .update(data)
          .eq('id', id)
          .eq('user_id', currentUser.id)
          .select()
          .single();

      print('✅ Vital reading updated successfully');
      return response;
    } catch (e) {
      print('❌ Error updating vital reading: $e');
      rethrow;
    }
  }

  /// Delete a vital reading
  Future<void> deleteVitalReading(String id) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('🔄 Deleting vital reading: $id');

      await _client
          .from('other_vitals_readings')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUser.id);

      print('✅ Vital reading deleted successfully');
    } catch (e) {
      print('❌ Error deleting vital reading: $e');
      rethrow;
    }
  }

  // ===========================================
  // Analytics and Statistics
  // ===========================================

  /// Get vital statistics for a time period
  Future<Map<String, dynamic>> getVitalStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? vitalType,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      var query = _client
          .from('other_vitals_readings')
          .select('value, vital_type')
          .eq('user_id', currentUser.id);

      if (vitalType != null) {
        query = query.eq('vital_type', vitalType);
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

      final values = readings.map((r) => (r['value'] as num).toDouble()).toList();
      final average = values.reduce((a, b) => a + b) / values.length;
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);

      final result = {
        'average': average,
        'min': min,
        'max': max,
        'count': readings.length,
      };

      print('✅ Retrieved vital statistics: $result');
      return result;
    } catch (e) {
      print('❌ Error getting vital statistics: $e');
      rethrow;
    }
  }

  // ===========================================
  // Utility Methods
  // ===========================================

  /// Get available vital types
  List<String> getVitalTypes() {
    return [
      'hba1c', 'uacr', 'hb', 'creatinine', 'egfr', 
      'cholesterol', 'triglycerides', 'ldl', 'hdl', 
      'bmi', 'weight', 'height', 'temperature', 
      'oxygen_saturation', 'respiratory_rate'
    ];
  }

  /// Get vital type display name
  String getVitalTypeDisplayName(String vitalType) {
    switch (vitalType) {
      case 'hba1c':
        return 'HBA1C';
      case 'uacr':
        return 'UACR';
      case 'hb':
        return 'Hemoglobin';
      case 'creatinine':
        return 'Creatinine';
      case 'egfr':
        return 'eGFR';
      case 'cholesterol':
        return 'Total Cholesterol';
      case 'triglycerides':
        return 'Triglycerides';
      case 'ldl':
        return 'LDL';
      case 'hdl':
        return 'HDL';
      case 'bmi':
        return 'BMI';
      case 'weight':
        return 'Weight';
      case 'height':
        return 'Height';
      case 'temperature':
        return 'Temperature';
      case 'oxygen_saturation':
        return 'Oxygen Saturation';
      case 'respiratory_rate':
        return 'Respiratory Rate';
      default:
        return vitalType.toUpperCase();
    }
  }

  /// Get default unit for vital type
  String getDefaultUnit(String vitalType) {
    switch (vitalType) {
      case 'hba1c':
        return '%';
      case 'uacr':
        return 'mg/g';
      case 'hb':
        return 'g/dL';
      case 'creatinine':
        return 'mg/dL';
      case 'egfr':
        return 'mL/min/1.73m²';
      case 'cholesterol':
      case 'triglycerides':
      case 'ldl':
      case 'hdl':
        return 'mg/dL';
      case 'bmi':
        return 'kg/m²';
      case 'weight':
        return 'kg';
      case 'height':
        return 'cm';
      case 'temperature':
        return '°C';
      case 'oxygen_saturation':
        return '%';
      case 'respiratory_rate':
        return 'breaths/min';
      default:
        return '';
    }
  }

  /// Get vital category based on value and type
  String getVitalCategory(String vitalType, double value) {
    switch (vitalType) {
      case 'hba1c':
        if (value < 5.7) return 'Normal';
        if (value < 6.5) return 'Prediabetes';
        return 'Diabetes';
      case 'uacr':
        if (value < 30) return 'Normal';
        if (value < 300) return 'Microalbuminuria';
        return 'Macroalbuminuria';
      case 'hb':
        if (value >= 13.5 && value <= 17.5) return 'Normal (Male)';
        if (value >= 12.0 && value <= 15.5) return 'Normal (Female)';
        return 'Abnormal';
      case 'bmi':
        if (value < 18.5) return 'Underweight';
        if (value < 25) return 'Normal';
        if (value < 30) return 'Overweight';
        return 'Obese';
      default:
        return 'Normal';
    }
  }

  /// Get vital category color
  Color getVitalCategoryColor(String category) {
    switch (category) {
      case 'Normal':
      case 'Normal (Male)':
      case 'Normal (Female)':
        return Colors.green;
      case 'Prediabetes':
      case 'Microalbuminuria':
      case 'Overweight':
        return Colors.orange;
      case 'Diabetes':
      case 'Macroalbuminuria':
      case 'Obese':
        return Colors.red;
      case 'Underweight':
        return Colors.blue;
      case 'Abnormal':
        return Colors.red[700]!;
      default:
        return Colors.grey;
    }
  }

  /// Validate vital value
  bool isValidVitalValue(String vitalType, double value) {
    switch (vitalType) {
      case 'hba1c':
        return value >= 0 && value <= 20;
      case 'uacr':
        return value >= 0 && value <= 10000;
      case 'hb':
        return value >= 0 && value <= 30;
      case 'creatinine':
        return value >= 0 && value <= 20;
      case 'egfr':
        return value >= 0 && value <= 200;
      case 'cholesterol':
      case 'triglycerides':
      case 'ldl':
      case 'hdl':
        return value >= 0 && value <= 1000;
      case 'bmi':
        return value >= 10 && value <= 100;
      case 'weight':
        return value >= 0 && value <= 500;
      case 'height':
        return value >= 0 && value <= 300;
      case 'temperature':
        return value >= 20 && value <= 50;
      case 'oxygen_saturation':
        return value >= 0 && value <= 100;
      case 'respiratory_rate':
        return value >= 0 && value <= 100;
      default:
        return value > 0;
    }
  }
} 