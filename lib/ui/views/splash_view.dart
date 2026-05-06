import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/notification_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/ad_service.dart';
import '../../providers/database_provider.dart';
import '../../firebase_options.dart';
import '../app_colors.dart';
import 'onboarding_view.dart';
import 'main_view.dart';
import '../widgets/privacy_policy_sheet.dart';
import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
      duration: const Duration(milliseconds: 2000),
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
    // 1. Ekranın çizilmesi için bekle
    await Future.delayed(const Duration(milliseconds: 500));

    // 2. Maksimum bekleme süresi
    Timer(const Duration(seconds: 10), () {
      if (mounted && !_isNavigated) {
        _navigateToNext();
      }
    });

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }

      final db = ref.read(databaseProvider);
      await db.init();

      // --- GÜNCELLEME KONTROLÜ ---
      try {
        final config = await db.getRemoteConfig();
        if (config != null && mounted) {
          final int remoteBuildNumber = int.tryParse(config['buildNumber']?.toString() ?? '0') ?? 0;
          final PackageInfo packageInfo = await PackageInfo.fromPlatform();
          final int localBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

          if (remoteBuildNumber > localBuildNumber) {
            await _showUpdateDialog(
              iosUrl: config['iosUrl'] ?? '',
              androidUrl: config['androidUrl'] ?? '',
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ Güncelleme kontrolü hatası: $e');
      }
      // --------------------------

      debugPrint('🔔 Bildirimler başlatılıyor...');
      await NotificationService().init();

      if (db.isRegistered) {
        db.logAppEntry();
        final String? userId = db.currentFirebaseId;
        final Map<dynamic, dynamic>? userData = db.localUserData;
        if (userId != null && userData != null) {
          DashboardService().syncExistingUser(userId, userData);
        }
      }

      // Kullanıcı kayıtlıysa ve bildirimler açıksa, bildirimleri her açılışta tazeleyelim
      if (db.isRegistered && db.notificationsEnabled) {
        debugPrint('🔔 Bildirimler planlanıyor...');
        await NotificationService().schedulePeriodicNotifications();
      }

      debugPrint('💰 AdMob başlatılıyor...');
      // hem ATT hem AdMob'u başlatır
      AdService.init(); 
      
      // Isterseniz geçiş reklamlarını önceden yükleyebilirsiniz
      AdService.loadInterstitialAd();

      // İşlemler biter bitmez yönlendir (Timer'ı bekleme, akıcı bir geçiş için ekstra beklet)
      if (mounted && !_isNavigated) {
        await Future.delayed(const Duration(milliseconds: 1500));
        _navigateToNext();
      }
    } catch (e) {
      debugPrint("⚠️ Servislerde hata: $e");
      if (mounted && !_isNavigated) _navigateToNext();
    }
  }

  void _navigateToNext() async {
    if (_isNavigated) return;

    final db = ref.read(databaseProvider);
    _isNavigated = true;
    final bool isRegistered = db.isRegistered;

    if (!mounted) return;

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
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC), // AppColors.background
              Color(0xFFF0FDF4), // Very light green
              Color(0xFFDCFCE7), // Light green-100
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
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/Quitly.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'splash.title'.tr(),
                  style: const TextStyle(
                    fontSize: 42, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 4, 
                    color: Color(0xFF064E3B), 
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'splash.subtitle'.tr(),
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w800, 
                    letterSpacing: 2, 
                    color: AppColors.primary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 60),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Future<void> _showUpdateDialog({required String iosUrl, required String androidUrl}) async {
    final String storeUrl = Platform.isIOS ? iosUrl : androidUrl;
    
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Güncelleme Mevcut',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
        ),
        content: const Text(
          'Uygulamanın daha yeni ve stabil bir versiyonu yayında. En iyi deneyim için lütfen güncelleyin.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Güncelleme', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (storeUrl.isNotEmpty) {
                final Uri url = Uri.parse(storeUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }
}

class AppCurves {
  static const Curve outOrdinary = Cubic(0.2, 0.0, 0.0, 1.0);
}
