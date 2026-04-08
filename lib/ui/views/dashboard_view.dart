import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../providers/database_provider.dart';
import 'crisis_view.dart';

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
      backgroundColor: const Color(0xFFF4F9F4),
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
                  'Harikasın $userName!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInSlide(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Tertemiz bir hayata adım atalı:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 32),

              // Geri Sayım Süre Kartı (Neumorphic Soft UI)
              FadeInSlide(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, spreadRadius: 0, offset: const Offset(0, 12)),
                      const BoxShadow(color: Colors.white, blurRadius: 10, spreadRadius: 5, offset: Offset(-4, -4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCircularTime('GÜN', days, 365, const Color(0xFF4CAF50)),
                      _buildCircularTime('SAAT', hours, 24, const Color(0xFF66BB6A)),
                      _buildCircularTime('DAKİKA', minutes, 60, const Color(0xFF81C784)),
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
                      colors: [Color(0xFF47D548), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
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
                        'Kurtarılan Bütçe',
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
                            '₺',
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
                    side: BorderSide(color: Colors.orange.shade300, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    foregroundColor: Colors.orange.shade900,
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  icon: Icon(Icons.warning_amber_rounded, size: 24, color: Colors.orange.shade800),
                  label: const Text(
                    'İÇMEK ÜZEREYİM',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
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
                    side: BorderSide(color: Colors.red.shade200, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    foregroundColor: Colors.red.shade700,
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  label: const Text(
                    'SİGARA İÇTİM (YENİDEN BAŞLA)',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Emin misin?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'Bu işlem tüm ilerlemeni ve kurtarılan bütçeni sıfırlayacaktır. Yeni ve daha güçlü bir başlangıç yapmak istiyor musun?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('VAZGEÇ', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(dashboardViewModelProvider.notifier).resetTimer();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Sayaç sıfırlandı. Asla pes etme!', style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF1B5E20),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SIFIRLA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularTime(String label, int value, int maxValue, Color color) {
    // Sınır güvenliği (Eğer limit aşılırsa çember tam dolsun)
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
              // Arka plan soft çember
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 8,
                color: color.withOpacity(0.1),
              ),
              // İlerleyen ana çember (Yuvarlatılmış uçlarla animasyonlu hale getirilebilir ama standart widget uçları kare)
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                color: color,
              ),
              Center(
                child: Text(
                  value.toString().padLeft(2, '0'),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

/// Gelişmiş Giriş Animasyonu (Fade & Slide UP)
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

/// Modern & Şık Karbon Ayak İzi Widget'ı
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
        primaryColor = const Color(0xFF81C784);
        secondaryColor = const Color(0xFFC8E6C9);
        statusText = "Doğa Tohumları Atıldı";
        break;
      case 2:
        treeIcon = Icons.eco;
        primaryColor = const Color(0xFF66BB6A);
        secondaryColor = const Color(0xFFA5D6A7);
        statusText = "Fidanın Büyüyor";
        break;
      case 3:
        treeIcon = Icons.park_outlined;
        primaryColor = const Color(0xFF43A047);
        secondaryColor = const Color(0xFF81C784);
        statusText = "Genç Bir Ağaç Oldu";
        break;
      case 4:
      default:
        treeIcon = Icons.park;
        primaryColor = const Color(0xFF1B5E20);
        secondaryColor = const Color(0xFF4CAF50);
        statusText = "Koca Bir Çınar Yolunda";
        break;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [Colors.white, secondaryColor.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Arka Plan Dekoratif Halka
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
                      // İkon Konteynırı
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
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
                              'Doğaya Katkın',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: primaryColor.withAlpha(200),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Değer Kartı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: primaryColor.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'KURTARILAN CO2',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
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
                  // Alt Bilgi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'İçilmeyen $avoidedCigarettes sigara sayesinde',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
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
