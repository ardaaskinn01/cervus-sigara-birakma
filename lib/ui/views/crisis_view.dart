import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import 'dart:async';

class CrisisView extends ConsumerStatefulWidget {
  const CrisisView({super.key});

  @override
  ConsumerState<CrisisView> createState() => _CrisisViewState();
}

class _CrisisViewState extends ConsumerState<CrisisView> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  String _breatheText = "Nefes Al";

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
        setState(() => _breatheText = "Nefes Ver");
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _breatheText = "Nefes Al");
        _breathingController.forward();
      }
    });

    _breathingController.forward();
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
      backgroundColor: const Color(0xFF1B5E20), // Kuyu yeşil arkaplan
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Derin Bir Nefes Al",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
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
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Transform.scale(
                        scale: 1 / _scaleAnimation.value, // Metnin boyutlanmasını engellemek için
                        child: Text(
                          _breatheText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.water_drop_outlined, color: Colors.white, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      "Krizler genelde 3-5 dakika sürer. Büyük bir bardak su iç ve aklını başka bir şeye odakla.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      days > 0 
                        ? "Tam $days gün $hours saattir başarıyorsun. \nBunu çöpe atmaya değmez!" 
                        : "Daha yeni başladın, ilk günler en zorudur. \nTam şu an direnmeye ihtiyacımız var!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.yellowAccent, 
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
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
