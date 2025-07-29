import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../services/supabase_auth_service.dart';

class StepsService {
  static final StepsService _instance = StepsService._internal();
  factory StepsService() => _instance;
  StepsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user ID
  String? get _currentUserId => SupabaseAuthService.instance.currentUser?.id;

  // =====================================================
  // STEPS READINGS OPERATIONS
  // =====================================================

  /// Get steps readings for a specific date range
  Future<List<Map<String, dynamic>>> getStepsReadings({
    DateTime? startDate,
    DateTime? endDate,
    String? activityType,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('steps_readings')
          .select()
          .eq('user_id', _currentUserId)
          .order('reading_date', ascending: false);

      List<Map<String, dynamic>> readings = List<Map<String, dynamic>>.from(response);

      // Filter by date range if specified
      if (startDate != null) {
        final startDateStr = startDate.toIso8601String().split('T')[0];
        readings = readings.where((reading) {
          final readingDate = reading['reading_date'] as String;
          return readingDate.compareTo(startDateStr) >= 0;
        }).toList();
      }

      if (endDate != null) {
        final endDateStr = endDate.toIso8601String().split('T')[0];
        readings = readings.where((reading) {
          final readingDate = reading['reading_date'] as String;
          return readingDate.compareTo(endDateStr) <= 0;
        }).toList();
      }

      // Filter by activity type if specified
      if (activityType != null) {
        readings = readings.where((reading) {
          return reading['activity_type'] == activityType;
        }).toList();
      }

      return readings;
    } catch (e) {
      print('❌ Error getting steps readings: $e');
      rethrow;
    }
  }

  /// Get today's steps
  Future<Map<String, dynamic>?> getTodaySteps() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final today = DateTime.now();
      final response = await _supabase
          .from('steps_readings')
          .select()
          .eq('user_id', _currentUserId)
          .eq('reading_date', today.toIso8601String().split('T')[0])
          .single();

      return response;
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        // No data found for today
        return null;
      }
      print('❌ Error getting today\'s steps: $e');
      rethrow;
    }
  }

  /// Get latest steps reading
  Future<Map<String, dynamic>?> getLatestStepsReading() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('steps_readings')
          .select()
          .eq('user_id', _currentUserId)
          .order('reading_date', ascending: false)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return response;
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        // No data found
        return null;
      }
      print('❌ Error getting latest steps reading: $e');
      rethrow;
    }
  }

  /// Add a new steps reading
  Future<Map<String, dynamic>> addStepsReading({
    required int stepsCount,
    String activityType = 'walking',
    String source = 'manual',
    String? notes,
    DateTime? readingDate,
    TimeOfDay? readingTime,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final date = readingDate ?? DateTime.now();
      final time = readingTime ?? TimeOfDay.now();

      final data = {
        'user_id': _currentUserId,
        'steps_count': stepsCount,
        'activity_type': activityType,
        'source': source,
        'notes': notes,
        'reading_date': date.toIso8601String().split('T')[0],
        'reading_time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
      };

      final response = await _supabase
          .from('steps_readings')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      print('❌ Error adding steps reading: $e');
      rethrow;
    }
  }

  /// Update a steps reading
  Future<Map<String, dynamic>> updateStepsReading({
    required String id,
    int? stepsCount,
    String? activityType,
    String? source,
    String? notes,
    DateTime? readingDate,
    TimeOfDay? readingTime,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final data = <String, dynamic>{};

      if (stepsCount != null) data['steps_count'] = stepsCount;
      if (activityType != null) data['activity_type'] = activityType;
      if (source != null) data['source'] = source;
      if (notes != null) data['notes'] = notes;
      if (readingDate != null) data['reading_date'] = readingDate.toIso8601String().split('T')[0];
      if (readingTime != null) {
        data['reading_time'] = '${readingTime.hour.toString().padLeft(2, '0')}:${readingTime.minute.toString().padLeft(2, '0')}:00';
      }

      final response = await _supabase
          .from('steps_readings')
          .update(data)
          .eq('id', id)
          .eq('user_id', _currentUserId)
          .select()
          .single();

      return response;
    } catch (e) {
      print('❌ Error updating steps reading: $e');
      rethrow;
    }
  }

  /// Delete a steps reading
  Future<void> deleteStepsReading(String id) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('steps_readings')
          .delete()
          .eq('id', id)
          .eq('user_id', _currentUserId);
    } catch (e) {
      print('❌ Error deleting steps reading: $e');
      rethrow;
    }
  }

  // =====================================================
  // STEPS GOALS OPERATIONS
  // =====================================================

  /// Get user's current active goal
  Future<Map<String, dynamic>?> getCurrentGoal() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('steps_goals')
          .select()
          .eq('user_id', _currentUserId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return response;
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        // No active goal found
        return null;
      }
      print('❌ Error getting current goal: $e');
      rethrow;
    }
  }

  /// Create or update user's daily goal
  Future<Map<String, dynamic>> setDailyGoal(int dailyGoal) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Deactivate all existing goals
      await _supabase
          .from('steps_goals')
          .update({'is_active': false})
          .eq('user_id', _currentUserId)
          .eq('is_active', true);

      // Create new goal
      final data = {
        'user_id': _currentUserId,
        'daily_goal': dailyGoal,
        'goal_type': 'daily',
        'is_active': true,
        'start_date': DateTime.now().toIso8601String().split('T')[0],
      };

      final response = await _supabase
          .from('steps_goals')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      print('❌ Error setting daily goal: $e');
      rethrow;
    }
  }

  // =====================================================
  // STATISTICS OPERATIONS
  // =====================================================

  /// Get steps statistics for a date range
  Future<Map<String, dynamic>> getStepsStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final response = await _supabase
          .rpc('get_steps_statistics', params: {
            'user_uuid': _currentUserId,
            'start_date': start.toIso8601String().split('T')[0],
            'end_date': end.toIso8601String().split('T')[0],
          });

      return response;
    } catch (e) {
      print('❌ Error getting steps statistics: $e');
      rethrow;
    }
  }

  /// Get daily steps for a specific date
  Future<int> getDailySteps(DateTime date) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .rpc('get_daily_steps', params: {
            'user_uuid': _currentUserId,
            'target_date': date.toIso8601String().split('T')[0],
          });

      return response;
    } catch (e) {
      print('❌ Error getting daily steps: $e');
      rethrow;
    }
  }

  /// Get weekly steps
  Future<int> getWeeklySteps({DateTime? startDate}) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 6));

      final response = await _supabase
          .rpc('get_weekly_steps', params: {
            'user_uuid': _currentUserId,
            'start_date': start.toIso8601String().split('T')[0],
          });

      return response;
    } catch (e) {
      print('❌ Error getting weekly steps: $e');
      rethrow;
    }
  }

  /// Get monthly steps
  Future<int> getMonthlySteps({DateTime? targetMonth}) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final month = targetMonth ?? DateTime.now();

      final response = await _supabase
          .rpc('get_monthly_steps', params: {
            'user_uuid': _currentUserId,
            'target_month': DateTime(month.year, month.month, 1).toIso8601String().split('T')[0],
          });

      return response;
    } catch (e) {
      print('❌ Error getting monthly steps: $e');
      rethrow;
    }
  }

  // =====================================================
  // DASHBOARD HELPERS
  // =====================================================

  /// Get steps data for dashboard
  Future<Map<String, dynamic>> getDashboardStepsData() async {
    try {
      final todaySteps = await getTodaySteps();
      final currentGoal = await getCurrentGoal();
      final weeklyStats = await getStepsStatistics(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );

      return {
        'today_steps': todaySteps?['steps_count'] ?? 0,
        'daily_goal': currentGoal?['daily_goal'] ?? 10000,
        'weekly_stats': weeklyStats,
        'goal_achievement': todaySteps != null 
            ? ((todaySteps['steps_count'] as int) / (currentGoal?['daily_goal'] ?? 10000) * 100).clamp(0, 100)
            : 0.0,
      };
    } catch (e) {
      print('❌ Error getting dashboard steps data: $e');
      rethrow;
    }
  }

  /// Get weekly progress data for charts
  Future<List<Map<String, dynamic>>> getWeeklyProgress() async {
    try {
      final startDate = DateTime.now().subtract(const Duration(days: 6));
      final readings = await getStepsReadings(
        startDate: startDate,
        endDate: DateTime.now(),
      );

      // Group by date and sum steps
      final Map<String, int> dailySteps = {};
      for (final reading in readings) {
        final date = reading['reading_date'] as String;
        final steps = reading['steps_count'] as int;
        dailySteps[date] = (dailySteps[date] ?? 0) + steps;
      }

      // Create list for last 7 days
      final List<Map<String, dynamic>> weeklyData = [];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];
        final steps = dailySteps[dateStr] ?? 0;

        weeklyData.add({
          'date': dateStr,
          'steps': steps,
          'day_name': _getDayName(date.weekday),
        });
      }

      return weeklyData;
    } catch (e) {
      print('❌ Error getting weekly progress: $e');
      rethrow;
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return 'Mon';
    }
  }
} 