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

  /// Get today's steps (aggregated total)
  Future<Map<String, dynamic>?> getTodaySteps() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final today = DateTime.now();
      final response = await _supabase
          .from('steps_readings')
          .select('steps_count')
          .eq('user_id', _currentUserId)
          .eq('reading_date', today.toIso8601String().split('T')[0]);

      if (response.isEmpty) {
        return null;
      }

      // Convert all steps_count to integers first
      final List<int> stepCounts = List<Map<String, dynamic>>.from(response)
          .map((reading) => int.parse(reading['steps_count'].toString()))
          .toList();

      // Now sum up all steps
      final totalSteps = stepCounts.fold<int>(0, (sum, steps) => sum + steps);
      
      return {
        'steps_count': totalSteps,
        'reading_date': today.toIso8601String().split('T')[0],
        'user_id': _currentUserId,
      };
    } catch (e) {
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
          .from('steps_readings')
          .select('steps_count, reading_date')
          .eq('user_id', _currentUserId);

      List<Map<String, dynamic>> readings = List<Map<String, dynamic>>.from(response);
      
      // Filter by date range
      final startStr = start.toIso8601String().split('T')[0];
      final endStr = end.toIso8601String().split('T')[0];
      
      readings = readings.where((reading) {
        final readingDate = reading['reading_date'] as String;
        return readingDate.compareTo(startStr) >= 0 && readingDate.compareTo(endStr) <= 0;
      }).toList();
      
      if (readings.isEmpty) {
        return {
          'total_steps': 0,
          'average_steps': 0.0,
          'max_steps': 0,
          'min_steps': 0,
          'days_with_data': 0,
        };
      }

             final totalSteps = readings.fold<int>(0, (sum, reading) => sum + (int.parse(reading['steps_count'].toString())));
      final averageSteps = totalSteps / readings.length;
             final maxSteps = readings.map((r) => int.parse(r['steps_count'].toString())).reduce((a, b) => a > b ? a : b);
       final minSteps = readings.map((r) => int.parse(r['steps_count'].toString())).reduce((a, b) => a < b ? a : b);
      final uniqueDates = readings.map((r) => r['reading_date']).toSet().length;

      return {
        'total_steps': totalSteps,
        'average_steps': averageSteps,
        'max_steps': maxSteps,
        'min_steps': minSteps,
        'days_with_data': uniqueDates,
      };
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
          .from('steps_readings')
          .select('steps_count')
          .eq('user_id', _currentUserId)
          .eq('reading_date', date.toIso8601String().split('T')[0]);

      // Convert all steps_count to integers first
      final List<int> stepCounts = List<Map<String, dynamic>>.from(response)
          .map((reading) => int.parse(reading['steps_count'].toString()))
          .toList();

      // Now sum up all steps
      return stepCounts.fold<int>(0, (sum, steps) => sum + steps);
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
          .from('steps_readings')
          .select('steps_count')
          .eq('user_id', _currentUserId);

      List<Map<String, dynamic>> readings = List<Map<String, dynamic>>.from(response);
      
      // Filter by date range and convert steps to integers
      final startStr = start.toIso8601String().split('T')[0];
      final endStr = DateTime.now().toIso8601String().split('T')[0];
      
      // Convert all steps_count to integers first and filter by date
      final List<int> stepCounts = List<Map<String, dynamic>>.from(response)
          .where((reading) {
            final readingDate = reading['reading_date'] as String;
            return readingDate.compareTo(startStr) >= 0 && readingDate.compareTo(endStr) <= 0;
          })
          .map((reading) => int.parse(reading['steps_count'].toString()))
          .toList();

      // Now sum up all steps
      return stepCounts.fold<int>(0, (sum, steps) => sum + steps);
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
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      final response = await _supabase
          .from('steps_readings')
          .select('steps_count')
          .eq('user_id', _currentUserId);

      List<Map<String, dynamic>> readings = List<Map<String, dynamic>>.from(response);
      
      // Filter by date range and convert steps to integers
      final startStr = startOfMonth.toIso8601String().split('T')[0];
      final endStr = endOfMonth.toIso8601String().split('T')[0];
      
      // Convert all steps_count to integers first and filter by date
      final List<int> stepCounts = List<Map<String, dynamic>>.from(response)
          .where((reading) {
            final readingDate = reading['reading_date'] as String;
            return readingDate.compareTo(startStr) >= 0 && readingDate.compareTo(endStr) <= 0;
          })
          .map((reading) => int.parse(reading['steps_count'].toString()))
          .toList();

      // Now sum up all steps
      return stepCounts.fold<int>(0, (sum, steps) => sum + steps);
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

      final todayStepsCount = int.parse((todaySteps?['steps_count'] ?? 0).toString());
      final dailyGoal = int.parse((currentGoal?['daily_goal'] ?? 10000).toString());

      return {
        'today_steps': todayStepsCount,
        'daily_goal': dailyGoal,
        'weekly_stats': weeklyStats,
        'goal_achievement': dailyGoal > 0 
            ? ((todayStepsCount / dailyGoal) * 100).clamp(0, 100)
            : 0.0,
      };
    } catch (e) {
      print('❌ Error getting dashboard steps data: $e');
      rethrow;
    }
  }

  /// Get progress data for charts based on selected period
  Future<List<Map<String, dynamic>>> getWeeklyProgress({String period = 'This Week'}) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      
      switch (period) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = now.subtract(const Duration(days: 6));
      }
      
      final readings = await getStepsReadings(
        startDate: startDate,
        endDate: now,
      );

      // Group by date and sum steps
      final Map<String, int> dailySteps = {};
      for (final reading in readings) {
        final date = reading['reading_date'] as String;
        final steps = int.parse(reading['steps_count'].toString());
        dailySteps[date] = (dailySteps[date] ?? 0) + steps;
      }

      // Create list for the selected period with appropriate intervals
      final List<Map<String, dynamic>> progressData = [];
      final List<DateTime> intervals = [];
      
      // Generate intervals based on period
      DateTime current = startDate;
      switch (period) {
        case 'Today':
          // Divide day into 6 4-hour intervals
          for (int hour = 0; hour < 24; hour += 4) {
            // Only add intervals up to the current hour
            if (hour <= now.hour) {
              intervals.add(DateTime(now.year, now.month, now.day, hour));
            }
          }
          break;
          
        case 'This Week':
          while (!current.isAfter(now)) {
            intervals.add(current);
            current = current.add(const Duration(days: 1));
          }
          break;
          
        case 'This Month':
          // Divide month into weeks
          while (!current.isAfter(now)) {
            intervals.add(current);
            current = current.add(const Duration(days: 7));
          }
          if (current.subtract(const Duration(days: 7)).isBefore(now)) {
            intervals.add(now);
          }
          break;
          
        case 'This Year':
          // Use quarters (3 months intervals)
          while (current.isBefore(DateTime(now.year + 1, 1, 1))) {
            intervals.add(current);
            current = DateTime(current.year, current.month + 3, 1);
          }
          break;
          
        default:
          while (!current.isAfter(now)) {
            intervals.add(current);
            current = current.add(const Duration(days: 1));
          }
      }

      // Create data points for each interval
      for (int i = 0; i < intervals.length; i++) {
        final currentInterval = intervals[i];
        final nextInterval = i < intervals.length - 1 
            ? intervals[i + 1] 
                          : period == 'Today' 
              ? (i < intervals.length - 1 
                  ? intervals[i + 1] 
                  : DateTime(now.year, now.month, now.day, now.hour + 1))
              : now.add(const Duration(days: 1));

        // Calculate total steps for this interval
        int totalSteps = 0;
        dailySteps.forEach((date, steps) {
          final readingDate = DateTime.parse(date);
          if (readingDate.isAfter(currentInterval.subtract(const Duration(seconds: 1))) && 
              readingDate.isBefore(nextInterval)) {
            totalSteps += steps;
          }
        });

        String label;
        switch (period) {
          case 'Today':
            final endHour = i < intervals.length - 1 
                ? intervals[i + 1].hour
                : now.hour;
            label = '${currentInterval.hour.toString().padLeft(2, '0')}-${endHour.toString().padLeft(2, '0')}';
            break;
          case 'This Week':
            label = _getDayName(currentInterval.weekday);
            break;
          case 'This Month':
            final weekNum = ((currentInterval.day - 1) ~/ 7) + 1;
            label = 'W$weekNum';
            break;
          case 'This Year':
            final quarterNum = ((currentInterval.month - 1) ~/ 3) + 1;
            label = 'Q$quarterNum';
            break;
          default:
            label = _getDayName(currentInterval.weekday);
        }

        progressData.add({
          'date': currentInterval.toIso8601String(),
          'steps': totalSteps,
          'label': label,
        });
      }

      return progressData;
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

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
} 