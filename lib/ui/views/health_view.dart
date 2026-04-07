import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../providers/database_provider.dart';
import '../../models/health_goal.dart';
import '../widgets/health_progress_widget.dart';

class HealthView extends ConsumerStatefulWidget {
  const HealthView({super.key});

  @override
  ConsumerState<HealthView> createState() => _HealthViewState();
}

class _HealthViewState extends ConsumerState<HealthView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider);
    final db = ref.watch(databaseProvider);
    final yearsSmoking = db.localUserData?['yearsSmoking'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      appBar: AppBar(
        title: const Text('İyileşme Süreci', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
          itemCount: healthGoals.length,
          itemBuilder: (context, index) {
            return FadeInSlideFast(
              delay: Duration(milliseconds: 100 + (index * 100)),
              child: HealthProgressWidget(
                timeElapsed: state.timeElapsed,
                goal: healthGoals[index],
                yearsSmoking: yearsSmoking,
              ),
            );
          },
        ),
      ),
    );
  }
}

class FadeInSlideFast extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeInSlideFast({super.key, required this.child, required this.delay});

  @override
  State<FadeInSlideFast> createState() => _FadeInSlideFastState();
}

class _FadeInSlideFastState extends State<FadeInSlideFast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
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
