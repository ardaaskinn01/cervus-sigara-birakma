import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../services/notification_service.dart';

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
          const SnackBar(content: Text('Profil bilgilerin güncellendi! ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
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
      backgroundColor: const Color(0xFFF4F9F4),
      appBar: AppBar(
        title: const Text('Profil & Ayarlar', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 120), // BottomNav padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bilgi Güncelleme Segmenti
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text('KİŞİSEL BİLGİLER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
              ),
              Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildFlatField('İsim', _nameController, Icons.badge_rounded, TextInputType.name),
                      Divider(color: Colors.grey.shade100, height: 1, indent: 56, endIndent: 24),
                      _buildFlatField('Yaş', _ageController, Icons.cake_rounded, TextInputType.number),
                      Divider(color: Colors.grey.shade100, height: 1, indent: 56, endIndent: 24),
                      _buildFlatField('Kaç Yıldır İçiyorsun?', _yearsController, Icons.history_rounded, TextInputType.number),
                      Divider(color: Colors.grey.shade100, height: 1, indent: 56, endIndent: 24),
                      _buildFlatField('Günde Kaç Dal?', _dailyController, Icons.smoking_rooms_rounded, TextInputType.number),
                      Divider(color: Colors.grey.shade100, height: 1, indent: 56, endIndent: 24),
                      _buildFlatField('Güncel Paket Fiyatı (TL)', _priceController, Icons.attach_money_rounded, const TextInputType.numberWithOptions(decimal: true)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Güncelleme Butonu (Gradient & Glow)
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
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('BİLGİLERİ KAYDET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 48),

              // Ayarlar Segmenti
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text('UYGULAMA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12)),
                  ],
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF4CAF50),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF1F8F1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF4CAF50)),
                      ),
                      title: const Text('Motivasyon Bildirimleri', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                      subtitle: Text('Günde 2 kez destek mesajı al.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ),
                    Divider(color: Colors.grey.shade100, height: 1, indent: 70, endIndent: 24),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      onTap: () async {
                        await NotificationService().showImmediateNotification();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Test bildirimi gönderildi! 🔔'),
                            backgroundColor: Color(0xFF4CAF50),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.send_rounded, color: Color(0xFF4CAF50)),
                      ),
                      title: const Text('Test Bildirimi Gönder', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                      subtitle: Text('Bildirimlerin çalışıp çalışmadığını test et.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ),
                    Divider(color: Colors.grey.shade100, height: 1, indent: 70, endIndent: 24),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Destekleriniz için teşekkürler! ❤️', style: TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: const Color(0xFF1B5E20),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ));
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.star_rounded, color: Colors.amber),
                      ),
                      title: const Text('Bizi Puanlayın', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                      subtitle: Text('Uygulamayı destekleyin.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
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
        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1B5E20), fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'Gerekli alan' : null,
      ),
    );
  }
}
