import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sleep_goal.dart';
import '../providers/sleep_provider.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  TimeOfDay _targetSleepTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _targetWakeTime = const TimeOfDay(hour: 7, minute: 0);
  int _targetHours = 8;
  int _targetMinutes = 0;

  @override
  void initState() {
    super.initState();
    final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
    final existingGoal = sleepProvider.sleepGoal;

    if (existingGoal != null) {
      _targetSleepTime = TimeOfDay.fromDateTime(existingGoal.targetSleepTime);
      _targetWakeTime = TimeOfDay.fromDateTime(existingGoal.targetWakeTime);
      _targetHours = existingGoal.targetDuration.inHours;
      _targetMinutes = existingGoal.targetDuration.inMinutes % 60;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수면 목표'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<SleepProvider>(
        builder: (context, sleepProvider, child) {
          final currentGoal = sleepProvider.sleepGoal;
          final recentRecords = sleepProvider.getRecentRecords(7);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 현재 목표 요약
                if (currentGoal != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '현재 수면 목표',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildGoalItem(
                                '취침 시간',
                                '${_targetSleepTime.hour}:${_targetSleepTime.minute.toString().padLeft(2, '0')}',
                                Icons.bedtime,
                              ),
                              _buildGoalItem(
                                '기상 시간',
                                '${_targetWakeTime.hour}:${_targetWakeTime.minute.toString().padLeft(2, '0')}',
                                Icons.wb_sunny,
                              ),
                              _buildGoalItem(
                                '목표 수면',
                                '${_targetHours}시간 ${_targetMinutes}분',
                                Icons.timer,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 목표 달성도
                  if (recentRecords.isNotEmpty) ...[
                    Text(
                      '최근 7일 목표 달성도',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildAchievementRate(recentRecords, currentGoal),
                            const SizedBox(height: 16),
                            _buildAchievementList(recentRecords, currentGoal),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],

                // 목표 설정
                Text(
                  '목표 설정',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // 취침 시간 설정
                        ListTile(
                          leading: const Icon(Icons.bedtime),
                          title: const Text('목표 취침 시간'),
                          subtitle: Text(
                            '${_targetSleepTime.hour}:${_targetSleepTime.minute.toString().padLeft(2, '0')}',
                          ),
                          onTap: () => _selectTime(context, true),
                        ),
                        const Divider(),

                        // 기상 시간 설정
                        ListTile(
                          leading: const Icon(Icons.wb_sunny),
                          title: const Text('목표 기상 시간'),
                          subtitle: Text(
                            '${_targetWakeTime.hour}:${_targetWakeTime.minute.toString().padLeft(2, '0')}',
                          ),
                          onTap: () => _selectTime(context, false),
                        ),
                        const Divider(),

                        // 수면 시간 설정
                        ListTile(
                          leading: const Icon(Icons.timer),
                          title: const Text('목표 수면 시간'),
                          subtitle:
                              Text('${_targetHours}시간 ${_targetMinutes}분'),
                        ),
                        Row(
                          children: [
                            const Text('시간: '),
                            Expanded(
                              child: Slider(
                                value: _targetHours.toDouble(),
                                min: 4,
                                max: 12,
                                divisions: 8,
                                label: '${_targetHours}시간',
                                onChanged: (value) {
                                  setState(() {
                                    _targetHours = value.round();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('분: '),
                            Expanded(
                              child: Slider(
                                value: _targetMinutes.toDouble(),
                                min: 0,
                                max: 45,
                                divisions: 3,
                                label: '${_targetMinutes}분',
                                onChanged: (value) {
                                  setState(() {
                                    _targetMinutes = value.round();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),

                // 저장 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveGoal,
                    child: const Text('목표 저장'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAchievementRate(List records, SleepGoal goal) {
    int achievedDays = 0;
    for (final record in records) {
      if (goal.isWithinGoal(record.sleepTime, record.wakeTime)) {
        achievedDays++;
      }
    }

    final rate = records.isEmpty ? 0.0 : achievedDays / records.length;

    return Column(
      children: [
        CircularProgressIndicator(
          value: rate,
          strokeWidth: 8,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            rate >= 0.7
                ? Colors.green
                : rate >= 0.4
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(rate * 100).round()}% 달성',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('${achievedDays}일 / ${records.length}일'),
      ],
    );
  }

  Widget _buildAchievementList(List records, SleepGoal goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('최근 기록:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...records.take(5).map((record) {
          final achieved = goal.isWithinGoal(record.sleepTime, record.wakeTime);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Icon(
                  achieved ? Icons.check_circle : Icons.cancel,
                  color: achieved ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${record.sleepTime.month}/${record.sleepTime.day}',
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${record.sleepDuration.inHours}시간 ${record.sleepDuration.inMinutes % 60}분',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, bool isSleepTime) async {
    final currentTime = isSleepTime ? _targetSleepTime : _targetWakeTime;

    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (time != null) {
      setState(() {
        if (isSleepTime) {
          _targetSleepTime = time;
        } else {
          _targetWakeTime = time;
        }
      });
    }
  }

  void _saveGoal() {
    final now = DateTime.now();
    final sleepDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _targetSleepTime.hour,
      _targetSleepTime.minute,
    );
    final wakeDateTime = DateTime(
      now.year,
      now.month,
      now.day + 1,
      _targetWakeTime.hour,
      _targetWakeTime.minute,
    );

    final goal = SleepGoal(
      targetSleepTime: sleepDateTime,
      targetWakeTime: wakeDateTime,
      targetDuration: Duration(hours: _targetHours, minutes: _targetMinutes),
    );

    final sleepProvider = Provider.of<SleepProvider>(context, listen: false);
    sleepProvider.setSleepGoal(goal);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('수면 목표가 저장되었습니다.'),
      ),
    );
  }
}
