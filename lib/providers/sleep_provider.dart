import 'package:flutter/material.dart';
import '../models/sleep_record.dart';
import '../models/sleep_goal.dart';
import '../models/sleep_stats.dart';
import '../database/database_helper.dart';

class SleepProvider extends ChangeNotifier {
  List<SleepRecord> _sleepRecords = [];
  SleepGoal? _sleepGoal;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = false;

  List<SleepRecord> get sleepRecords => _sleepRecords;
  SleepGoal? get sleepGoal => _sleepGoal;
  bool get isLoading => _isLoading;

  // 초기 데이터 로드
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sleepRecords = await _databaseHelper.getAllSleepRecords();
      _sleepGoal = await _databaseHelper.getSleepGoal();
    } catch (e) {
      debugPrint('데이터 로드 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSleepRecord(SleepRecord record) async {
    try {
      await _databaseHelper.insertSleepRecord(record);
      _sleepRecords.add(record);
      _sleepRecords.sort((a, b) => b.sleepTime.compareTo(a.sleepTime));
      notifyListeners();
    } catch (e) {
      debugPrint('수면 기록 추가 오류: $e');
      rethrow;
    }
  }

  Future<void> updateSleepRecord(SleepRecord updatedRecord) async {
    try {
      await _databaseHelper.updateSleepRecord(updatedRecord);
      final index =
          _sleepRecords.indexWhere((record) => record.id == updatedRecord.id);
      if (index != -1) {
        _sleepRecords[index] = updatedRecord;
        _sleepRecords.sort((a, b) => b.sleepTime.compareTo(a.sleepTime));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('수면 기록 수정 오류: $e');
      rethrow;
    }
  }

  Future<void> deleteSleepRecord(String id) async {
    try {
      await _databaseHelper.deleteSleepRecord(id);
      _sleepRecords.removeWhere((record) => record.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('수면 기록 삭제 오류: $e');
      rethrow;
    }
  }

  Future<void> setSleepGoal(SleepGoal goal) async {
    try {
      await _databaseHelper.insertOrUpdateSleepGoal(goal);
      _sleepGoal = goal;
      notifyListeners();
    } catch (e) {
      debugPrint('수면 목표 저장 오류: $e');
      rethrow;
    }
  }

  SleepStats calculateStats() {
    if (_sleepRecords.isEmpty) {
      return SleepStats(
        averageSleep: Duration.zero,
        averageQuality: 0.0,
        factorImpact: {},
      );
    }

    // 평균 수면 시간 계산
    final totalDuration = _sleepRecords.fold<Duration>(
      Duration.zero,
      (prev, record) => prev + record.sleepDuration,
    );
    final averageSleep = Duration(
      milliseconds: totalDuration.inMilliseconds ~/ _sleepRecords.length,
    );

    // 평균 수면 질 계산
    final totalQuality = _sleepRecords.fold<int>(
      0,
      (prev, record) => prev + record.quality,
    );
    final averageQuality = totalQuality / _sleepRecords.length;

    // 요인별 영향 계산 (간단한 버전)
    Map<String, double> factorImpact = {};
    for (final factor in ['카페인', '음주', '운동', '스트레스', '늦은 식사']) {
      final withFactor = _sleepRecords.where((r) => r.factors.contains(factor));
      final withoutFactor =
          _sleepRecords.where((r) => !r.factors.contains(factor));

      if (withFactor.isNotEmpty && withoutFactor.isNotEmpty) {
        final avgWithFactor =
            withFactor.fold<double>(0, (prev, r) => prev + r.quality) /
                withFactor.length;
        final avgWithoutFactor =
            withoutFactor.fold<double>(0, (prev, r) => prev + r.quality) /
                withoutFactor.length;
        factorImpact[factor] = avgWithFactor - avgWithoutFactor;
      }
    }

    return SleepStats(
      averageSleep: averageSleep,
      averageQuality: averageQuality,
      factorImpact: factorImpact,
    );
  }

  List<SleepRecord> getRecentRecords([int days = 7]) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _sleepRecords
        .where((record) => record.sleepTime.isAfter(cutoffDate))
        .toList();
  }
}
