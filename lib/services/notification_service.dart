import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Bildirim Motorunun Hazırlanması ve İzinleri Alması
  Future<void> init() async {
    // 1. Timezone verilerini yükle
    tz.initializeTimeZones();

    // 2. Android İkon Ayarı
    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS Ayarları
    const DarwinInitializationSettings initIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 4. Genel Init
    const InitializationSettings initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initIOS,
    );

    await _notificationsPlugin.initialize(initSettings);

    // 5. Android 13+ (API 33) için Bildirim İzni İsteme
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> schedulePeriodicNotifications() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_motivation_channel',
      'Günlük Motivasyon',
      channelDescription:
          'Sigara bırakma süreci için periyodik motivasyon bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = tz.TZDateTime.now(tz.local);

    // TEST İÇİN: 1 Dakika Sonra (Daha önce 8 saatti)
    await _notificationsPlugin.zonedSchedule(
      1,
      'Harika Gidiyorsun! 💪',
      'Vücudun bir nebze daha kurtuldu. Ne kadar para tasarruf ettiğini görmek için uygulamaya bakabilirsin.',
      now.add(const Duration(minutes: 1)),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // TEST İÇİN: 2 Dakika Sonra (Daha önce 20 saatti)
    await _notificationsPlugin.zonedSchedule(
      2,
      'Akciğerlerin Rahatlıyor 🫁',
      'Nefes almanın ne kadar kolaylaştığını hissediyor musun? Kararından vazgeçme ve derin bir nefes al!',
      now.add(const Duration(minutes: 2)),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
