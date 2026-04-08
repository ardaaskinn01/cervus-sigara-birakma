import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Bildirim Motorunun Hazırlanması ve İzinleri Alması
  Future<void> init() async {
    if (_initialized) return;

    // 1. Timezone verilerini yükle
    tz.initializeTimeZones();
    
    // 2. Telefonun Yerel Saat Dilimini Ayarla
    try {
      final String timeZoneName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      final int offsetInSeconds = DateTime.now().timeZoneOffset.inSeconds;
      final location = tz.Location('Local', [0], [0], [
        tz.TimeZone(offsetInSeconds, isDst: false, abbreviation: 'LOC')
      ]);
      tz.setLocalLocation(location);
    }

    // 3. Android İkon Ayarı
    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 4. iOS Ayarları
    const DarwinInitializationSettings initIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 5. Genel Init
    const InitializationSettings initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initIOS,
    );

    await _notificationsPlugin.initialize(initSettings);

    // 6. Android 13+ (API 33) için Bildirim İzni İsteme
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Anında bildirim (Test için en hızlı yol)
  Future<void> showImmediateNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'sigara_test_kanal',
      'Test Bildirimleri',
      channelDescription: 'Anlık test bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      99,
      'Cervus İyileşme Bildirimi! 💪',
      'Bildirim sistemi şu an aktif ve hazır.',
      details,
    );
  }

  /// Günlük periyodik bildirimleri ayarla (Öğlen 12 ve Akşam 20:00)
  Future<void> schedulePeriodicNotifications() async {
    // Önce eski tüm bildirimleri temizleyelim (çakışma olmaması için)
    await cancelAllNotifications();

    const androidDetails = AndroidNotificationDetails(
      'daily_motivation_channel',
      'Günlük Motivasyon',
      channelDescription: 'Sigara bırakma süreci için periyodik motivasyon bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // 1. Bildirim: Öğlen 12:00
    await _notificationsPlugin.zonedSchedule(
      1200,
      'Günün Yarısı Tamam! 💪',
      'Bugün hiç sigara içmedin. Harika ilerliyorsun!',
      _nextInstanceOfTime(12, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Her gün aynı saatte tekrarla
    );

    // 2. Bildirim: Akşam 20:00
    await _notificationsPlugin.zonedSchedule(
      2000,
      'İyi Akşamlar! 🌿',
      'Günü tertemiz bitirmek üzeresin. Akciğerlerin sana teşekkür ediyor.',
      _nextInstanceOfTime(20, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Her gün aynı saatte tekrarla
    );
  }

  /// Belirtilen saat ve dakika için bir sonraki zaman dilimini hesapla
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // Eğer saat geçtiyse bir sonraki güne ayarla
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
