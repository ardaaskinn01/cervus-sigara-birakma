import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/notification_service.dart';
import '../../providers/database_provider.dart';
import '../../firebase_options.dart';
import 'onboarding_view.dart';
import 'main_view.dart';
import 'dart:async';

/// ==========================================
/// 🚀 ULTRA-SAFE SPLASH SCREEN (ZIRHLI MOD)
/// ==========================================
/// Uygulama açılır açılmaz UI render edilir.
/// Servisler (Firebase, AdMob vs) ARKA PLANDA başlar.
/// Hiçbir servis UI çizilmeyi engellemez (White Screen çözümü).
/// ==========================================
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🌊 SPLASH: Başladı');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.outOrdinary),
    );

    _controller.forward();

    // 🎯 KRİTİK: beklemeden servisleri tetikle!
    _startInitialization();
  }

  void _startInitialization() async {
    // 1. Ekranın çizilmesi için bekle (Hemen başlar başlamaz çizim yapılır)
    await Future.delayed(const Duration(milliseconds: 500));

    // 2. Maksimum bekleme süresi koy (Eğer her şey kilitlenirse bile 6 saniye sonra ana ekrana fırlat)
    Timer(const Duration(seconds: 6), () {
      if (mounted && !_isNavigated) {
        debugPrint('⏰ SPLASH TIMEOUT: Servisler bitmeden gidiyoruz.');
        _navigateToNext();
      }
    });

    try {
      // 3. Arka Plan Servisleri
      debugPrint('🔥 Firebase başlatılıyor...');
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        debugPrint('🔥 Firebase başarıyla başlatıldı.');
      } else {
        debugPrint('🔥 Firebase zaten başlatılmış, atlanıyor.');
      }

      debugPrint('🔔 Bildirimler başlatılıyor...');
      await NotificationService().init();

      debugPrint('🗄️ Veritabanı başlatılıyor...');
      final db = ref.read(databaseProvider);
      await db.init();

      // Kullanıcı kayıtlıysa ve bildirimler açıksa, bildirimleri her açılışta tazeleyelim
      if (db.isRegistered && db.notificationsEnabled) {
        debugPrint('🔔 Bildirimler planlanıyor...');
        await NotificationService().schedulePeriodicNotifications();
      }

      debugPrint('💰 AdMob başlatılıyor...');
      // initialize() zaten güvenli, ama beklemeden devam ediyoruz
      MobileAds.instance.initialize();

      // İşlemler biter bitmez yönlendir (Timer'ı bekleme, akıcı bir geçiş için ekstra beklet)
      if (mounted && !_isNavigated) {
        await Future.delayed(const Duration(milliseconds: 800));
        _navigateToNext();
      }
    } catch (e) {
      debugPrint("⚠️ Servislerde hata: $e");
      if (mounted && !_isNavigated) _navigateToNext();
    }
  }

  void _navigateToNext() {
    if (_isNavigated) return;
    _isNavigated = true;

    // Database provider'ı _startInitialization içinde init() yapmıştık.
    final db = ref.read(databaseProvider);
    final bool isRegistered = db.isRegistered;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          isRegistered ? const MainView() : const OnboardingView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9), // Açık yeşil tonları uygulamamıza uyum için
              Color(0xFF81C784),
              Color(0xFF4CAF50),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded, size: 100, color: Colors.white), // Logo ikonu
                ),
                const SizedBox(height: 30),
                const Text(
                  'CERVUS',
                  style: TextStyle(
                    fontSize: 42, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 8, 
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'YENİDEN DOĞUŞ',
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w600, 
                    letterSpacing: 4, 
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 60),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppCurves {
  static const Curve outOrdinary = Cubic(0.2, 0.0, 0.0, 1.0);
}
