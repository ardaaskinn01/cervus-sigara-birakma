import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../providers/database_provider.dart';
import '../app_colors.dart';

class CrisisView extends ConsumerStatefulWidget {
  const CrisisView({super.key});

  @override
  ConsumerState<CrisisView> createState() => _CrisisViewState();
}

class _CrisisViewState extends ConsumerState<CrisisView> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  String _breatheKey = "crisis.breathe_in";

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOutSine),
    );

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _breatheKey = "crisis.breathe_out");
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _breatheKey = "crisis.breathe_in");
        _breathingController.forward();
      }
    });

    _breathingController.forward();
    
    // Kriz günü kaydı — otomatik olarak Firebase'e yaz
    Future.microtask(() {
      ref.read(databaseProvider).logCrisisDay();
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider);
    final days = state.timeElapsed.inDays;
    final hours = state.timeElapsed.inHours.remainder(24);

    return Scaffold(
      backgroundColor: AppColors.breathBlue, // Fresh Blue for focus
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'crisis.title'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Animasyon çemberi
            Center(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.25),
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.15),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Transform.scale(
                        scale: 1 / _scaleAnimation.value,
                        child: Text(
                          _breatheKey.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Öneri Kartı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.water_drop_rounded, color: Colors.white, size: 48),
                    const SizedBox(height: 24),
                    Text(
                      'crisis.tip'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 16, 
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: Colors.white.withOpacity(0.3), height: 1),
                    const SizedBox(height: 24),
                    Text(
                      days > 0 
                        ? 'crisis.success_msg'.tr(args: [days.toString(), hours.toString()]) 
                        : 'crisis.start_msg'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFDE68A), // Amber-200
                        fontSize: 16, 
                        fontWeight: FontWeight.w900,
                        height: 1.5
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
