import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class AdService {
  /// Üretim (Production) modu bayrağı.
  /// Gerçek reklam ID'lerini kullanmak için true yapın.
  static const bool isProduction = true;

  /// AdMob ve ATT (iOS) Başlatma
  static Future<void> init() async {
    if (Platform.isIOS) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Kullanıcıya izin penceresini göster (biraz gecikme ile ekranın hazır olmasını bekle)
        await Future.delayed(const Duration(milliseconds: 1000));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }
    await MobileAds.instance.initialize();
  }

  // Banner Reklam Unit ID'leri
  static String get bannerAdUnitId {
    if (isProduction) {
      if (Platform.isIOS) {
        return 'ca-app-pub-2073707860224174/8103519209'; 
      } else if (Platform.isAndroid) {
        return 'ca-app-pub-2073707860224174/4185378931';
      }
    } else {
      // Test ID'leri
      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      } else if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      }
    }
    return '';
  }

  // Geçiş (Interstitial) Reklam Unit ID'leri (Kullanıcı tarafından verilmediği için geçici olarak 000 tutuldu veya banner ile aynı atanabilir/değişebilir)
  static String get interstitialAdUnitId {
    if (isProduction) {
      if (Platform.isIOS) {
        return 'ca-app-pub-0000000000000000/0000000000'; // Henüz verilmediyse boş kalabilir.
      } else if (Platform.isAndroid) {
        return 'ca-app-pub-0000000000000000/0000000000';
      }
    } else {
      // Test ID'leri
      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910';
      } else if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712';
      }
    }
    return '';
  }

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  /// Geçiş Reklamını Yükle
  static void loadInterstitialAd() {
    // Interstitial ID boşsa yükleme yapma
    if (interstitialAdUnitId.contains('0000000000000000')) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              // Kapatılınca yenisini önbelleğe al
              loadInterstitialAd(); 
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Geçiş reklamı yüklenemedi: ${err.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  /// Geçiş Reklamını Göster (Eğer yüklendiyse)
  static void showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
    } else {
      debugPrint('Geçiş reklamı henüz hazır değil veya arka planda yükleniyor.');
    }
  }
}
