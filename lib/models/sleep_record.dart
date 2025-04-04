import 'package:uuid/uuid.dart';

class SleepRecord {
  final String id;
  final DateTime sleepTime;
  final DateTime wakeTime;
  final int quality; // 수면의 질 1~5
  final List<String> factors; // ["카페인", "운동", ...]
  final String note;

  SleepRecord(
      {String? id,
      required this.sleepTime,
      required this.wakeTime,
      required this.quality,
      required this.factors,
      required this.note})
      : id = id ?? const Uuid().v4();

  Duration get sleepDuration => wakeTime.difference(sleepTime);
}
