import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../services/notification_service.dart';
import '../models/sleep_goal.dart';

class AlarmSettingsScreen extends StatefulWidget {
  const AlarmSettingsScreen({super.key});

  @override
  State<AlarmSettingsScreen> createState() => _AlarmSettingsScreenState();
}

class _AlarmSettingsScreenState extends State<AlarmSettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _bedtimeReminderEnabled = true;
  bool _wakeUpAlarmEnabled = true;
  int _bedtimeReminderMinutes = 30;

  bool _isBedtimeAlarmActive = false;
  bool _isWakeUpAlarmActive = false;

  @override
  void initState() {
    super.initState();
    _checkAlarmStatus();
  }

  Future<void> _checkAlarmStatus() async {
    final isBedtimeActive = await _notificationService.isAlarmActive(
      NotificationService.BEDTIME_REMINDER_ID,
    );
    final isWakeUpActive = await _notificationService.isAlarmActive(
      NotificationService.WAKE_UP_NOTIFICATION_ID,
    );

    setState(() {
      _isBedtimeAlarmActive = isBedtimeActive;
      _isWakeUpAlarmActive = isWakeUpActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람 설정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<SleepProvider>(
        builder: (context, sleepProvider, child) {
          final sleepGoal = sleepProvider.sleepGoal;

          if (sleepGoal == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alarm_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '먼저 수면 목표를 설정해주세요',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 현재 수면 목표 표시
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
                              _buildTimeInfo(
                                '취침 시간',
                                TimeOfDay.fromDateTime(
                                    sleepGoal.targetSleepTime),
                                Icons.bedtime,
                                Colors.deepPurple,
                              ),
                              _buildTimeInfo(
                                '기상 시간',
                                TimeOfDay.fromDateTime(
                                    sleepGoal.targetWakeTime),
                                Icons.wb_sunny,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 알람 상태 표시
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '알람 상태',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildAlarmStatus(
                                '취침 리마인더',
                                _isBedtimeAlarmActive,
                                Icons.bedtime,
                              ),
                              _buildAlarmStatus(
                                '기상 알람',
                                _isWakeUpAlarmActive,
                                Icons.alarm,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 알람 설정
                  Text(
                    '알람 설정',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('취침 시간 리마인더'),
                            subtitle: Text(
                              _bedtimeReminderEnabled
                                  ? '취침 ${_bedtimeReminderMinutes}분 전에 알림'
                                  : '비활성화됨',
                            ),
                            value: _bedtimeReminderEnabled,
                            onChanged: (value) {
                              setState(() {
                                _bedtimeReminderEnabled = value;
                              });
                            },
                            secondary: const Icon(Icons.bedtime),
                          ),
                          if (_bedtimeReminderEnabled) ...[
                            const Divider(),
                            ListTile(
                              title: const Text('리마인더 시간'),
                              subtitle:
                                  Text('취침 ${_bedtimeReminderMinutes}분 전'),
                              trailing: DropdownButton<int>(
                                value: _bedtimeReminderMinutes,
                                items: [15, 30, 45, 60]
                                    .map((minutes) => DropdownMenuItem(
                                          value: minutes,
                                          child: Text('${minutes}분 전'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _bedtimeReminderMinutes = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                          const Divider(),
                          SwitchListTile(
                            title: const Text('기상 알람'),
                            subtitle: Text(
                              _wakeUpAlarmEnabled
                                  ? '매일 ${TimeOfDay.fromDateTime(sleepGoal.targetWakeTime).format(context)}에 알람'
                                  : '비활성화됨',
                            ),
                            value: _wakeUpAlarmEnabled,
                            onChanged: (value) {
                              setState(() {
                                _wakeUpAlarmEnabled = value;
                              });
                            },
                            secondary: const Icon(Icons.alarm),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 알람 설정 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _saveAlarmSettings(sleepGoal),
                      icon: const Icon(Icons.alarm_add),
                      label: const Text('알람 설정 저장'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 알람 취소 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _cancelAllAlarms,
                      icon: const Icon(Icons.alarm_off),
                      label: const Text('모든 알람 취소'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeInfo(
      String label, TimeOfDay time, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          time.format(context),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAlarmStatus(String label, bool isActive, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.green : Colors.grey,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isActive ? '활성화' : '비활성화',
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.green : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _saveAlarmSettings(SleepGoal sleepGoal) async {
    try {
      await _notificationService.scheduleSleepAlarms(
        sleepGoal,
        enableBedtimeReminder: _bedtimeReminderEnabled,
        enableWakeUpAlarm: _wakeUpAlarmEnabled,
        bedtimeReminderMinutes: _bedtimeReminderMinutes,
      );

      await _checkAlarmStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('알람이 설정되었습니다.'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알람 설정 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelAllAlarms() async {
    try {
      await _notificationService.cancelAllSleepAlarms();
      await _checkAlarmStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 알람이 취소되었습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알람 취소 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
