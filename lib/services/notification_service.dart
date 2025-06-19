import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/sleep_goal.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int BEDTIME_NOTIFICATION_ID = 1;
  static const int WAKE_UP_NOTIFICATION_ID = 2;
  static const int BEDTIME_REMINDER_ID = 3;

  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // 타임존 초기화
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await _flutterLocalNotificationsPlugin!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    await _flutterLocalNotificationsPlugin
        ?.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('알림 탭됨: ${response.payload}');
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized || _flutterLocalNotificationsPlugin == null) {
      throw Exception(
          'NotificationService is not initialized. Call init() first.');
    }
  }

  Future<void> scheduleSleepAlarms(
    SleepGoal goal, {
    bool enableBedtimeReminder = true,
    bool enableWakeUpAlarm = true,
    int bedtimeReminderMinutes = 30,
  }) async {
    await _ensureInitialized();

    await cancelAllSleepAlarms();

    if (enableBedtimeReminder) {
      await _scheduleBedtimeReminder(
          goal.targetSleepTime, bedtimeReminderMinutes);
    }

    if (enableWakeUpAlarm) {
      await _scheduleWakeUpAlarm(goal.targetWakeTime);
    }
  }

  Future<void> _scheduleBedtimeReminder(
    DateTime bedtime,
    int reminderMinutes,
  ) async {
    await _ensureInitialized();

    final now = DateTime.now();
    var reminderTime = bedtime.subtract(Duration(minutes: reminderMinutes));
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'bedtime_channel',
      '취침 알림',
      channelDescription: '취침 시간을 알려주는 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/bedtime_icon',
      sound: RawResourceAndroidNotificationSound('bedtime_sound'),
    );

    const iosDetails = DarwinNotificationDetails(
      sound: 'bedtime_sound.aiff',
      categoryIdentifier: 'bedtime_category',
    );

    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin!.zonedSchedule(
      BEDTIME_REMINDER_ID,
      '🌙 취침 시간이 다가왔어요',
      '${reminderMinutes}분 후 취침 시간입니다. 잠들 준비를 시작하세요!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'bedtime_reminder',
    );
  }

  Future<void> _scheduleWakeUpAlarm(DateTime wakeTime) async {
    await _ensureInitialized();

    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day + 1,
      wakeTime.hour,
      wakeTime.minute,
    );

    const androidDetails = AndroidNotificationDetails(
      'wakeup_channel',
      '기상 알람',
      channelDescription: '기상 시간을 알려주는 알람',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@drawable/alarm_icon',
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      sound: 'alarm_sound.aiff',
      categoryIdentifier: 'alarm_category',
      interruptionLevel: InterruptionLevel.critical,
    );

    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin!.zonedSchedule(
      WAKE_UP_NOTIFICATION_ID,
      '☀️ 기상 시간입니다!',
      '좋은 아침이에요! 상쾌한 하루를 시작하세요.',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'wake_up_alarm',
    );
  }

  Future<void> cancelAllSleepAlarms() async {
    await _ensureInitialized();

    await _flutterLocalNotificationsPlugin!.cancel(BEDTIME_REMINDER_ID);
    await _flutterLocalNotificationsPlugin!.cancel(WAKE_UP_NOTIFICATION_ID);
  }

  Future<void> cancelBedtimeReminder() async {
    await _ensureInitialized();
    await _flutterLocalNotificationsPlugin!.cancel(BEDTIME_REMINDER_ID);
  }

  Future<void> cancelWakeUpAlarm() async {
    await _ensureInitialized();
    await _flutterLocalNotificationsPlugin!.cancel(WAKE_UP_NOTIFICATION_ID);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await _ensureInitialized();
    return await _flutterLocalNotificationsPlugin!
        .pendingNotificationRequests();
  }

  Future<bool> isAlarmActive(int id) async {
    final pendingNotifications = await getPendingNotifications();
    return pendingNotifications.any((n) => n.id == id);
  }
}
