import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_entry.dart';

class FoodService {
  final SupabaseClient _supabase;

  FoodService(this._supabase);

  // Get food entries for a specific date
  Future<List<FoodEntry>> getFoodEntries({
    DateTime? date,
    String? mealType,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase
          .from('food_entries')
          .select();

      // Apply date filter
      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        query = query
            .gte('timestamp', startOfDay.toIso8601String())
            .lt('timestamp', endOfDay.toIso8601String());
      }

      // Apply meal type filter
      if (mealType != null) {
        query = query.eq('meal_type', mealType);
      }

      // Execute the query first
      final response = await query;
      
      // Convert to list and sort by timestamp
      var entries = List<Map<String, dynamic>>.from(response);
      entries.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      
      // Apply pagination
      if (offset != null && limit != null) {
        final start = offset;
        final end = offset + limit;
        if (start < entries.length) {
          entries = entries.sublist(start, end > entries.length ? entries.length : end);
        } else {
          entries = [];
        }
      } else if (limit != null && entries.length > limit) {
        entries = entries.take(limit).toList();
      }

      return entries
          .map((json) => FoodEntry.fromJson(json))
          .toList();
    } catch (e) {
      throw 'Failed to load food entries: $e';
    }
  }

  // Get food entry by ID
  Future<FoodEntry> getFoodEntryById(String entryId) async {
    try {
      final response = await _supabase
          .from('food_entries')
          .select()
          .eq('id', entryId)
          .single();

      return FoodEntry.fromJson(response);
    } catch (e) {
      throw 'Failed to load food entry: $e';
    }
  }

  // Create new food entry
  Future<FoodEntry> createFoodEntry(FoodEntry entry) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      final data = {
        'user_id': userId,
        'name': entry.name,
        'description': entry.description,
        'timestamp': entry.timestamp.toIso8601String(),
        'image_url': entry.imageUrl,
        'calories': entry.calories,
        'carbs': entry.carbs,
        'protein': entry.protein,
        'fat': entry.fat,
        'meal_type': entry.mealType,
      };

      print('Creating food entry with data: $data');

      final response = await _supabase
          .from('food_entries')
          .insert(data)
          .select()
          .single();

      print('Response from database: $response');

      return FoodEntry.fromJson(response);
    } catch (e) {
      print('Error creating food entry: $e');
      throw 'Failed to create food entry: $e';
    }
  }

  // Update food entry
  Future<FoodEntry> updateFoodEntry(FoodEntry entry) async {
    try {
      if (entry.id == null) {
        throw 'Food entry ID is required for update';
      }

      final data = {
        'name': entry.name,
        'description': entry.description,
        'timestamp': entry.timestamp.toIso8601String(),
        'image_url': entry.imageUrl,
        'calories': entry.calories,
        'carbs': entry.carbs,
        'protein': entry.protein,
        'fat': entry.fat,
        'meal_type': entry.mealType,
      };

      print('Updating food entry with data: $data');

      final response = await _supabase
          .from('food_entries')
          .update(data)
          .eq('id', entry.id)
          .select()
          .single();

      print('Response from database: $response');

      return FoodEntry.fromJson(response);
    } catch (e) {
      print('Error updating food entry: $e');
      throw 'Failed to update food entry: $e';
    }
  }

  // Delete food entry
  Future<void> deleteFoodEntry(String entryId) async {
    try {
      await _supabase
          .from('food_entries')
          .delete()
          .eq('id', entryId);
    } catch (e) {
      throw 'Failed to delete food entry: $e';
    }
  }

  // Get daily nutrition summary
  Future<Map<String, dynamic>> getDailyNutritionSummary(DateTime date) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .rpc('get_daily_nutrition_summary', params: {
        'p_user_id': userId,
        'p_date': dateStr,
      });

      if (response != null && response.isNotEmpty) {
        return response[0];
      }

      return {
        'total_calories': 0,
        'total_carbs': 0.0,
        'total_protein': 0.0,
        'total_fat': 0.0,
        'meal_count': 0,
      };
    } catch (e) {
      throw 'Failed to get daily nutrition summary: $e';
    }
  }

  // Get nutrition by meal type for a date range
  Future<List<Map<String, dynamic>>> getNutritionByMealType({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .rpc('get_nutrition_by_meal_type', params: {
        'p_user_id': userId,
        'p_start_date': startDateStr,
        'p_end_date': endDateStr,
      });

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw 'Failed to get nutrition by meal type: $e';
    }
  }

  // Search food items from the food database
  Future<List<Map<String, dynamic>>> searchFoodItems(String query) async {
    try {
      final response = await _supabase
          .from('food_items')
          .select('*')
          .ilike('name', '%$query%')
          .eq('is_active', true);

      var items = List<Map<String, dynamic>>.from(response);
      
      // Apply limit manually
      if (items.length > 20) {
        items = items.take(20).toList();
      }

      return items;
    } catch (e) {
      throw 'Failed to search food items: $e';
    }
  }

  // Get meal types
  Future<List<Map<String, dynamic>>> getMealTypes() async {
    try {
      final response = await _supabase
          .from('meal_types')
          .select('*')
          .eq('is_active', true);

      var items = List<Map<String, dynamic>>.from(response);
      
      // Sort by sort_order
      items.sort((a, b) => (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0));

      return items;
    } catch (e) {
      throw 'Failed to get meal types: $e';
    }
  }

  // Test method to check database structure
  Future<void> testDatabaseConnection() async {
    try {
      print('Testing database connection...');
      
      // Test if food_entries table exists
      final response = await _supabase
          .from('food_entries')
          .select('count')
          .limit(1);
      
      print('✅ Food entries table exists');
      
      // Test if food_items table exists
      final foodItemsResponse = await _supabase
          .from('food_items')
          .select('count')
          .limit(1);
      
      print('✅ Food items table exists');
      
      // Test if meal_types table exists
      final mealTypesResponse = await _supabase
          .from('meal_types')
          .select('count')
          .limit(1);
      
      print('✅ Meal types table exists');
      
    } catch (e) {
      print('❌ Database connection test failed: $e');
      throw 'Database connection test failed: $e';
    }
  }

  // Get food categories
  Future<List<Map<String, dynamic>>> getFoodCategories() async {
    try {
      final response = await _supabase
          .from('food_categories')
          .select('*')
          .eq('is_active', true);

      var items = List<Map<String, dynamic>>.from(response);
      
      // Sort by sort_order
      items.sort((a, b) => (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0));

      return items;
    } catch (e) {
      throw 'Failed to get food categories: $e';
    }
  }
} 