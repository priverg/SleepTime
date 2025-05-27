import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import 'add_sleep_screen.dart';
import 'statistics_screen.dart';
import 'sleep_list_screen.dart';
import 'goal_setting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardTab(),
      const SleepListScreen(),
      const StatisticsScreen(),
      const GoalSettingScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '수면 기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '통계',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: '목표',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddSleepScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수면 트래커'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<SleepProvider>(
        builder: (context, sleepProvider, child) {
          if (sleepProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final recentRecords = sleepProvider.getRecentRecords(7);
          final stats = sleepProvider.calculateStats();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 오늘의 수면 요약
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '최근 7일 평균',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  Icons.bedtime,
                                  size: 32,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${stats.averageSleep.inHours}시간 ${stats.averageSleep.inMinutes % 60}분',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const Text('평균 수면시간'),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 32,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${stats.averageQuality.toStringAsFixed(1)}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const Text('평균 수면질'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 최근 기록
                Text(
                  '최근 기록',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: recentRecords.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bedtime, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('아직 수면 기록이 없습니다'),
                              Text('+ 버튼을 눌러 첫 기록을 추가해보세요'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: recentRecords.length > 3
                              ? 3
                              : recentRecords.length,
                          itemBuilder: (context, index) {
                            final record = recentRecords[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${record.quality}'),
                                ),
                                title: Text(
                                  '${record.sleepDuration.inHours}시간 ${record.sleepDuration.inMinutes % 60}분',
                                ),
                                subtitle: Text(
                                  '${record.sleepTime.month}/${record.sleepTime.day} ${record.sleepTime.hour}:${record.sleepTime.minute.toString().padLeft(2, '0')} - ${record.wakeTime.hour}:${record.wakeTime.minute.toString().padLeft(2, '0')}',
                                ),
                                trailing: record.factors.isNotEmpty
                                    ? Chip(
                                        label: Text(
                                            '${record.factors.length}개 요인'),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
