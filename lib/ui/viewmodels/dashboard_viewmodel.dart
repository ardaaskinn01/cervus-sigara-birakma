import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../services/database_service.dart';

class DashboardState {
  final Duration timeElapsed;
  final double savedMoney;
  final double savedCO2; // in grams
  final int avoidedCigarettes;
  final String currencySymbol;

  DashboardState({
    required this.timeElapsed, 
    required this.savedMoney,
    required this.savedCO2,
    required this.avoidedCigarettes,
    required this.currencySymbol,
  });
}

class DashboardViewModel extends StateNotifier<DashboardState> {
  final DatabaseService _db;
  Timer? _timer;
  StreamSubscription? _dbSubscription;

  DashboardViewModel(this._db)
      : super(DashboardState(
          timeElapsed: Duration.zero, 
          savedMoney: 0.0,
          savedCO2: 0.0,
          avoidedCigarettes: 0,
          currencySymbol: _db.currencySymbol,
        )) {
    _startTimer();
    
    // Listen for Hive changes (like resetting the timer or changing currency)
    _dbSubscription = _db.userChanges.listen((event) {
      _timer?.cancel();
      _startTimer();
    });
  }

  void _startTimer() {
    final localData = _db.localUserData;
    if (localData == null) return;

    final regDateStr = localData['registrationDate'] as String?;
    if (regDateStr == null) return;

    final regDate = DateTime.parse(regDateStr);
    
    final dailyCig = (localData['dailyCigarettes'] as num?)?.toInt() ?? 0;
    final packPrice = (localData['packPrice'] as num?)?.toDouble() ?? 0.0;

    final pricePerCig = packPrice / 20;
    final moneyPerDay = dailyCig * pricePerCig;
    final moneyPerMinute = moneyPerDay / (24 * 60);
    
    final cigPerMinute = dailyCig / (24 * 60);

    _calculateTick(regDate, moneyPerMinute, cigPerMinute);

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _calculateTick(regDate, moneyPerMinute, cigPerMinute);
    });
  }

  void _calculateTick(DateTime regDate, double moneyPerMinute, double cigPerMinute) {
    final now = DateTime.now();
    final difference = now.difference(regDate);

    if (difference.isNegative) {
       state = DashboardState(
         timeElapsed: Duration.zero, 
         savedMoney: 0.0,
         savedCO2: 0.0,
         avoidedCigarettes: 0,
         currencySymbol: _db.currencySymbol,
       );
       return;
    }

    final totalMinutes = difference.inMinutes;
    final saved = (totalMinutes * moneyPerMinute).floorToDouble();
    final totalAvoidedRaw = totalMinutes * cigPerMinute;
    final avoided = totalAvoidedRaw.floor();
    final co2 = totalAvoidedRaw * 14.0;

    state = DashboardState(
      timeElapsed: difference,
      savedMoney: saved,
      savedCO2: co2,
      avoidedCigarettes: avoided,
      currencySymbol: _db.currencySymbol,
    );
  }

  Future<void> resetTimer() async {
    await _db.resetSmokingTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dbSubscription?.cancel();
    super.dispose();
  }
}

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
  final db = ref.watch(databaseProvider);
  return DashboardViewModel(db);
});
