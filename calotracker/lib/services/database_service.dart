// Database Service
// SQLite database management for all app data
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';
import '../models/calo_record.dart';
import '../models/meal.dart';
import '../models/gym_session.dart';
import '../models/chat_message.dart';
import '../models/water_record.dart';
import '../models/weight_record.dart';
import '../models/sleep_record.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'calotracker.db';
  static const int _dbVersion = 6; // Updated version for avatar support

  /// Get database instance (singleton)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables
  static Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        goal TEXT NOT NULL,
        bmr REAL NOT NULL,
        daily_target REAL NOT NULL,
        created_at INTEGER NOT NULL,
        country TEXT DEFAULT 'VN',
        language TEXT DEFAULT 'vi',
        avatar_url TEXT
      )
    ''');

    // Calorie records table
    await db.execute('''
      CREATE TABLE calo_records (
        date TEXT PRIMARY KEY,
        calo_intake REAL DEFAULT 0,
        calo_burned REAL DEFAULT 0,
        net_calo REAL DEFAULT 0
      )
    ''');

    // Meals table
    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        date_time INTEGER NOT NULL,
        food_name TEXT NOT NULL,
        weight REAL,
        calories REAL NOT NULL,
        protein REAL,
        carbs REAL,
        fat REAL,
        source TEXT NOT NULL
      )
    ''');

    // Gym sessions table
    await db.execute('''
      CREATE TABLE gym_sessions (
        id TEXT PRIMARY KEY,
        scheduled_time INTEGER NOT NULL,
        end_time INTEGER,
        actual_time INTEGER,
        gym_type TEXT NOT NULL,
        estimated_calories REAL NOT NULL,
        is_completed INTEGER DEFAULT 0,
        duration_minutes INTEGER DEFAULT 60
      )
    ''');

    // Chat history table
    await db.execute('''
      CREATE TABLE chat_history (
        id TEXT PRIMARY KEY,
        timestamp INTEGER NOT NULL,
        message TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        nutrition TEXT
      )
    ''');

    // Water records table
    await db.execute('''
      CREATE TABLE water_records (
        id TEXT PRIMARY KEY,
        date_time INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        note TEXT
      )
    ''');

    // Weight records table
    await db.execute('''
      CREATE TABLE weight_records (
        id TEXT PRIMARY KEY,
        date_time INTEGER NOT NULL,
        weight REAL NOT NULL,
        note TEXT
      )
    ''');

    // Sleep records table
    await db.execute('''
      CREATE TABLE sleep_records (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        bed_time INTEGER NOT NULL,
        wake_time INTEGER NOT NULL,
        quality INTEGER,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_meals_date ON meals(date_time)');
    await db.execute(
      'CREATE INDEX idx_gym_scheduled ON gym_sessions(scheduled_time)',
    );
    await db.execute(
      'CREATE INDEX idx_chat_timestamp ON chat_history(timestamp)',
    );
    await db.execute('CREATE INDEX idx_water_date ON water_records(date_time)');
    await db.execute(
      'CREATE INDEX idx_weight_date ON weight_records(date_time)',
    );
    await db.execute('CREATE INDEX idx_sleep_date ON sleep_records(date)');
  }

  /// Handle database upgrades
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Migration from v1 to v2: Add duration_minutes and end_time to gym_sessions
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE gym_sessions ADD COLUMN end_time INTEGER');
      await db.execute(
        'ALTER TABLE gym_sessions ADD COLUMN duration_minutes INTEGER DEFAULT 60',
      );
    }

    // Migration from v2 to v3: Add water_records table
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS water_records (
          id TEXT PRIMARY KEY,
          date_time INTEGER NOT NULL,
          amount INTEGER NOT NULL,
          note TEXT
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_water_date ON water_records(date_time)',
      );
    }

    // Migration from v3 to v4: Add weight_records table
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS weight_records (
          id TEXT PRIMARY KEY,
          date_time INTEGER NOT NULL,
          weight REAL NOT NULL,
          note TEXT
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_weight_date ON weight_records(date_time)',
      );
    }

    // Migration from v4 to v5: Add sleep_records table
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sleep_records (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          bed_time INTEGER NOT NULL,
          wake_time INTEGER NOT NULL,
          quality INTEGER,
          notes TEXT,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sleep_date ON sleep_records(date)',
      );
    }

    // Migration from v5 to v6: Add avatar_url to users table
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE users ADD COLUMN avatar_url TEXT');
    }
  }

  // ==================== USER OPERATIONS ====================

  /// Insert or update user profile
  static Future<int> saveUser(UserProfile user) async {
    final db = await database;
    final existing = await getUser();

    if (existing != null) {
      return await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      return await db.insert('users', user.toMap());
    }
  }

  /// Get current user profile
  static Future<UserProfile?> getUser() async {
    final db = await database;
    final results = await db.query('users', limit: 1);

    if (results.isEmpty) return null;
    return UserProfile.fromMap(results.first);
  }

  /// Check if user exists
  static Future<bool> hasUser() async {
    final user = await getUser();
    return user != null;
  }

  // ==================== CALO RECORD OPERATIONS ====================

  /// Get calorie record for a specific date
  static Future<CaloRecord> getCaloRecord(String date) async {
    final db = await database;
    final results = await db.query(
      'calo_records',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (results.isEmpty) {
      return CaloRecord.empty(date);
    }
    return CaloRecord.fromMap(results.first);
  }

  /// Get today's calorie record
  static Future<CaloRecord> getTodayRecord() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return await getCaloRecord(dateStr);
  }

  /// Update calorie record (upsert)
  static Future<void> updateCaloRecord(CaloRecord record) async {
    final db = await database;
    await db.insert(
      'calo_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get calorie records for date range (for charts)
  static Future<List<CaloRecord>> getCaloRecordsRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

    final results = await db.query(
      'calo_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC',
    );

    return results.map((m) => CaloRecord.fromMap(m)).toList();
  }

  // ==================== MEAL OPERATIONS ====================

  /// Insert a meal and update daily record
  static Future<void> insertMeal(Meal meal) async {
    final db = await database;

    // Insert meal
    await db.insert('meals', meal.toMap());

    // Update daily calorie record
    final record = await getCaloRecord(meal.dateStr);
    final updatedRecord = record.addIntake(meal.calories);
    await updateCaloRecord(updatedRecord);
  }

  /// Get meals for a specific date
  static Future<List<Meal>> getMealsForDate(String date) async {
    final db = await database;

    // Parse date string to get day boundaries
    final parts = date.split('-');
    final dayStart = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    final results = await db.query(
      'meals',
      where: 'date_time >= ? AND date_time < ?',
      whereArgs: [
        dayStart.millisecondsSinceEpoch,
        dayEnd.millisecondsSinceEpoch,
      ],
      orderBy: 'date_time DESC',
    );

    return results.map((m) => Meal.fromMap(m)).toList();
  }

  /// Get today's meals
  static Future<List<Meal>> getTodayMeals() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return await getMealsForDate(dateStr);
  }

  /// Delete a meal
  static Future<void> deleteMeal(String id) async {
    final db = await database;

    // Get meal first to update record
    final results = await db.query('meals', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      final meal = Meal.fromMap(results.first);

      // Delete meal
      await db.delete('meals', where: 'id = ?', whereArgs: [id]);

      // Update daily record
      final record = await getCaloRecord(meal.dateStr);
      final updated = record.copyWith(
        caloIntake: record.caloIntake - meal.calories,
        netCalo: (record.caloIntake - meal.calories) - record.caloBurned,
      );
      await updateCaloRecord(updated);
    }
  }

  // ==================== GYM SESSION OPERATIONS ====================

  /// Insert gym session
  static Future<void> insertGymSession(GymSession session) async {
    final db = await database;
    await db.insert('gym_sessions', session.toMap());
  }

  /// Get upcoming gym sessions for today
  static Future<List<GymSession>> getTodayGymSessions() async {
    final db = await database;
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final results = await db.query(
      'gym_sessions',
      where: 'scheduled_time >= ? AND scheduled_time < ?',
      whereArgs: [
        dayStart.millisecondsSinceEpoch,
        dayEnd.millisecondsSinceEpoch,
      ],
      orderBy: 'scheduled_time ASC',
    );

    return results.map((m) => GymSession.fromMap(m)).toList();
  }

  /// Get next upcoming gym session
  static Future<GymSession?> getNextGymSession() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final results = await db.query(
      'gym_sessions',
      where: 'scheduled_time >= ? AND is_completed = 0',
      whereArgs: [now],
      orderBy: 'scheduled_time ASC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return GymSession.fromMap(results.first);
  }

  /// Complete gym session and update calories burned
  static Future<void> completeGymSession(String id) async {
    final db = await database;

    // Get session
    final results = await db.query(
      'gym_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      final session = GymSession.fromMap(results.first);
      final completed = session.complete();

      // Update session
      await db.update(
        'gym_sessions',
        completed.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      // Update daily calories burned
      final record = await getCaloRecord(session.dateStr);
      final updated = record.addBurned(session.estimatedCalories);
      await updateCaloRecord(updated);
    }
  }

  /// Delete gym session
  static Future<void> deleteGymSession(String id) async {
    final db = await database;
    await db.delete('gym_sessions', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CHAT HISTORY OPERATIONS ====================

  /// Insert chat message
  static Future<void> insertChatMessage(ChatMessage message) async {
    final db = await database;
    await db.insert('chat_history', message.toMap());
  }

  /// Get chat history (paginated)
  static Future<List<ChatMessage>> getChatHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final results = await db.query(
      'chat_history',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return results
        .map((m) => ChatMessage.fromMap(m))
        .toList()
        .reversed
        .toList();
  }

  /// Get today's chat history
  static Future<List<ChatMessage>> getTodayChatHistory() async {
    final db = await database;
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);

    final results = await db.query(
      'chat_history',
      where: 'timestamp >= ?',
      whereArgs: [dayStart.millisecondsSinceEpoch],
      orderBy: 'timestamp ASC',
    );

    return results.map((m) => ChatMessage.fromMap(m)).toList();
  }

  /// Clear all chat history
  static Future<void> clearChatHistory() async {
    final db = await database;
    await db.delete('chat_history');
  }

  // ==================== WATER RECORD OPERATIONS ====================

  /// Insert water record
  static Future<void> insertWaterRecord(WaterRecord record) async {
    final db = await database;
    await db.insert('water_records', record.toMap());
  }

  /// Get water records for a specific date
  static Future<List<WaterRecord>> getWaterRecordsForDate(String date) async {
    final db = await database;

    // Parse date string to get day boundaries
    final parts = date.split('-');
    final dayStart = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    final results = await db.query(
      'water_records',
      where: 'date_time >= ? AND date_time < ?',
      whereArgs: [
        dayStart.millisecondsSinceEpoch,
        dayEnd.millisecondsSinceEpoch,
      ],
      orderBy: 'date_time DESC',
    );

    return results.map((m) => WaterRecord.fromMap(m)).toList();
  }

  /// Get today's water records
  static Future<List<WaterRecord>> getTodayWaterRecords() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return await getWaterRecordsForDate(dateStr);
  }

  /// Delete water record
  static Future<void> deleteWaterRecord(String id) async {
    final db = await database;
    await db.delete('water_records', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all water records
  static Future<List<WaterRecord>> getAllWaterRecords() async {
    final db = await database;
    final results = await db.query('water_records', orderBy: 'date_time DESC');
    return results.map((m) => WaterRecord.fromMap(m)).toList();
  }

  /// Get total water intake for today
  static Future<int> getTodayWaterTotal() async {
    final db = await database;
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM water_records WHERE date_time >= ? AND date_time < ?',
      [dayStart.millisecondsSinceEpoch, dayEnd.millisecondsSinceEpoch],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  // ==================== WEIGHT RECORD OPERATIONS ====================

  /// Insert weight record
  static Future<void> insertWeightRecord(WeightRecord record) async {
    final db = await database;
    await db.insert('weight_records', record.toMap());
  }

  /// Get latest weight record
  static Future<WeightRecord?> getLatestWeightRecord() async {
    final db = await database;
    final results = await db.query(
      'weight_records',
      orderBy: 'date_time DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return WeightRecord.fromMap(results.first);
  }

  /// Get all weight records
  static Future<List<WeightRecord>> getAllWeightRecords() async {
    final db = await database;
    final results = await db.query('weight_records', orderBy: 'date_time DESC');
    return results.map((m) => WeightRecord.fromMap(m)).toList();
  }

  /// Get weight records for date range
  static Future<List<WeightRecord>> getWeightRecordsRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final results = await db.query(
      'weight_records',
      where: 'date_time >= ? AND date_time <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date_time ASC',
    );
    return results.map((m) => WeightRecord.fromMap(m)).toList();
  }

  /// Delete weight record
  static Future<void> deleteWeightRecord(String id) async {
    final db = await database;
    await db.delete('weight_records', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SLEEP RECORD OPERATIONS ====================

  /// Insert sleep record
  static Future<void> insertSleepRecord(SleepRecord record) async {
    final db = await database;
    await db.insert('sleep_records', record.toMap());
  }

  /// Update sleep record
  static Future<void> updateSleepRecord(SleepRecord record) async {
    final db = await database;
    await db.update(
      'sleep_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// Get sleep record for a specific date
  static Future<SleepRecord?> getSleepRecordForDate(String date) async {
    final db = await database;
    final results = await db.query(
      'sleep_records',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return SleepRecord.fromMap(results.first);
  }

  /// Get today's sleep record
  static Future<SleepRecord?> getTodaySleepRecord() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return await getSleepRecordForDate(dateStr);
  }

  /// Get last night's sleep record (yesterday's date)
  static Future<SleepRecord?> getLastNightSleepRecord() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dateStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    return await getSleepRecordForDate(dateStr);
  }

  /// Get sleep records for date range
  static Future<List<SleepRecord>> getSleepRecordsRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

    final results = await db.query(
      'sleep_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC',
    );

    return results.map((m) => SleepRecord.fromMap(m)).toList();
  }

  /// Get all sleep records
  static Future<List<SleepRecord>> getAllSleepRecords() async {
    final db = await database;
    final results = await db.query('sleep_records', orderBy: 'date DESC');
    return results.map((m) => SleepRecord.fromMap(m)).toList();
  }

  /// Get sleep records for the last N days
  static Future<List<SleepRecord>> getRecentSleepRecords(int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return await getSleepRecordsRange(start, end);
  }

  /// Delete sleep record
  static Future<void> deleteSleepRecord(String id) async {
    final db = await database;
    await db.delete('sleep_records', where: 'id = ?', whereArgs: [id]);
  }

  /// Get average sleep duration for last N days
  static Future<double> getAverageSleepDuration(int days) async {
    final records = await getRecentSleepRecords(days);
    if (records.isEmpty) return 0;

    final totalHours = records.fold<double>(
      0,
      (sum, record) => sum + record.durationHours,
    );
    return totalHours / records.length;
  }

  // ==================== STATISTICS ====================

  /// Get total statistics
  static Future<Map<String, dynamic>> getStats() async {
    final db = await database;

    final totalMeals =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM meals'),
        ) ??
        0;

    final totalSessions =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM gym_sessions WHERE is_completed = 1',
          ),
        ) ??
        0;

    final totalDays =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM calo_records'),
        ) ??
        0;

    return {
      'totalMeals': totalMeals,
      'totalSessions': totalSessions,
      'totalDays': totalDays,
    };
  }

  /// Close database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Get daily macros (protein, carbs, fat, calories) from today's meals
  static Future<Map<String, double>> getDailyMacros() async {
    final meals = await getTodayMeals();
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double calories = 0;
    for (final meal in meals) {
      protein += meal.protein ?? 0;
      carbs += meal.carbs ?? 0;
      fat += meal.fat ?? 0;
      calories += meal.calories;
    }
    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calories': calories,
    };
  }

  /// Get all meals
  static Future<List<Meal>> getAllMeals() async {
    final db = await database;
    final results = await db.query('meals', orderBy: 'date_time DESC');
    return results.map((m) => Meal.fromMap(m)).toList();
  }

  /// Get all gym sessions
  static Future<List<GymSession>> getAllGymSessions() async {
    final db = await database;
    final results = await db.query(
      'gym_sessions',
      orderBy: 'scheduled_time DESC',
    );
    return results.map((m) => GymSession.fromMap(m)).toList();
  }

  /// Clear all data from database
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('meals');
    await db.delete('gym_sessions');
    await db.delete('calo_records');
    await db.delete('chat_history');
    await db.delete('water_records');
    await db.delete('weight_records');
    await db.delete('sleep_records');
    await db.delete('users');
  }
}
