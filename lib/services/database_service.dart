import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sugar_insights.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name TEXT,
        phone TEXT,
        role TEXT DEFAULT 'patient',
        date_of_birth TEXT,
        gender TEXT,
        height REAL,
        weight REAL,
        diabetes_type TEXT,
        diagnosis_date TEXT,
        unique_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Onboarding progress table
    await db.execute('''
      CREATE TABLE onboarding_progress (
        user_id TEXT PRIMARY KEY,
        basic_details_completed BOOLEAN DEFAULT FALSE,
        height_weight_completed BOOLEAN DEFAULT FALSE,
        diabetes_status_completed BOOLEAN DEFAULT FALSE,
        diabetes_type_completed BOOLEAN DEFAULT FALSE,
        diagnosis_timeline_completed BOOLEAN DEFAULT FALSE,
        unique_id_completed BOOLEAN DEFAULT FALSE,
        completed_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Sessions table for authentication
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        token TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  // User authentication methods
  Future<User?> authenticateUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, _hashPassword(password)],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<bool> emailExists(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }

  Future<User> createUser({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    final db = await database;
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    final userData = {
      'id': userId,
      'email': email,
      'password_hash': _hashPassword(password),
      'name': name,
      'phone': phone,
      'role': 'patient',
      'created_at': now,
      'updated_at': now,
    };

    await db.insert('users', userData);
    return User.fromJson(userData);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update(
      'users',
      data,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Session management
  Future<String> createSession(String userId) async {
    final db = await database;
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final token = _generateToken();
    final expiresAt = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    final createdAt = DateTime.now().toIso8601String();

    await db.insert('sessions', {
      'id': sessionId,
      'user_id': userId,
      'token': token,
      'expires_at': expiresAt,
      'created_at': createdAt,
    });

    return token;
  }

  Future<String?> getUserIdFromToken(String token) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'token = ? AND expires_at > ?',
      whereArgs: [token, DateTime.now().toIso8601String()],
    );

    if (maps.isNotEmpty) {
      return maps.first['user_id'] as String;
    }
    return null;
  }

  Future<void> deleteSession(String token) async {
    final db = await database;
    await db.delete(
      'sessions',
      where: 'token = ?',
      whereArgs: [token],
    );
  }

  // Onboarding progress methods
  Future<Map<String, bool>> getOnboardingProgress(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'onboarding_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return {
        'basic_details_completed': maps.first['basic_details_completed'] == 1,
        'height_weight_completed': maps.first['height_weight_completed'] == 1,
        'diabetes_status_completed': maps.first['diabetes_status_completed'] == 1,
        'diabetes_type_completed': maps.first['diabetes_type_completed'] == 1,
        'diagnosis_timeline_completed': maps.first['diagnosis_timeline_completed'] == 1,
        'unique_id_completed': maps.first['unique_id_completed'] == 1,
      };
    }

    // Create new onboarding progress record
    await db.insert('onboarding_progress', {
      'user_id': userId,
      'basic_details_completed': 0,
      'height_weight_completed': 0,
      'diabetes_status_completed': 0,
      'diabetes_type_completed': 0,
      'diagnosis_timeline_completed': 0,
      'unique_id_completed': 0,
    });

    return {
      'basic_details_completed': false,
      'height_weight_completed': false,
      'diabetes_status_completed': false,
      'diabetes_type_completed': false,
      'diagnosis_timeline_completed': false,
      'unique_id_completed': false,
    };
  }

  Future<void> updateOnboardingProgress(String userId, String step, bool completed) async {
    final db = await database;
    await db.update(
      'onboarding_progress',
      {step: completed ? 1 : 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> completeOnboarding(String userId) async {
    final db = await database;
    await db.update(
      'onboarding_progress',
      {
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Helper methods
  String _hashPassword(String password) {
    // Simple hash for demo - in production, use proper hashing
    return password.hashCode.toString();
  }

  String _generateToken() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (1000 + DateTime.now().microsecond).toString();
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} 