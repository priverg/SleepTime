class SleepStats {
  final Duration averageSleep;
  final double averageQuality;
  final Map<String, double> factorImpact; // 예: {"카페인": -1.3}

  SleepStats({
    required this.averageSleep,
    required this.averageQuality,
    required this.factorImpact,
  });
}
