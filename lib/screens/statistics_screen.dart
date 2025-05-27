import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/sleep_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<SleepProvider>(
        builder: (context, sleepProvider, child) {
          final records = sleepProvider.sleepRecords;
          final stats = sleepProvider.calculateStats();

          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('통계를 보려면 수면 기록이 필요합니다'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 평균 통계
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '전체 평균',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              context,
                              '수면 시간',
                              '${stats.averageSleep.inHours}시간 ${stats.averageSleep.inMinutes % 60}분',
                              Icons.bedtime,
                            ),
                            _buildStatItem(
                              context,
                              '수면 질',
                              '${stats.averageQuality.toStringAsFixed(1)}/5',
                              Icons.star,
                            ),
                            _buildStatItem(
                              context,
                              '총 기록',
                              '${records.length}일',
                              Icons.calendar_today,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 수면 시간 차트
                Text(
                  '최근 7일 수면 시간',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 200,
                      child: LineChart(
                        _createSleepDurationChart(
                            sleepProvider.getRecentRecords(7)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 수면 질 차트
                Text(
                  '최근 7일 수면 질',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 200,
                      child: LineChart(
                        _createSleepQualityChart(
                            sleepProvider.getRecentRecords(7)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 요인별 영향
                if (stats.factorImpact.isNotEmpty) ...[
                  Text(
                    '요인별 수면 질 영향',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: stats.factorImpact.entries
                            .map((entry) => _buildFactorImpactItem(
                                  context,
                                  entry.key,
                                  entry.value,
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  LineChartData _createSleepDurationChart(List records) {
    final spots = <FlSpot>[];

    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      final hours = record.sleepDuration.inMinutes / 60.0;
      spots.add(FlSpot(i.toDouble(), hours));
    }

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < records.length) {
                final record = records[value.toInt()];
                return Text(
                    '${record.sleepTime.month}/${record.sleepTime.day}');
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text('${value.toStringAsFixed(1)}h');
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }

  LineChartData _createSleepQualityChart(List records) {
    final spots = <FlSpot>[];

    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      spots.add(FlSpot(i.toDouble(), record.quality.toDouble()));
    }

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < records.length) {
                final record = records[value.toInt()];
                return Text(
                    '${record.sleepTime.month}/${record.sleepTime.day}');
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text('${value.toInt()}');
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      minY: 1,
      maxY: 5,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }

  Widget _buildFactorImpactItem(
      BuildContext context, String factor, double impact) {
    final isPositive = impact > 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(factor),
          ),
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '${impact.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
