import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/expiry.dart';
import '../../domain/models.dart';
import '../l10n/strings.dart';

/// Lokale, geplande herinneringen (geen server, geen push).
/// Elke keer worden alle meldingen opnieuw gepland: simpel en altijd consistent.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Amsterdam'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Toestemming wordt pas gevraagd bij het instellen van een herinnering.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Vraagt toestemming (Android 13+ / iOS). Geeft terug of meldingen aan staan.
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Plant alle herinneringen opnieuw.
  Future<void> reschedule({
    required List<Item> items,
    required int leadDays,
    required bool semiAnnual,
    DateTime? planReminderAt,
    List<DateTime> vaultReminders = const [],
  }) async {
    await init();
    await _plugin.cancelAll();
    final now = DateTime.now();
    final fmt = DateFormat('d MMMM yyyy', 'nl_NL');
    var id = 1;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        S.notifChannelName,
        channelDescription: S.notifChannelDesc,
      ),
      iOS: DarwinNotificationDetails(),
    );

    Future<void> schedule(DateTime when, String title, String body) =>
        _plugin.zonedSchedule(
          id: id++,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(when, tz.local),
          notificationDetails: details,
          // Inexact: geen "exact alarm"-permissie nodig; een paar minuten
          // afwijking is voor deze herinneringen prima.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );

    // Maximaal ~400 meldingen om onder de Android-limiet van 500 alarmen te blijven.
    final due = <(Item, DateTime, DateTime)>[];
    for (final i in items.where((i) => !i.hidden)) {
      final d = dueDate(i);
      if (d == null) continue;
      final t = reminderTime(d, now, leadDays);
      if (t != null) due.add((i, d, t));
    }
    due.sort((a, b) => a.$3.compareTo(b.$3));
    for (final (item, d, t) in due.take(400)) {
      final body = item.expiryDate != null
          ? S.notifBodyReplace(item.name, fmt.format(d))
          : S.notifBodyCheck(item.name);
      await schedule(t, S.notifTitleReplace, body);
    }

    // Documentenkluis: bewust neutrale tekst, zonder titel, naam of nummer.
    for (final t in vaultReminders.take(100)) {
      await schedule(t, S.notifTitleVault, S.notifBodyVault);
    }

    if (planReminderAt != null) {
      await schedule(planReminderAt, S.notifTitlePlan, S.notifBodyPlan);
    }

    if (semiAnnual) {
      // Twee komende halfjaarlijkse momenten; elke app-start schuift dit door.
      for (final m in [6, 12]) {
        final t = addMonths(dateOnly(now), m);
        await schedule(
            DateTime(t.year, t.month, t.day, 10), S.notifTitleHalfYear, S.notifBodyHalfYear);
      }
    }
  }
}
