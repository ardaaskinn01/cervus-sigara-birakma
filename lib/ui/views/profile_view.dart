import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/database_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/notification_service.dart';
import '../../services/review_service.dart';
import '../../services/app_constants.dart';
import '../../services/revenuecat_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../app_colors.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _yearsController;
  late TextEditingController _dailyController;
  late TextEditingController _priceController;

  bool _isLoading = false;
  bool _notificationsEnabled = true;


  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);
    final data = db.localUserData ?? {};
    
    _notificationsEnabled = db.notificationsEnabled;

    
    _nameController = TextEditingController(text: data['originalName']?.toString() ?? '');
    _ageController = TextEditingController(text: data['age']?.toString() ?? '');
    _yearsController = TextEditingController(text: data['yearsSmoking']?.toString() ?? '');
    _dailyController = TextEditingController(text: data['dailyCigarettes']?.toString() ?? '');
    _priceController = TextEditingController(text: data['packPrice']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _yearsController.dispose();
    _dailyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      await db.updateProfile(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        yearsSmoking: int.tryParse(_yearsController.text.trim()),
        dailyCigarettes: int.tryParse(_dailyController.text.trim()),
        packPrice: double.tryParse(_priceController.text.trim().replaceAll(',', '.')),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.update_success'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'profile.error'.tr()}$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleNotifications(bool value) {
    setState(() => _notificationsEnabled = value);
    ref.read(databaseProvider).setNotificationsEnabled(value);
    
    if (value) {
      NotificationService().schedulePeriodicNotifications();
    } else {
      NotificationService().cancelAllNotifications();
    }
  }

  void _showPremiumDialog() {
    final isTr = context.locale.languageCode == 'tr';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium_rounded, size: 56, color: Color(0xFF10B981)),
                const SizedBox(height: 8),
                Text(
                  isTr ? "Quitly Pro" : "Quitly Pro", 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF064E3B))
                ),
                const SizedBox(height: 14),

                // Vurgulu 1 Haftalık Ücretsiz Deneme Hero Banderolü
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTr ? "🎁 7 GÜN ÜCRETSİZ DENEME HAKKI" : "🎁 7-DAY FREE TRIAL INCLUDED",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isTr 
                                  ? "Bugün ₺0.00 ödeyin! İlk 7 gün ücretsiz deneyin, dilediğiniz an iptal edin." 
                                  : "Pay $0.00 today! Try free for 7 days, cancel anytime.",
                              style: const TextStyle(
                                color: Colors.white90,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Özellikler
                _buildPremiumFeatureRow(Icons.check_circle_rounded, isTr ? 'Reklamları Tamamen Kaldır' : 'Remove All Ads'),
                _buildPremiumFeatureRow(Icons.star_rounded, isTr ? 'Sınırsız Kullanım' : 'Unlimited Access'),
                const SizedBox(height: 12),

                // RevenueCat paketler
                FutureBuilder<Offerings?>(
                  future: RevenueCatService.getOfferings(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return Text(isTr ? "Paketler yüklenemedi." : "Packages could not be loaded.", style: const TextStyle(color: Color(0xFF64748B)));
                    }
                    final packages = snapshot.data!.current?.availablePackages ?? [];
                    final monthly  = packages.where((p) => p.packageType == PackageType.monthly).firstOrNull;
                    final yearly   = packages.where((p) => p.packageType == PackageType.annual).firstOrNull;
                    final lifetime = packages.where((p) => p.packageType == PackageType.lifetime).firstOrNull;
                    
                    return Column(children: [
                      if (monthly  != null) 
                        _buildSubCard(
                          package: monthly,
                          title: isTr ? "Aylık Abonelik" : "Monthly Subscription",
                          price: monthly.storeProduct.priceString,
                          subtitle: isTr 
                              ? "7 gün ₺0.00, ardından ${monthly.storeProduct.priceString}/ay" 
                              : "7 days $0.00, then ${monthly.storeProduct.priceString}/month",
                          isPopular: false,
                          hasTrial: true,
                          isTr: isTr,
                        ),
                      if (yearly   != null) 
                        _buildSubCard(
                          package: yearly,
                          title: isTr ? "Yıllık Abonelik" : "Annual Subscription",
                          price: yearly.storeProduct.priceString,
                          subtitle: isTr ? "1 Yıl boyunca geçerlidir" : "Valid for 1 Year",
                          isPopular: true,
                          originalPrice: yearly.storeProduct.currencyCode == 'TRY' ? "799.99 ₺" : "\$49.99",
                          isTr: isTr,
                        ),
                      if (lifetime != null) 
                        _buildSubCard(
                          package: lifetime,
                          title: isTr ? "Ömür Boyu Erişim" : "Lifetime Access",
                          price: lifetime.storeProduct.priceString,
                          subtitle: isTr ? "Tek seferlik ödeme" : "One-time payment",
                          isPopular: false,
                          isSpecialOffer: true,
                          isTr: isTr,
                        ),
                    ]);
                  },
                ),

                const SizedBox(height: 16),
                // Apple Compliance Links
                Column(
                  children: [
                    Text(
                      isTr ? "Abonelik bilgilendirmesi ve koşullar:" : "Subscription info and legal conditions:",
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegalLink(isTr ? "Gizlilik Politikası" : "Privacy Policy", AppConstants.privacyPolicyUrl),
                        const Text("  •  ", style: TextStyle(color: Color(0xFFCBD5E1))),
                        _buildLegalLink(isTr ? "Kullanım Koşulları (EULA)" : "Terms of Use (EULA)", "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async { 
                    Navigator.pop(ctx); 
                    await RevenueCatService.restorePurchases(context, ref); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF475569),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isTr ? 'Satın Alımları Geri Yükle' : 'Restore Purchases', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: Text(isTr ? 'Kapat' : 'Close', style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500))
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFF064E3B), fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String title, String url) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF10B981),
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildSubCard({
    required Package package,
    required String title,
    required String price,
    required String subtitle,
    required bool isPopular,
    String? originalPrice,
    bool isSpecialOffer = false,
    bool hasTrial = false,
    required bool isTr,
  }) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        await RevenueCatService.purchasePackage(context, ref, package);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasTrial 
              ? const Color(0xFF2563EB).withOpacity(0.08) 
              : (isPopular ? const Color(0xFF10B981).withOpacity(0.1) : Colors.transparent),
          border: Border.all(
            color: hasTrial 
                ? const Color(0xFF2563EB) 
                : (isPopular ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.2)),
            width: hasTrial || isPopular ? 1.8 : 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title, 
                          style: const TextStyle(color: Color(0xFF064E3B), fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasTrial) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            isTr ? "⚡ 1 HAFTA ÜCRETSİZ" : "⚡ 1 WEEK FREE", 
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ] else if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(6)),
                          child: Text(isTr ? "POPÜLER" : "POPULAR", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ] else if (isSpecialOffer) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(6)),
                          child: Text(isTr ? "ÖZEL TEKLİF" : "SPECIAL OFFER", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: hasTrial ? const Color(0xFF1E40AF) : const Color(0xFF64748B), fontSize: 12, fontWeight: hasTrial ? FontWeight.w600 : FontWeight.normal)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasTrial) ...[
                  Text(
                    isTr ? "₺0.00 / 7 Gün" : "$0.00 / 7 Days",
                    style: const TextStyle(color: Color(0xFF2563EB), fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    isTr ? "sonra $price/ay" : "then $price/mo",
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ] else ...[
                  if (originalPrice != null)
                    Text(
                      originalPrice,
                      style: TextStyle(
                        color: const Color(0xFF64748B).withOpacity(0.6),
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.redAccent,
                        decorationThickness: 2.0,
                      ),
                    ),
                  Text(
                    price,
                    style: const TextStyle(color: Color(0xFF059669), fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final isPro = db.isPro;
    final isTr = context.locale.languageCode == 'tr';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('profile.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF064E3B))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Status Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: isPro
                      ? const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: (isPro ? const Color(0xFF0F172A) : const Color(0xFF2563EB)).withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isPro ? Icons.auto_awesome_rounded : Icons.card_giftcard_rounded, 
                        color: Colors.white, 
                        size: 28
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isPro ? (isTr ? 'Quitly PRO Açık' : 'Quitly PRO Active') : 'Quitly PRO', 
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  letterSpacing: -0.5
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!isPro) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isTr ? "1 HAFTA ÜCRETSİZ" : "1 WEEK FREE",
                                    style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 8, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isPro 
                                ? (isTr ? 'Reklamsız deneyimin tadını çıkarın.' : 'Enjoy an ad-free experience.') 
                                : (isTr ? '1 Hafta Ücretsiz Deneme fırsatıyla reklamları kaldırın.' : 'Remove all ads with a 1-Week Free Trial.'), 
                            style: const TextStyle(
                              color: Colors.white90, 
                              fontSize: 12,
                              fontWeight: FontWeight.w500
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                    if (!isPro)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton(
                          onPressed: _showPremiumDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1D4ED8),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            isTr ? '7 Gün Ücretsiz' : '7 Days Free', 
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bilgi Güncelleme Segmenti
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text('profile.personal_info'.tr(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondaryText, letterSpacing: 1.2)),
              ),
              Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12)),
                    ],
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildFlatField('onboarding.name_label'.tr(), _nameController, Icons.badge_rounded, TextInputType.name),
                      const Divider(color: AppColors.border, height: 1, indent: 56, endIndent: 24),
                      _buildFlatField('onboarding.age_label'.tr(), _ageController, Icons.cake_rounded, TextInputType.number),
                      const Divider(color: AppColors.border, height: 1, indent: 56, endIndent: 24),
                      _buildFlatField('onboarding.years_smoking_label'.tr(), _yearsController, Icons.history_rounded, TextInputType.number),
                      const Divider(color: AppColors.border, height: 1, indent: 56, endIndent: 24),
                      _buildFlatField('onboarding.daily_cig_label'.tr(), _dailyController, Icons.smoking_rooms_rounded, TextInputType.number),
                      const Divider(color: AppColors.border, height: 1, indent: 56, endIndent: 24),
                      _buildFlatField('onboarding.pack_price_label'.tr(), _priceController, Icons.attach_money_rounded, const TextInputType.numberWithOptions(decimal: true)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Güncelleme Butonu
              AnimatedContainer(
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
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('profile.save_btn'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 48),

              // Ayarlar Segmenti
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text('profile.app_settings'.tr(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondaryText, letterSpacing: 1.2)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12)),
                  ],
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: const Text('profile.language', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))).tr(),
                      trailing: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(value: 'tr', label: Text('TR')),
                          ButtonSegment<String>(value: 'en', label: Text('EN')),
                        ],
                        selected: {ref.watch(languageProvider).languageCode},
                        onSelectionChanged: (Set<String> newSelection) {
                          ref.read(languageProvider.notifier).changeLanguage(context, newSelection.first);
                        },
                      ),
                    ),
                    const Divider(color: AppColors.border, height: 1, indent: 70, endIndent: 24),
                    SwitchListTile(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFCBD5E1),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                      ),
                      title: const Text('profile.notifications_title', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))).tr(),
                      subtitle: Text('profile.notifications_desc'.tr(), style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                    ),
                    const Divider(color: AppColors.border, height: 1, indent: 70, endIndent: 24),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      onTap: () async {
                        await ReviewService().requestReview();
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.star_rounded, color: Color(0xFFD97706)),
                      ),
                      title: const Text('profile.rate_title', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))).tr(),
                      subtitle: Text('profile.rate_desc'.tr(), style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText),
                    ),
                    const Divider(color: AppColors.border, height: 1, indent: 70, endIndent: 24),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      onTap: () async {
                        final url = Uri.parse(AppConstants.privacyPolicyUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF2563EB)),
                      ),
                      title: const Text('profile.privacy_policy', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))).tr(),
                      trailing: const Icon(Icons.open_in_new_rounded, color: AppColors.secondaryText, size: 20),
                    ),
                    const Divider(color: AppColors.border, height: 1, indent: 70, endIndent: 24),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      onTap: () async {
                        final url = Uri.parse(
                          Platform.isIOS 
                            ? 'https://apps.apple.com/tr/developer/cervus-digital/id1889669486'
                            : 'https://play.google.com/store/apps/developer?id=Cervus+App+Studio'
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.apps_rounded, color: Color(0xFF64748B)),
                      ),
                      title: const Text('profile.other_apps', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))).tr(),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlatField(String label, TextEditingController controller, IconData icon, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: const Color(0xFFCBD5E1), size: 22),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'onboarding.required_error'.tr() : null,
      ),
    );
  }
}
