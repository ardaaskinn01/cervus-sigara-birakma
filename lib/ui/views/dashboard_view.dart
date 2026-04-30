import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../providers/database_provider.dart';
import 'crisis_view.dart';
import '../app_colors.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider);
    final db = ref.watch(databaseProvider);
    final userName = db.localUserData?['originalName'] ?? 'Kahraman';

    final days = state.timeElapsed.inDays;
    final hours = state.timeElapsed.inHours.remainder(24);
    final minutes = state.timeElapsed.inMinutes.remainder(60);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Teşvik Başlığı
              FadeInSlide(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'dashboard.greeting'.tr(args: [userName]),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF064E3B),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInSlide(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'dashboard.subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppColors.secondaryText, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 32),

              // Geri Sayım Süre Kartı (Neumorphic Soft UI)
              FadeInSlide(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, spreadRadius: 0, offset: const Offset(0, 12)),
                      const BoxShadow(color: Colors.white, blurRadius: 10, spreadRadius: 5, offset: Offset(-4, -4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCircularTime('common.day'.tr(), days, 365, AppColors.primary),
                      _buildCircularTime('common.hour'.tr(), hours, 24, const Color(0xFF4ADE80)),
                      _buildCircularTime('common.minute'.tr(), minutes, 60, const Color(0xFF86EFAC)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Kurtarılan Bütçe Kartı (LinearGradient & Glass Effect)
              FadeInSlide(
                delay: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ADE80), AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, size: 42, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'dashboard.money_saved'.tr(),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            state.savedMoney.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            state.currencySymbol,
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
// Removed Health Progress Section
              const SizedBox(height: 24),
              // Karbon Ayak İzi Kartı
              FadeInSlide(
                delay: const Duration(milliseconds: 600),
                child: CarbonFootprintCard(
                  savedCO2: state.savedCO2,
                  avoidedCigarettes: state.avoidedCigarettes,
                ),
              ),
              const SizedBox(height: 24),

              // Krize Müdahale Butonu
              FadeInSlide(
                delay: const Duration(milliseconds: 500),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CrisisView()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(color: Color(0xFFFFEDD5), width: 2), // Orange-100
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    foregroundColor: AppColors.accent,
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.warning_amber_rounded, size: 24, color: AppColors.accent),
                  label: Text(
                    'crisis.title'.tr().toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sigara İçtim Butonu
              FadeInSlide(
                delay: const Duration(milliseconds: 1400),
                child: OutlinedButton.icon(
                  onPressed: () => _showResetConfirmation(context, ref),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(color: Color(0xFFFEE2E2), width: 2), // Red-100
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    foregroundColor: const Color(0xFFB91C1C), // Red-700
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  label: Text(
                    'dashboard.reset_confirm'.tr().toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('dashboard.reset_title'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        content: Text(
          'dashboard.reset_desc'.tr(),
          style: const TextStyle(fontSize: 15, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('dashboard.reset_cancel'.tr(), style: const TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(dashboardViewModelProvider.notifier).resetTimer();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('dashboard.reset_success'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626), // Red-600
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('dashboard.reset_confirm'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularTime(String label, int value, int maxValue, Color color) {
    double progress = value / maxValue;
    if (progress > 1.0) progress = 1.0;
    if (progress < 0.0) progress = 0.0;

    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 8,
                color: color.withOpacity(0.1),
              ),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                color: color,
              ),
              Center(
                child: Text(
                  value.toString().padLeft(2, '0'),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.secondaryText,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeInSlide({super.key, required this.child, required this.delay});

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
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

class CarbonFootprintCard extends StatelessWidget {
  final double savedCO2;
  final int avoidedCigarettes;

  const CarbonFootprintCard({
    super.key,
    required this.savedCO2,
    required this.avoidedCigarettes,
  });

  @override
  Widget build(BuildContext context) {
    final String co2Text = savedCO2 > 1000 
      ? '${(savedCO2 / 1000).toStringAsFixed(2)} kg' 
      : '${savedCO2.toStringAsFixed(0)} gr';

    int treeLevel = (avoidedCigarettes / 50).floor().clamp(1, 4);

    IconData treeIcon;
    Color primaryColor;
    Color secondaryColor;
    String statusText;

    switch (treeLevel) {
      case 1:
        treeIcon = Icons.eco_outlined;
        primaryColor = const Color(0xFF4ADE80);
        secondaryColor = const Color(0xFFDCFCE7);
        statusText = "dashboard.tree_status_1".tr();
        break;
      case 2:
        treeIcon = Icons.eco;
        primaryColor = const Color(0xFF22C55E);
        secondaryColor = const Color(0xFFBBF7D0);
        statusText = "dashboard.tree_status_2".tr();
        break;
      case 3:
        treeIcon = Icons.park_outlined;
        primaryColor = const Color(0xFF16A34A);
        secondaryColor = const Color(0xFF86EFAC);
        statusText = "dashboard.tree_status_3".tr();
        break;
      case 4:
      default:
        treeIcon = Icons.park;
        primaryColor = const Color(0xFF15803D);
        secondaryColor = const Color(0xFF4ADE80);
        statusText = "dashboard.tree_status_4".tr();
        break;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [AppColors.card, secondaryColor.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(seconds: 1),
                          builder: (context, val, child) {
                            return Transform.rotate(
                              angle: (1 - val) * 0.5,
                              child: Icon(treeIcon, size: 32, color: primaryColor),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'dashboard.nature_contribution'.tr(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              statusText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.card.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'dashboard.co2_saved_label', // Fixed translation key access if needed, or translate directly
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: AppColors.secondaryText,
                          ),
                        ).tr(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              co2Text.split(' ')[0],
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                co2Text.split(' ')[1],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        '${'dashboard.cig_avoided'.tr()} $avoidedCigarettes',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
