import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'database_provider.dart';

class LanguageNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final db = ref.read(databaseProvider);
    final savedCode = db.localeCode;
    if (savedCode != null) {
      return Locale(savedCode);
    }
    // Default fallback
    return const Locale('tr');
  }

  /// Change language visually and save the preference
  Future<void> changeLanguage(BuildContext context, String languageCode) async {
    final newLocale = Locale(languageCode);
    
    // Update EasyLocalization context directly
    await context.setLocale(newLocale);
    
    // Save locally via DatabaseService
    final db = ref.read(databaseProvider);
    await db.setLocale(languageCode);
    
    // Update provider state
    state = newLocale;
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, Locale>(() {
  return LanguageNotifier();
});
