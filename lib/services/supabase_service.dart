import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;
  SupabaseClient get client => _client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    _client = Supabase.instance.client;
  }

  // Auth Methods
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'role': 'patient'},
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // User Profile Methods
  Future<void> createProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _client
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();
    return response;
  }

  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('profiles').update({
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // Medication Methods
  Future<List<Map<String, dynamic>>> getMedications(String userId) async {
    final response = await _client
      .from('medications')
      .select()
      .eq('user_id', userId)
      .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addMedication({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('medications').insert({
      'user_id': userId,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateMedication({
    required String medicationId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('medications').update({
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', medicationId);
  }

  Future<void> deleteMedication(String medicationId) async {
    await _client.from('medications').delete().eq('id', medicationId);
  }

  // Medication History Methods
  Future<void> logMedicationHistory({
    required String medicationId,
    required String userId,
    required String status,
    required DateTime scheduledFor,
    DateTime? takenAt,
  }) async {
    await _client.from('medication_history').insert({
      'medication_id': medicationId,
      'user_id': userId,
      'status': status,
      'scheduled_for': scheduledFor.toIso8601String(),
      'taken_at': takenAt?.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getMedicationHistory({
    required String medicationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
      .from('medication_history')
      .select()
      .eq('medication_id', medicationId);
    
    if (startDate != null) {
      query = query.gte('scheduled_for', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('scheduled_for', endDate.toIso8601String());
    }
    
    final response = await query.order('scheduled_for');
    return List<Map<String, dynamic>>.from(response);
  }

  // Reminder Settings Methods
  Future<void> updateReminderSettings({
    required String medicationId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('reminder_settings').upsert({
      'medication_id': medicationId,
      'user_id': userId,
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getReminderSettings({
    required String medicationId,
    required String userId,
  }) async {
    final response = await _client
      .from('reminder_settings')
      .select()
      .eq('medication_id', medicationId)
      .eq('user_id', userId)
      .single();
    return response;
  }

  // Health Readings Methods
  Future<void> addHealthReading({
    required String table,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from(table).insert({
      'user_id': userId,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHealthReadings({
    required String table,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
      .from(table)
      .select()
      .eq('user_id', userId);
    
    if (startDate != null) {
      query = query.gte('reading_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('reading_date', endDate.toIso8601String());
    }
    
    final response = await query.order('reading_date');
    return List<Map<String, dynamic>>.from(response);
  }
} 