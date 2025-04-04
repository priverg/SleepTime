class SleepGoal {
  final DateTime targetSleepTime;
  final DateTime targetWakeTime;
  final Duration targetDuration;

  SleepGoal({
    required this.targetSleepTime,
    required this.targetWakeTime,
    required this.targetDuration,
  });

  bool isWithinGoal(DateTime sleep, DateTime wake) {
    final actualDuration = wake.difference(sleep);
    return actualDuration >= targetDuration &&
        sleep.hour == targetSleepTime.hour &&
        wake.hour == targetWakeTime.hour;
  }
}
