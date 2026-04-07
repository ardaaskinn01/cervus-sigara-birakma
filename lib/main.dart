import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';

import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'providers/database_provider.dart';
import 'ui/views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Yalnızca Flutter dizinlerini açmak için son derece hızlı olan Hive dizin başlatıcısı.
  // Gerçek veri çekme ve veritabanı kilitleri SplashView içinde gerçekleşecek.
  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: MyApp(),
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
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F9F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF81C784),
          surface: Colors.white,
        ),
        cardColor: Colors.white,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF1B5E20), // Dark green text for app structures
        ),
      ),
      home: const SplashView(), // Uygulamanın doğrudan ve ilk açıldığı yer
    );
  }
}
