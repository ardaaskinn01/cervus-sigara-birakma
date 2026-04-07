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
    
    // 2. Telefonun Yerel Saat Dilimini Tespit Et (Paketsiz ve Güvenli Yol)
    try {
      // Cihazın şu anki yerel saati ile UTC arasındaki farkı saniye cinsinden alıyoruz
      final int offsetInSeconds = DateTime.now().timeZoneOffset.inSeconds;
      
      // Bu farkı kullanarak anonim bir yerel lokasyon oluşturuyoruz
      // tz.Location(name, transitionAt, transitionZone, zones) yapısı karmaşık olduğu için
      // en pratik yol: tz.local'i cihazın offset'ine göre kaydırılmış bir lokasyona eşitlemek.
      // tz.setLocalLocation(tz.getLocation(...)) yerine doğrudan offset kullanarak saati bulacağız.
      // Not: Çoğu modern cihazda tz.local zaten otomatik doğru gelmeye çalışır ama biz 
      // planlama sırasında DateTime.now() bazlı dinamik planlama yapacağız.
    } catch (e) {
      // Hata durumunda UTC devam et
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

  /// Zamanlanmış bildirimler (Telefonun Yerel Saatine Göre)
  Future<void> schedulePeriodicNotifications() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_motivation_channel',
      'Günlük Motivasyon',
      channelDescription: 'Sigara bırakma süreci için periyodik motivasyon bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // KRİTİK DÜZELTME: tz.local yerine DateTime.now() üzerinden 
    // mutlak bir TZDateTime oluşturuyoruz. Bu sayede cihaz hangi saatteyse
    // o saati referans alır, İstanbul mu Londra mı diye bakmaz.
    final DateTime now = DateTime.now();
    
    // 1. Bildirim (1 dak sonra)
    await _notificationsPlugin.zonedSchedule(
      1,
      'Harika Gidiyorsun! 💪',
      'Vücudun daha da temizlendi. Devam et!',
      tz.TZDateTime.from(now.add(const Duration(minutes: 1)), tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    // 2. Bildirim (2 dak sonra)
    await _notificationsPlugin.zonedSchedule(
      2,
      'Akciğerlerin Rahatlıyor 🫁',
      'Her nefes daha temiz. Kararından vazgeçme!',
      tz.TZDateTime.from(now.add(const Duration(minutes: 2)), tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
