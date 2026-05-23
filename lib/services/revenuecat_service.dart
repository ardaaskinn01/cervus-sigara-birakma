import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../providers/database_provider.dart';

class RevenueCatService {
  static bool _isConfigured = false;

  static Future<void> init(WidgetRef ref) async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      String apiKey = "";
      if (Platform.isAndroid) {
        apiKey = "goog_xiwZOaZBoCYtiKPCIwLJamDWAyT";
      } else {
        apiKey = "appl_CQFtyxVzaSGaQyKeeGaqxiKtyyV";
      }

      if (apiKey.isEmpty) return;

      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      _isConfigured = true;

      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      final isPro = customerInfo.entitlements.all["pro"]?.isActive ?? false;
      
      final db = ref.read(databaseProvider);
      await db.setProStatus(isPro);
    } catch (e) {
      debugPrint("RevenueCat Init Error: $e");
    }
  }

  static Future<Offerings?> getOfferings() async {
    if (!_isConfigured) {
      debugPrint("RevenueCat is not configured yet — skipping getOfferings.");
      return null;
    }
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint("Offerings hatası: $e");
      return null;
    }
  }

  static Future<bool> purchasePackage(BuildContext context, WidgetRef ref, Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      final customerInfo = result.customerInfo;
      final isPro = customerInfo.entitlements.all["pro"]?.isActive ?? false;

      final db = ref.read(databaseProvider);
      await db.setProStatus(isPro);

      if (context.mounted && isPro) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Satın alım başarılı!'), backgroundColor: Colors.green),
        );
      }
      return isPro;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint("Satın alma kullanıcı tarafından iptal edildi.");
        return false;
      }
      debugPrint("Satın alma hatası: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Satın alım başarısız oldu.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Beklenmedik satın alma hatası: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
    return false;
  }

  static Future<bool> restorePurchases(BuildContext context, WidgetRef ref) async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      final isPro = customerInfo.entitlements.all["pro"]?.isActive ?? false;

      final db = ref.read(databaseProvider);
      await db.setProStatus(isPro);

      if (context.mounted) {
        if (isPro) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Satın alımınız geri yüklendi!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Geri yüklenecek abonelik bulunamadı.'), backgroundColor: Colors.orange),
          );
        }
      }
      return isPro;
    } catch (e) {
      debugPrint("Geri yükleme hatası: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geri yükleme başarısız oldu.'), backgroundColor: Colors.red),
        );
      }
    }
    return false;
  }
}
