import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'providers/database_provider.dart';
import 'ui/views/splash_view.dart';
import 'ui/app_colors.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await EasyLocalization.ensureInitialized();

  // Yalnızca Flutter dizinlerini açmak için son derece hızlı olan Hive dizin başlatıcısı.
  // Gerçek veri çekme ve veritabanı kilitleri SplashView içinde gerçekleşecek.
  await Hive.initFlutter();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('tr'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('tr'),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Sigara Bırakma',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.breathBlue,
          surface: AppColors.card,
          onSurface: const Color(0xFF1E293B), // Dark slate for primary text
        ),
        cardColor: AppColors.card,
        dividerColor: AppColors.border,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF064E3B), // Emerald-950 for text
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      home: const SplashView(), // Uygulamanın doğrudan ve ilk açıldığı yer
    );
  }
}
