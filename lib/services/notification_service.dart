import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;

  /// Bildirim Motorunun Hazırlanması ve İzinleri Alması
  Future<void> init() async {
    if (_initialized) return;

    // 1. Timezone verilerini yükle
    tz_data.initializeTimeZones();
    
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

    // 7. FCM Kurulumu
    await _setupFcm();

    _initialized = true;
  }

  /// Token'ı veritabanına zorla günceller ve topic aboneliği yapar
  Future<void> updateTokenToDatabase() async {
    try {
      final String? uniqueId = DatabaseService().currentFirebaseId;
      String? token = await _messaging.getToken();
      
      if (token != null) {
        if (uniqueId != null) {
          String topic = 'user_$uniqueId';
          await _messaging.subscribeToTopic(topic);
          await DatabaseService().updateFcmSubscription(token: token, topic: topic);
        } else {
          await DatabaseService().updateFcmToken(token);
        }
      }
    } catch (e) {
      print('❌ FCM Token/Topic güncellenemedi: $e');
    }
  }

  /// FCM (Firebase Cloud Messaging) Ayarları
  Future<void> _setupFcm() async {
    // 1. İzin İste (iOS ve Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Kullanıcı bildirim izni verdi.');
    } else {
      print('❌ Kullanıcı bildirim iznini reddetti veya kısmi izin verdi.');
    }

    // 2. Token Al ve Kaydet
    try {
      final String? uniqueId = DatabaseService().currentFirebaseId;
      
      String? token = await _messaging.getToken();
      if (token != null) {
        print('📱 FCM Token: $token');
        
        // Bireysel Topic Aboneliği (Tekli mesaj atabilmek için)
        if (uniqueId != null) {
          String topic = 'user_$uniqueId';
          await _messaging.subscribeToTopic(topic);
          print('🔔 Subscribed to topic: $topic');
          
          // Token ve Topic'i Firestore'a kaydet
          await DatabaseService().updateFcmSubscription(token: token, topic: topic);
        } else {
          await updateTokenToDatabase();
        }
      }
    } catch (e) {
      print('❌ FCM Token veya Topic hatası: $e');
    }

    // 3. Token Yenilenirse Takip Et
    _messaging.onTokenRefresh.listen((newToken) async {
      await DatabaseService().updateFcmToken(newToken);
    });

    // 4. Foreground (Uygulama açıkken) mesajlarını dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground mesaj geldi: ${message.notification?.title}');
      
      // Eğer uygulama açıkken bildirim kutusu da çıksın istiyorsak local notification tetikliyoruz
      if (message.notification != null) {
        _showLocalNotificationFromFcm(message.notification!);
      }
    });

    // 5. Uygulama arka plandayken bildirime tıklandığında
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🖱️ Arka planda bildirime tıklandı!');
    });
  }

  /// FCM'den gelen bildirimi local olarak göster (Foreground için)
  Future<void> _showLocalNotificationFromFcm(RemoteNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'fcm_default_channel',
      'Push Bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
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

  /// 5 Sabah / 5 Akşam olmak üzere önümüzdeki 5 gün için rastgele dinamik bildirim ayarlar
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

    List<dynamic> morningTexts = [];
    List<dynamic> eveningTexts = [];
    
    try {
      final doc = await FirebaseFirestore.instance.collection('texts').doc('motivations').get();
      if (doc.exists) {
        morningTexts = List.from(doc.data()?['morning'] ?? []);
        eveningTexts = List.from(doc.data()?['evening'] ?? []);
      }
    } catch (e) {
      print('❌ Firebase metinleri çekilemedi, fallbacks kullanılacak: $e');
    }
    
    // Varsayılan metinler (Eğer internet yoksa veya Firestore başarısız olursa)
    if (morningTexts.isEmpty) {
      morningTexts = [
        {'title': 'Yeni Bir Gün, Temiz Nefes! 🌅', 'body': 'Bugün kahvenin tadı bir başka güzel değil mi? Harika ilerliyorsun!'},
        {'title': 'Sabah Enerjisi! 🏃‍♂️', 'body': 'Uyanmak eskisinden daha kolay. Güne çok daha zinde başlıyorsun.'}
      ];
    }
    if (eveningTexts.isEmpty) {
      eveningTexts = [
        {'title': 'İyi Akşamlar! 🌿', 'body': 'Günü tertemiz bitirmek üzeresin. Akciğerlerin sana teşekkür ediyor.'},
        {'title': 'Günü Başarıyla Tamamladın! 🌙', 'body': 'Bir günü daha dumansız bitirdin. Gurur duy!'}
      ];
    }
    
    // Rastgele dağılım için metinleri karıştırıyoruz
    morningTexts.shuffle();
    eveningTexts.shuffle();

    int notifId = 1000;
    
    // Önümüzdeki 5 gün için (0. günden 4. güne kadar) sabah ve akşam bildirimi kuralım
    for (int i = 0; i < 5; i++) {
        // Sabah 09:30 Bildirimi
        final currentMorning = morningTexts[i % morningTexts.length];
        await _notificationsPlugin.zonedSchedule(
          notifId++,
          currentMorning['title'].toString(),
          currentMorning['body'].toString(),
          _nextInstanceOfTime(9, 30).add(Duration(days: i)),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        
        // Akşam 20:30 Bildirimi
        final currentEvening = eveningTexts[i % eveningTexts.length];
        await _notificationsPlugin.zonedSchedule(
          notifId++,
          currentEvening['title'].toString(),
          currentEvening['body'].toString(),
          _nextInstanceOfTime(20, 30).add(Duration(days: i)),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
    }
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
