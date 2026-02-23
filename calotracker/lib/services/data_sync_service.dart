// Data Sync Service
// Syncs local health data with Supabase cloud
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/config/supabase_config.dart';
import 'database_service.dart';

class DataSyncService {
  static DataSyncService? _instance;

  factory DataSyncService() {
    _instance ??= DataSyncService._();
    return _instance!;
  }

  DataSyncService._();

  final _connectivity = Connectivity();
  bool _isSyncing = false;

  // Check if online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // Check if can sync (authenticated and online)
  bool get canSync =>
      SupabaseConfig.isConfigured && SupabaseConfig.isAuthenticated;

  // Sync all local data to cloud
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Đang đồng bộ...');
    }

    if (!canSync) {
      return SyncResult(success: false, message: 'Chưa đăng nhập');
    }

    final online = await isOnline();
    if (!online) {
      return SyncResult(success: false, message: 'Không có kết nối mạng');
    }

    _isSyncing = true;

    try {
      int synced = 0;

      // Sync calorie records
      synced += await _syncCaloRecords();

      // Sync water records
      synced += await _syncWaterRecords();

      // Sync weight records
      synced += await _syncWeightRecords();

      // Sync sleep records
      synced += await _syncSleepRecords();

      // Sync gym sessions
      synced += await _syncGymSessions();

      return SyncResult(
        success: true,
        message: 'Đã đồng bộ $synced bản ghi',
        recordsSynced: synced,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Lỗi: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Sync calorie records
  Future<int> _syncCaloRecords() async {
    final db = await DatabaseService.database;
    final userId = SupabaseConfig.currentUser!.id;
    final client = SupabaseConfig.client;

    // Get local records not yet synced
    // Group by date for user_health_records
    final records = await db.rawQuery('''
      SELECT 
        date,
        calo_intake,
        calo_burned,
        1 as meals_logged
      FROM calo_records
      WHERE date >= date('now', '-30 days')
    ''');

    int synced = 0;

    for (final record in records) {
      final date = record['date'] as String;
      final intake = (record['calo_intake'] as num?)?.toDouble() ?? 0;
      final burned = (record['calo_burned'] as num?)?.toDouble() ?? 0;
      final mealsLogged = record['meals_logged'] as int? ?? 0;

      await client.from('user_health_records').upsert({
        'user_id': userId,
        'date': date,
        'calo_intake': intake,
        'calo_burned': burned,
        'net_calo': intake - burned,
        'meals_logged': mealsLogged,
        'synced_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');

      synced++;
    }

    return synced;
  }

  // Sync water records
  Future<int> _syncWaterRecords() async {
    final db = await DatabaseService.database;
    final userId = SupabaseConfig.currentUser!.id;
    final client = SupabaseConfig.client;

    final records = await db.rawQuery('''
      SELECT 
        date(date_time / 1000, 'unixepoch', 'localtime') as date,
        SUM(amount) as water_intake
      FROM water_records
      WHERE date(date_time / 1000, 'unixepoch', 'localtime') >= date('now', '-30 days')
      GROUP BY date(date_time / 1000, 'unixepoch', 'localtime')
    ''');

    int synced = 0;

    for (final record in records) {
      final date = record['date'] as String;
      final waterIntake = record['water_intake'] as int? ?? 0;

      await client.from('user_health_records').upsert({
        'user_id': userId,
        'date': date,
        'water_intake': waterIntake,
        'synced_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');

      synced++;
    }

    return synced;
  }

  // Sync weight records
  Future<int> _syncWeightRecords() async {
    final db = await DatabaseService.database;
    final userId = SupabaseConfig.currentUser!.id;
    final client = SupabaseConfig.client;

    final records = await db.rawQuery('''
      SELECT 
        date(date_time / 1000, 'unixepoch', 'localtime') as date,
        AVG(weight) as weight
      FROM weight_records
      WHERE date(date_time / 1000, 'unixepoch', 'localtime') >= date('now', '-30 days')
      GROUP BY date(date_time / 1000, 'unixepoch', 'localtime')
    ''');

    int synced = 0;

    for (final record in records) {
      final date = record['date'] as String;
      final weight = (record['weight'] as num?)?.toDouble();

      if (weight != null) {
        await client.from('user_health_records').upsert({
          'user_id': userId,
          'date': date,
          'weight': weight,
          'synced_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,date');

        synced++;
      }
    }

    return synced;
  }

  // Sync sleep records
  Future<int> _syncSleepRecords() async {
    final db = await DatabaseService.database;
    final userId = SupabaseConfig.currentUser!.id;
    final client = SupabaseConfig.client;

    final records = await db.rawQuery('''
      SELECT 
        date as date,
        AVG((wake_time - bed_time) / 3600000.0) as sleep_hours,
        AVG(quality) as sleep_quality
      FROM sleep_records
      WHERE date >= date('now', '-30 days')
      GROUP BY date
    ''');

    int synced = 0;

    for (final record in records) {
      final date = record['date'] as String;
      final sleepHours = (record['sleep_hours'] as num?)?.toDouble();
      final sleepQuality = (record['sleep_quality'] as num?)?.toInt();

      await client.from('user_health_records').upsert({
        'user_id': userId,
        'date': date,
        'sleep_hours': sleepHours,
        'sleep_quality': sleepQuality,
        'synced_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');

      synced++;
    }

    return synced;
  }

  // Sync gym sessions
  Future<int> _syncGymSessions() async {
    final db = await DatabaseService.database;
    final userId = SupabaseConfig.currentUser!.id;
    final client = SupabaseConfig.client;

    final records = await db.rawQuery('''
      SELECT 
        date(scheduled_time / 1000, 'unixepoch', 'localtime') as date,
        COUNT(*) as workouts_completed
      FROM gym_sessions
      WHERE is_completed = 1 AND date(scheduled_time / 1000, 'unixepoch', 'localtime') >= date('now', '-30 days')
      GROUP BY date(scheduled_time / 1000, 'unixepoch', 'localtime')
    ''');

    int synced = 0;

    for (final record in records) {
      final date = record['date'] as String;
      final workoutsCompleted = record['workouts_completed'] as int? ?? 0;

      await client.from('user_health_records').upsert({
        'user_id': userId,
        'date': date,
        'workouts_completed': workoutsCompleted,
        'synced_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');

      synced++;
    }

    return synced;
  }

  // Sync user profile from local to cloud
  Future<void> syncProfile() async {
    if (!canSync) return;

    final db = await DatabaseService.database;
    final userId = SupabaseConfig.currentUser!.id;
    final client = SupabaseConfig.client;

    // Get local user profile
    final users = await db.query('users', limit: 1);
    if (users.isEmpty) return;

    final localProfile = users.first;

    await client
        .from('profiles')
        .update({
          'display_name': localProfile['name'],
          'height': localProfile['height'],
          'weight': localProfile['weight'],
          'goal': localProfile['goal'],
          'bmr': localProfile['bmr'],
          'daily_target': localProfile['daily_target'],
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // Migrate local user to cloud on first login
  Future<void> migrateLocalData() async {
    if (!canSync) return;

    // First sync profile
    await syncProfile();

    // Then sync all health records
    await syncAll();
  }

  // Get cloud health records for a date range
  Future<List<Map<String, dynamic>>> getCloudRecords({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!canSync) return [];

    final userId = SupabaseConfig.currentUser!.id;
    final client = SupabaseConfig.client;

    final response = await client
        .from('user_health_records')
        .select()
        .eq('user_id', userId)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first)
        .order('date', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  // Get today's aggregated stats from cloud
  Future<Map<String, dynamic>?> getTodayStats() async {
    if (!canSync) return null;

    final userId = SupabaseConfig.currentUser!.id;
    final client = SupabaseConfig.client;
    final today = DateTime.now().toIso8601String().split('T').first;

    final response =
        await client
            .from('user_health_records')
            .select()
            .eq('user_id', userId)
            .eq('date', today)
            .maybeSingle();

    return response;
  }

  // Auto-sync challenge progress when health data changes
  Future<void> syncChallengeProgress() async {
    if (!canSync) return;

    // Get today's stats
    final todayStats = await getTodayStats();
    if (todayStats == null) return;

    // Get active challenges the user is participating in
    final userId = SupabaseConfig.currentUser!.id;
    final client = SupabaseConfig.client;

    final participations = await client
        .from('challenge_participants')
        .select(
          'id, challenge_id, current_value, challenges(challenge_type, target_value)',
        )
        .eq('user_id', userId)
        .eq('is_completed', false);

    for (final p in participations) {
      final challenge = p['challenges'];
      final challengeType = challenge['challenge_type'] as String;

      double todayValue = 0;

      switch (challengeType) {
        case 'calories_burned':
          todayValue = (todayStats['calo_burned'] as num?)?.toDouble() ?? 0;
          break;
        case 'calories_intake':
          todayValue = (todayStats['calo_intake'] as num?)?.toDouble() ?? 0;
          break;
        case 'water_intake':
          todayValue = (todayStats['water_intake'] as num?)?.toDouble() ?? 0;
          break;
        case 'sleep_hours':
          todayValue = (todayStats['sleep_hours'] as num?)?.toDouble() ?? 0;
          break;
        case 'workouts_completed':
          todayValue =
              (todayStats['workouts_completed'] as num?)?.toDouble() ?? 0;
          break;
        case 'meals_logged':
          todayValue = (todayStats['meals_logged'] as num?)?.toDouble() ?? 0;
          break;
      }

      // Update progress if there's new data
      if (todayValue > 0) {
        // Add to daily progress
        final currentValue = (p['current_value'] as num?)?.toDouble() ?? 0;
        final newValue = currentValue + todayValue;
        final targetValue = (challenge['target_value'] as num).toDouble();
        final isCompleted = newValue >= targetValue;

        await client
            .from('challenge_participants')
            .update({
              'current_value': newValue,
              'is_completed': isCompleted,
              'completed_at':
                  isCompleted ? DateTime.now().toIso8601String() : null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', p['id']);
      }
    }
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int recordsSynced;

  SyncResult({
    required this.success,
    required this.message,
    this.recordsSynced = 0,
  });
}
