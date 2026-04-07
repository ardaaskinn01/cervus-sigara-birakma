import 'dart:ui';
import 'package:flutter/material.dart';
import 'dashboard_view.dart';
import 'health_view.dart';
import 'leaderboard_view.dart';
import 'profile_view.dart';
import '../../services/ad_service.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardView(),
    HealthView(),
    LeaderboardView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    AdService.loadInterstitialAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
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
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
                items: [
                  _buildNavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'Durum', 0),
                  _buildNavItem(Icons.favorite_rounded, Icons.favorite_outline_rounded, 'Sağlık', 1),
                  _buildNavItem(Icons.emoji_events_rounded, Icons.emoji_events_outlined, 'Liderlik', 2),
                  _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profil', 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: AnimatedScale(
          scale: isSelected ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.bounceOut,
          child: Icon(
            isSelected ? activeIcon : inactiveIcon,
            size: 26,
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade400,
          ),
        ),
      ),
      label: label,
    );
  }
}

