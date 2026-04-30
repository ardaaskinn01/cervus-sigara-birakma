import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'app_constants.dart';

class ReviewService with WidgetsBindingObserver {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }


  final InAppReview _inAppReview = InAppReview.instance;
  bool _didAppGoInactive = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _didAppGoInactive = true;
    }
  }

  /// In-app review promptunu göstermeye çalışır. 
  /// Eğer kota dolduysa veya sistem desteklemiyorsa mağaza sayfasına yönlendirir.
  Future<void> requestReview() async {
    _didAppGoInactive = false;

    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();

        // 4 saniye bekle ve uygulamanın inaktifleşip inaktifleşmediğini kontrol et
        await Future.delayed(const Duration(seconds: 4));

        // Eğer uygulama hala aktifse, popup açılmamış demektir
        if (!_didAppGoInactive) {
          debugPrint('Popup açılmadı, mağazaya yönlendiriliyor...');
          await _inAppReview.openStoreListing(appStoreId: AppConstants.appStoreId);
        }
      } else {
        await _inAppReview.openStoreListing(appStoreId: AppConstants.appStoreId);
      }
    } catch (e) {
      debugPrint('Rate app failed: $e');
      await _inAppReview.openStoreListing(appStoreId: AppConstants.appStoreId);
    }
  }

  /// Doğrudan uygulama mağazası sayfasını açar.
  Future<void> openStoreListing() async {
    await _inAppReview.openStoreListing(
      appStoreId: AppConstants.appStoreId,
    );
  }
}
