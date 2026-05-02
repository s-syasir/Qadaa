import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class StreakNotifier {
  StreakNotifier._();
  static final StreakNotifier instance = StreakNotifier._();

  static const _channelId = 'ch_streak';
  static const _notificationId = 200;
  static const _tomorrowNotificationId = 201;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          'Streak Reminders',
          description: 'Daily streak reminder at 9 PM',
          importance: Importance.low,
        ));
    _initialized = true;
  }

  /// Schedules (or cancels) the 9 PM streak alert for today, and pre-schedules
  /// a fallback for tomorrow so the user gets notified even if the app isn't opened.
  ///
  /// [streak] — current streak count
  /// [prayersRemainingToday] — how many of the 5 haven't been logged yet
  Future<void> reschedule({
    required int streak,
    required int prayersRemainingToday,
  }) async {
    await init();
    await _plugin.cancel(_notificationId);
    await _plugin.cancel(_tomorrowNotificationId);

    final now = DateTime.now();
    final ninepm = DateTime(now.year, now.month, now.day, 21, 0);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Streak Reminders',
        channelDescription: 'Daily streak reminder at 9 PM',
        importance: Importance.low,
        priority: Priority.low,
      ),
    );

    // Schedule today's notification if 9 PM hasn't passed yet and streak >= 3
    if (!ninepm.isBefore(now) && streak >= 3) {
      String title;
      String body;
      if (prayersRemainingToday == 0 && streak >= 7) {
        title = '🔥 Day $streak complete';
        body = 'All 5 prayers done. Keep the streak alive!';
      } else if (prayersRemainingToday > 0) {
        title = 'Don\'t break your $streak-day streak';
        body = '$prayersRemainingToday prayer${prayersRemainingToday > 1 ? 's' : ''} left today.';
      } else {
        // streak < 7 and all done — no noise
        title = '';
        body = '';
      }
      if (title.isNotEmpty) {
        await _plugin.zonedSchedule(
          _notificationId,
          title,
          body,
          tz.TZDateTime.from(ninepm, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    // Always pre-schedule tomorrow as a generic reminder if streak >= 3.
    // When the app opens tomorrow, this gets cancelled and replaced with actual data.
    if (streak >= 3) {
      final tomorrow9pm = DateTime(now.year, now.month, now.day + 1, 21, 0);
      await _plugin.zonedSchedule(
        _tomorrowNotificationId,
        'Log your prayers today',
        'Keep your $streak-day streak alive.',
        tz.TZDateTime.from(tomorrow9pm, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancel() async {
    await init();
    await _plugin.cancel(_notificationId);
    await _plugin.cancel(_tomorrowNotificationId);
  }
}
