import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sleep_record.dart';
import '../models/sleep_goal.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sleep_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 수면 기록 테이블
    await db.execute('''
      CREATE TABLE sleep_records (
        id TEXT PRIMARY KEY,
        sleep_time INTEGER NOT NULL,
        wake_time INTEGER NOT NULL,
        quality INTEGER NOT NULL,
        factors TEXT NOT NULL,
        note TEXT NOT NULL
      )
    ''');

    // 수면 목표 테이블
    await db.execute('''
      CREATE TABLE sleep_goals (
        id INTEGER PRIMARY KEY,
        target_sleep_time INTEGER NOT NULL,
        target_wake_time INTEGER NOT NULL,
        target_duration INTEGER NOT NULL
      )
    ''');
  }

  // 수면 기록 관련 메서드들
  Future<void> insertSleepRecord(SleepRecord record) async {
    final db = await database;
    await db.insert(
      'sleep_records',
      {
        'id': record.id,
        'sleep_time': record.sleepTime.millisecondsSinceEpoch,
        'wake_time': record.wakeTime.millisecondsSinceEpoch,
        'quality': record.quality,
        'factors': record.factors.join(','),
        'note': record.note,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SleepRecord>> getAllSleepRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sleep_records',
      orderBy: 'sleep_time DESC',
    );

    return List.generate(maps.length, (i) {
      return SleepRecord(
        id: maps[i]['id'],
        sleepTime: DateTime.fromMillisecondsSinceEpoch(maps[i]['sleep_time']),
        wakeTime: DateTime.fromMillisecondsSinceEpoch(maps[i]['wake_time']),
        quality: maps[i]['quality'],
        factors: maps[i]['factors'].toString().isEmpty
            ? <String>[]
            : maps[i]['factors'].toString().split(','),
        note: maps[i]['note'],
      );
    });
  }

  Future<void> updateSleepRecord(SleepRecord record) async {
    final db = await database;
    await db.update(
      'sleep_records',
      {
        'sleep_time': record.sleepTime.millisecondsSinceEpoch,
        'wake_time': record.wakeTime.millisecondsSinceEpoch,
        'quality': record.quality,
        'factors': record.factors.join(','),
        'note': record.note,
      },
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteSleepRecord(String id) async {
    final db = await database;
    await db.delete(
      'sleep_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 수면 목표 관련 메서드들
  Future<void> insertOrUpdateSleepGoal(SleepGoal goal) async {
    final db = await database;

    // 기존 목표 삭제 (하나만 유지)
    await db.delete('sleep_goals');

    // 새 목표 추가
    await db.insert(
      'sleep_goals',
      {
        'target_sleep_time': goal.targetSleepTime.millisecondsSinceEpoch,
        'target_wake_time': goal.targetWakeTime.millisecondsSinceEpoch,
        'target_duration': goal.targetDuration.inMilliseconds,
      },
    );
  }

  Future<SleepGoal?> getSleepGoal() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sleep_goals');

    if (maps.isEmpty) return null;

    final map = maps.first;
    return SleepGoal(
      targetSleepTime:
          DateTime.fromMillisecondsSinceEpoch(map['target_sleep_time']),
      targetWakeTime:
          DateTime.fromMillisecondsSinceEpoch(map['target_wake_time']),
      targetDuration: Duration(milliseconds: map['target_duration']),
    );
  }

  // 데이터베이스 닫기
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
