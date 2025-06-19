import 'package:flutter/material.dart';
import '../models/sleep_record.dart';
import '../models/sleep_goal.dart';
import '../models/sleep_stats.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class SleepProvider extends ChangeNotifier {
  List<SleepRecord> _sleepRecords = [];
  SleepGoal? _sleepGoal;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
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

      // 알림 서비스 초기화
      await _notificationService.init();
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

  Future<void> setSleepGoal(SleepGoal goal, {bool updateAlarms = true}) async {
    try {
      await _databaseHelper.insertOrUpdateSleepGoal(goal);
      _sleepGoal = goal;

      // 목표가 설정되면 자동으로 알람도 업데이트 (선택적)
      if (updateAlarms) {
        await _updateAlarmsForNewGoal(goal);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('수면 목표 저장 오류: $e');
      rethrow;
    }
  }

  Future<void> _updateAlarmsForNewGoal(SleepGoal goal) async {
    try {
      // 기존 알람이 있는지 확인
      final hasExistingAlarms = await _notificationService.isAlarmActive(
            NotificationService.BEDTIME_REMINDER_ID,
          ) ||
          await _notificationService.isAlarmActive(
            NotificationService.WAKE_UP_NOTIFICATION_ID,
          );

      // 기존 알람이 있으면 새로운 목표 시간으로 업데이트
      if (hasExistingAlarms) {
        await _notificationService.scheduleSleepAlarms(
          goal,
          enableBedtimeReminder: true,
          enableWakeUpAlarm: true,
          bedtimeReminderMinutes: 30,
        );
        debugPrint('수면 목표 변경으로 알람이 자동 업데이트되었습니다.');
      }
    } catch (e) {
      debugPrint('알람 자동 업데이트 오류: $e');
    }
  }

  // 알람 관련 편의 메서드들
  Future<void> enableSleepAlarms({
    bool bedtimeReminder = true,
    bool wakeUpAlarm = true,
    int bedtimeReminderMinutes = 30,
  }) async {
    if (_sleepGoal == null) {
      throw Exception('수면 목표를 먼저 설정해주세요.');
    }

    try {
      await _notificationService.scheduleSleepAlarms(
        _sleepGoal!,
        enableBedtimeReminder: bedtimeReminder,
        enableWakeUpAlarm: wakeUpAlarm,
        bedtimeReminderMinutes: bedtimeReminderMinutes,
      );
    } catch (e) {
      debugPrint('알람 설정 오류: $e');
      rethrow;
    }
  }

  Future<void> disableAllAlarms() async {
    try {
      await _notificationService.cancelAllSleepAlarms();
    } catch (e) {
      debugPrint('알람 취소 오류: $e');
      rethrow;
    }
  }

  Future<bool> isBedtimeReminderActive() async {
    return await _notificationService.isAlarmActive(
      NotificationService.BEDTIME_REMINDER_ID,
    );
  }

  Future<bool> isWakeUpAlarmActive() async {
    return await _notificationService.isAlarmActive(
      NotificationService.WAKE_UP_NOTIFICATION_ID,
    );
  }

  SleepStats calculateStats() {
    if (_sleepRecords.isEmpty) {
      return SleepStats(
        averageSleep: Duration.zero,
        averageQuality: 0.0,
        factorImpact: {},
      );
    }

    final totalDuration = _sleepRecords.fold<Duration>(
      Duration.zero,
      (prev, record) => prev + record.sleepDuration,
    );
    final averageSleep = Duration(
      milliseconds: totalDuration.inMilliseconds ~/ _sleepRecords.length,
    );

    final totalQuality = _sleepRecords.fold<int>(
      0,
      (prev, record) => prev + record.quality,
    );
    final averageQuality = totalQuality / _sleepRecords.length;

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

  // 스마트 알람 추천 기능
  Map<String, dynamic> getSmartAlarmRecommendation() {
    if (_sleepRecords.isEmpty || _sleepGoal == null) {
      return {
        'recommendation': '데이터가 부족합니다',
        'bedtimeAdjustment': 0,
        'wakeTimeAdjustment': 0,
        'confidence': 0.0,
      };
    }

    final recentRecords = getRecentRecords(14); // 최근 2주 데이터
    if (recentRecords.length < 5) {
      return {
        'recommendation': '더 많은 수면 데이터가 필요합니다',
        'bedtimeAdjustment': 0,
        'wakeTimeAdjustment': 0,
        'confidence': 0.0,
      };
    }

    // 평균 수면 시간 계산
    final avgSleepDuration = Duration(
      milliseconds: recentRecords.fold<int>(0,
              (prev, record) => prev + record.sleepDuration.inMilliseconds) ~/
          recentRecords.length,
    );

    // 평균 수면 품질 계산
    final avgQuality =
        recentRecords.fold<double>(0, (prev, record) => prev + record.quality) /
            recentRecords.length;

    // 목표와 실제 수면 시간 차이 분석
    final targetDuration = _sleepGoal!.targetDuration;
    final durationDiff = avgSleepDuration.inMinutes - targetDuration.inMinutes;

    String recommendation = '';
    int bedtimeAdjustment = 0;
    int wakeTimeAdjustment = 0;
    double confidence = 0.0;

    if (avgQuality >= 8.0 && durationDiff.abs() <= 15) {
      recommendation = '현재 수면 패턴이 매우 좋습니다! 현재 목표를 유지하세요.';
      confidence = 0.9;
    } else if (avgQuality < 6.0) {
      if (durationDiff < -30) {
        recommendation = '수면 시간이 부족합니다. 더 일찍 잠자리에 드시는 것을 권장합니다.';
        bedtimeAdjustment = -30; // 30분 일찍 취침
        confidence = 0.8;
      } else if (durationDiff > 60) {
        recommendation = '수면 시간은 충분하지만 품질이 낮습니다. 수면 환경을 점검해보세요.';
        confidence = 0.7;
      } else {
        recommendation = '수면의 질을 개선하기 위해 취침 시간을 조정해보세요.';
        bedtimeAdjustment = -15; // 15분 일찍 취침
        confidence = 0.6;
      }
    } else if (durationDiff < -30) {
      recommendation = '수면 시간이 부족합니다. 취침 시간을 앞당기거나 기상 시간을 늦춰보세요.';
      bedtimeAdjustment = -20;
      confidence = 0.7;
    } else if (durationDiff > 60) {
      recommendation = '수면 시간이 너무 깁니다. 취침 시간을 늦추거나 기상 시간을 앞당겨보세요.';
      wakeTimeAdjustment = -15;
      confidence = 0.7;
    } else {
      recommendation = '현재 수면 패턴이 양호합니다. 일관성을 유지하세요.';
      confidence = 0.8;
    }

    return {
      'recommendation': recommendation,
      'bedtimeAdjustment': bedtimeAdjustment, // 분 단위 (음수: 더 일찍, 양수: 더 늦게)
      'wakeTimeAdjustment': wakeTimeAdjustment,
      'confidence': confidence,
      'avgQuality': avgQuality,
      'avgDuration': avgSleepDuration,
      'targetDuration': targetDuration,
    };
  }
}
