import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../providers/database_provider.dart';
import '../../models/health_goal.dart';
import '../widgets/health_progress_widget.dart';
import '../app_colors.dart';

class HealthView extends ConsumerStatefulWidget {
  const HealthView({super.key});

  @override
  ConsumerState<HealthView> createState() => _HealthViewState();
}

class _HealthViewState extends ConsumerState<HealthView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider);
    final db = ref.watch(databaseProvider);
    final yearsSmoking = db.localUserData?['yearsSmoking'] ?? 0;

    // Genel Arınma Oranını Hesapla (Daha Gerçekçi Karesel Model)
    double totalProgressSum = 0;
    for (var goal in healthGoals) {
      final adjusted = goal.getAdjustedDuration(yearsSmoking);
      double p = state.timeElapsed.inSeconds / adjusted.inSeconds;
      if (p > 1.0) p = 1.0;
      
      totalProgressSum += p;
    }
    
    final double overallPurity = totalProgressSum / healthGoals.length;
    final int purityPercentage = (overallPurity * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('health.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF064E3B))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
          children: [
            // Canlı Vücut Arınma Göstergesi
            FadeInSlideFast(
              delay: const Duration(milliseconds: 100),
              child: _buildMasterPurityCard(purityPercentage),
            ),
            const SizedBox(height: 32),
            
            // "Ayrıntılı İyileşme Süreci" Başlığı
            FadeInSlideFast(
              delay: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 16),
                child: Text(
                  'health.subtitle'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B), // Slate-800
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // İyileşme Çubukları
            ...List.generate(healthGoals.length, (index) {
              return FadeInSlideFast(
                delay: Duration(milliseconds: 300 + (index * 100)),
                child: HealthProgressWidget(
                  timeElapsed: state.timeElapsed,
                  goal: healthGoals[index],
                  yearsSmoking: yearsSmoking,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterPurityCard(int purityPercentage) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)], // Green-100 to Green-200
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          // Nefes Alan / Kalp Atan Animasyonlu İkon
          const BreathingHeartIcon(),
          const SizedBox(height: 24),
          Text(
            'health.master_purity_label'.tr(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '%$purityPercentage',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15803D), // Green-700
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'health.master_purity_desc'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF15803D).withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class BreathingHeartIcon extends StatefulWidget {
  const BreathingHeartIcon({super.key});

  @override
  State<BreathingHeartIcon> createState() => _BreathingHeartIconState();
}

class _BreathingHeartIconState extends State<BreathingHeartIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20 * _scaleAnimation.value,
                  spreadRadius: 2 * _scaleAnimation.value,
                ),
              ],
            ),
            child: const Icon(Icons.favorite_rounded, size: 48, color: AppColors.primary),
          ),
        );
      },
    );
  }
}

class FadeInSlideFast extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeInSlideFast({super.key, required this.child, required this.delay});

  @override
  State<FadeInSlideFast> createState() => _FadeInSlideFastState();
}

class _FadeInSlideFastState extends State<FadeInSlideFast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}
