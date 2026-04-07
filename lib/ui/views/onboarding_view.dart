import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../services/notification_service.dart';
import 'main_view.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _yearsController = TextEditingController();
  final _dailyController = TextEditingController();
  final _priceController = TextEditingController();
  final _daysSinceQuittingController = TextEditingController();

  bool _isLoading = false;
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _yearsController.dispose();
    _dailyController.dispose();
    _priceController.dispose();
    _daysSinceQuittingController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Validate that the current field is filled
    if (_currentIndex == 0 && _nameController.text.trim().isEmpty) return;
    if (_currentIndex == 1 && _ageController.text.trim().isEmpty) return;
    if (_currentIndex == 2 && _yearsController.text.trim().isEmpty) return;
    if (_currentIndex == 3 && _dailyController.text.trim().isEmpty) return;
    if (_currentIndex == 4 && _priceController.text.trim().isEmpty) return;

    if (_currentIndex < 5) {
      _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.fastOutSlowIn);
    } else {
      _saveData();
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 600), curve: Curves.fastOutSlowIn);
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      await db.registerUser(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        yearsSmoking: int.parse(_yearsController.text.trim()),
        dailyCigarettes: int.parse(_dailyController.text.trim()),
        packPrice: double.parse(_priceController.text.trim().replaceAll(',', '.')),
        daysSinceQuitting: int.tryParse(_daysSinceQuittingController.text.trim()) ?? 0,
      );

      // Zamanlayıcıları/Bildirimleri İlk Kez Başlat
      NotificationService().schedulePeriodicNotifications();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainView()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FCF9), // Daha yumuşak premium beyaz
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 24),
              // İlerleme noktaları (Animated Dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 32 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Kaydırmayı butonla yapalım
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  children: [
                    _buildStepCard(
                      icon: Icons.spa_rounded,
                      title: 'Yeni Bir Başlangıç',
                      subtitle: 'Sana nasıl hitap edelim?',
                      input: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w300, color: Color(0xFF1B5E20), letterSpacing: -1),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(fontSize: 42, fontWeight: FontWeight.w200, color: Colors.grey.shade300),
                          border: InputBorder.none,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Boş bırakılamaz' : null,
                      ),
                    ),
                    _buildStepCard(
                      icon: Icons.cake_rounded,
                      title: 'Yaşın Kaç?',
                      subtitle: 'Sağlık verilerini yaşınıza göre analiz edeceğiz.',
                      input: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Color(0xFF1B5E20), letterSpacing: -1),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(fontSize: 56, fontWeight: FontWeight.w200, color: Colors.grey.shade300),
                          border: InputBorder.none,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Boş bırakılamaz' : null,
                      ),
                    ),
                    _buildStepCard(
                      icon: Icons.history_rounded,
                      title: 'Geçmişi Geride Bırak',
                      subtitle: 'Kaç yıldır sigara içiyorsun?',
                      input: TextFormField(
                        controller: _yearsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Color(0xFF1B5E20), letterSpacing: -1),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(fontSize: 56, fontWeight: FontWeight.w200, color: Colors.grey.shade300),
                          border: InputBorder.none,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Boş bırakılamaz' : null,
                      ),
                    ),
                    _buildStepCard(
                      icon: Icons.smoking_rooms_rounded,
                      title: 'Alışkanlık Analizi',
                      subtitle: 'Günde ortalama kaç dal içiyordun?',
                      input: TextFormField(
                        controller: _dailyController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Color(0xFF1B5E20), letterSpacing: -1),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(fontSize: 56, fontWeight: FontWeight.w200, color: Colors.grey.shade300),
                          border: InputBorder.none,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Boş bırakılamaz' : null,
                      ),
                    ),
                    _buildStepCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Bütçe Odaklı',
                      subtitle: 'Kullandığın paketin fiyatı ne kadar? (TL)',
                      input: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Color(0xFF1B5E20), letterSpacing: -1),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Boş bırakılamaz' : null,
                      ),
                    ),
                    _buildStepCard(
                      icon: Icons.calendar_today_rounded,
                      title: 'Yolculuğun Ne Zaman Başladı?',
                      subtitle: 'Kaç gündür içmiyorsun?',
                      input: TextFormField(
                        controller: _daysSinceQuittingController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Color(0xFF1B5E20), letterSpacing: -1),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: TextStyle(fontWeight: FontWeight.w200, color: Colors.black12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Alt Butonlar
              Padding(
                padding: const EdgeInsets.only(left: 32.0, right: 32.0, bottom: 48.0, top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIndex > 0)
                      TextButton(
                        onPressed: _prevPage,
                        style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
                        child: Text('Geri', style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                      )
                    else
                      const SizedBox(width: 64),
                      
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextPage,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                            _currentIndex == 5 ? 'BAŞLA' : 'İLERİ',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5),
                          ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({required IconData icon, required String title, required String subtitle, required Widget input}) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32.0),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, spreadRadius: 0, offset: const Offset(0, 20)),
            const BoxShadow(color: Colors.white, blurRadius: 10, offset: Offset(-5, -5)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F9F4),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), letterSpacing: -0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // The input field styling will be huge, thin, centralized text.
            input,
          ],
        ),
      ),
    );
  }
}
