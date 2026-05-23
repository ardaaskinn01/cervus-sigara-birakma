import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../services/revenuecat_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'dashboard_view.dart';
import 'health_view.dart';
import 'calendar_view.dart';
import 'profile_view.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardView(),
    const HealthView(),
    const CalendarView(),
    const ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize RevenueCat on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RevenueCatService.init(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BannerAdWidget(
            key: ValueKey(_currentIndex),
            screenIndex: _currentIndex,
          ),
          SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 65,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: BottomNavigationBar(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      selectedItemColor: const Color(0xFF2E7D32),
                      unselectedItemColor: Colors.grey.shade400,
                      showSelectedLabels: true,
                      showUnselectedLabels: false,
                      type: BottomNavigationBarType.fixed,
                      selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.2,
                      ),
                      items: [
                        _buildNavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'dashboard.title'.tr(), 0),
                        _buildNavItem(Icons.favorite_rounded, Icons.favorite_outline_rounded, 'health.title'.tr(), 1),
                        _buildNavItem(Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'calendar.title'.tr(), 2),
                        _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded, 'profile.title'.tr(), 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          size: 24,
        ),
      ),
      label: label,
    );
  }
}
