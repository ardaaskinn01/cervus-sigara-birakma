import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/database_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/notification_service.dart';
import '../../services/review_service.dart';
import '../../services/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('profile.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF064E3B))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
