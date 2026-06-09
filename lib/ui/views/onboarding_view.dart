import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/database_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/notification_service.dart';
import 'main_view.dart';
import '../app_colors.dart';

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
  
  String _selectedCurrency = 'TRY';

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
    if (_currentIndex == 1) {
      final db = ref.read(databaseProvider);
      db.setPrivacyAccepted(true);
    }
    
    // Validations
    if (_currentIndex == 3 && _nameController.text.trim().isEmpty) return;
    if (_currentIndex == 4 && _ageController.text.trim().isEmpty) return;
    if (_currentIndex == 5 && _yearsController.text.trim().isEmpty) return;
    if (_currentIndex == 6 && _dailyController.text.trim().isEmpty) return;
    if (_currentIndex == 7 && _priceController.text.trim().isEmpty) return;

    if (_currentIndex < 8) {
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
        currency: _selectedCurrency,
      );

      NotificationService().schedulePeriodicNotifications();
      NotificationService().updateTokenToDatabase();
      db.logAppEntry();

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  9,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 32 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? AppColors.primary : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  children: [
                    _buildLanguageCard(),
                    _buildPrivacyPolicyCard(),
                    _buildCurrencyCard(),
                    _buildStepCard(
                      icon: Icons.spa_rounded,
                      title: 'onboarding.welcome_title'.tr(),
                      subtitle: 'onboarding.welcome_desc'.tr(),
                      input: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w300, color: Color(0xFF0F172A), letterSpacing: -1),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintStyle: const TextStyle(fontSize: 42, fontWeight: FontWeight.w200, color: Color(0xFFE2E8F0)),
                          border: InputBorder.none,
                          hintText: 'onboarding.name_label'.tr(),
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _nextPage(),
                        validator: (v) => v == null || v.trim().isEmpty ? 'onboarding.required_error'.tr() : null,
                      ),
                    ),
                    _buildStepCard(
                      icon: Icons.cake_rounded,
                      title: 'onboarding.age_label'.tr(),
                      subtitle: 'onboarding.age_desc'.tr(),
                      input: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Color(0xFF0F172A), letterSpacing: -1),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintStyle: TextStyle(fontSize: 56, fontWeight: FontWeight.w200, color: Color(0xFFE2E8F0)),
                          border: InputBorder.none,
                          hintText: '00',
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _nextPage(),
                        validator: (v) => v == null || v.isEmpty ? 'onboarding.required_error'.tr() : null,
                      ),
                    ),
                    _buildStepCard(
                      icon: Icons.history_rounded,
                      title: 'onboarding.years_smoking_label'.tr(),
                      subtitle: 'onboarding.years_desc'.tr(),
                      input: TextFormField(
                        controller: _yearsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Color(0xFF0F172A), letterSpacing: -1),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintStyle: TextStyle(fontSize: 56, fontWeight: FontWeight.w200, color: Color(0xFFE2E8F0)),
                          border: InputBorder.none,
                          hintText: '0',
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _nextPage(),
                        validator: (v) => v == null || v.isEmpty ? 'onboarding.required_error'.tr() : null,
                      ),
                    ),
                    _buildStepCard(
                      icon: Icons.smoking_rooms_rounded,
                      title: 'onboarding.daily_cig_label'.tr(),
                      subtitle: 'onboarding.daily_desc'.tr(),
                      input: TextFormField(
                        controller: _dailyController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Color(0xFF0F172A), letterSpacing: -1),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintStyle: TextStyle(fontSize: 56, fontWeight: FontWeight.w200, color: Color(0xFFE2E8F0)),
                          border: InputBorder.none,
                          hintText: '0',
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _nextPage(),
                        validator: (v) => v == null || v.isEmpty ? 'onboarding.required_error'.tr() : null,
                      ),
                    ),
                    _buildStepCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'onboarding.pack_price_label'.tr(),
                      subtitle: 'onboarding.price_desc'.tr(),
                      input: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Color(0xFF0F172A), letterSpacing: -1),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: const TextStyle(fontWeight: FontWeight.w200, color: Color(0xFFE2E8F0)),
                          suffixText: _selectedCurrency == 'TRY' ? '₺' : (_selectedCurrency == 'USD' ? '\$' : '€'),
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _nextPage(),
                        validator: (v) => v == null || v.isEmpty ? 'onboarding.required_error'.tr() : null,
                      ),
                    ),
                    _buildStepCard(
                      icon: Icons.calendar_today_rounded,
                      title: 'onboarding.days_since_label'.tr(),
                      subtitle: 'onboarding.days_desc'.tr(),
                      input: TextFormField(
                        controller: _daysSinceQuittingController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Color(0xFF0F172A), letterSpacing: -1),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: TextStyle(fontWeight: FontWeight.w200, color: Color(0xFFE2E8F0)),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _nextPage(),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 32.0, right: 32.0, bottom: 48.0, top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIndex > 0)
                      TextButton(
                        onPressed: _prevPage,
                        style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
                        child: Text('onboarding.back_btn'.tr(), style: const TextStyle(fontSize: 18, color: AppColors.secondaryText, fontWeight: FontWeight.w600)),
                      ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF4ADE80), AppColors.primary]),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _nextPage,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                _currentIndex == 8 ? 'onboarding.start_btn'.tr() :
                                _currentIndex == 1 ? 'splash.privacy_policy.accept_btn'.tr() : 'onboarding.next_btn'.tr(),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                              ),
                          ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32.0),
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, spreadRadius: 0, offset: const Offset(0, 20)),
                  ],
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                      ),
                      child: Icon(icon, size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 15, color: AppColors.secondaryText, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    input,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32.0),
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 20)),
                  ],
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: 32),
                    Text(
                      'profile.language'.tr(),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _buildSelectionItem('tr', 'Türkçe', context.locale.languageCode == 'tr', () {
                       ref.read(languageProvider.notifier).changeLanguage(context, 'tr');
                    }),
                    const SizedBox(height: 16),
                    _buildSelectionItem('en', 'English', context.locale.languageCode == 'en', () {
                       ref.read(languageProvider.notifier).changeLanguage(context, 'en');
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32.0),
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 20)),
                  ],
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payments_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: 32),
                    Text(
                      'onboarding.currency_title'.tr(),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'onboarding.currency_desc'.tr(),
                      style: const TextStyle(fontSize: 15, color: AppColors.secondaryText, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'onboarding.currency_warning'.tr(),
                      style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _buildSelectionItem('TRY', 'Türk Lirası (₺)', _selectedCurrency == 'TRY', () {
                      setState(() => _selectedCurrency = 'TRY');
                    }),
                    const SizedBox(height: 16),
                    _buildSelectionItem('USD', 'Dollar (\$)', _selectedCurrency == 'USD', () {
                      setState(() => _selectedCurrency = 'USD');
                    }),
                    const SizedBox(height: 16),
                    _buildSelectionItem('EUR', 'Euro (€)', _selectedCurrency == 'EUR', () {
                      setState(() => _selectedCurrency = 'EUR');
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionItem(String value, String label, bool isSelected, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ),
    );
  }

  Widget _buildPrivacyPolicyCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 20)),
              ],
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'splash.privacy_policy.title'.tr(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 16),
                _PolicySection(
                  title: 'splash.privacy_policy.p1_title'.tr(),
                  content: 'splash.privacy_policy.p1_desc'.tr(),
                ),
                _PolicySection(
                  title: 'splash.privacy_policy.p2_title'.tr(),
                  content: 'splash.privacy_policy.p2_desc'.tr(),
                ),
                _PolicySection(
                  title: 'splash.privacy_policy.p3_title'.tr(),
                  content: 'splash.privacy_policy.p3_desc'.tr(),
                ),
                _PolicySection(
                  title: 'splash.privacy_policy.p4_title'.tr(),
                  content: 'splash.privacy_policy.p4_desc'.tr(),
                ),
                _PolicySection(
                  title: 'splash.privacy_policy.p5_title'.tr(),
                  content: 'splash.privacy_policy.p5_desc'.tr(),
                ),
                const SizedBox(height: 20),
                Text(
                  'splash.privacy_policy.footer'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
