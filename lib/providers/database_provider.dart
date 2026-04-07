import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

/// Database provider'ını globale açıyoruz
final databaseProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});
