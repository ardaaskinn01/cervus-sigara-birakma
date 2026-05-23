import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/database_provider.dart';
import '../app_colors.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  DateTime _focusedMonth = DateTime.now();
  Set<String> _smokedDays = {};
  Set<String> _crisisDays = {};
  DateTime? _selectedDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      // First load from local cache for instant display
      _smokedDays = db.smokedDays.toSet();
      _crisisDays = db.crisisDays.toSet();
      setState(() => _isLoading = false);

      // Then fetch fresh from Firestore
      final uid = db.currentFirebaseId;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _smokedDays = Set<String>.from((data['smokedDays'] as List<dynamic>? ?? []).map((e) => e.toString()));
          _crisisDays = Set<String>.from((data['crisisDays'] as List<dynamic>? ?? []).map((e) => e.toString()));
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      debugPrint('❌ Takvim verisi yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  void _prevMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
        _selectedDay = null;
      });

  void _nextMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
        _selectedDay = null;
      });

  /// Returns color for a given day:
  /// Red (smoked) > Yellow (crisis) > Green (smoke-free) > Grey (future/before start)
  Color? _dayColor(DateTime day, DateTime firstStart) {
    if (day.isAfter(DateTime.now())) return null; // future
    final key = _dateKey(day);
    final dayOnly = DateTime(day.year, day.month, day.day);
    final startOnly = DateTime(firstStart.year, firstStart.month, firstStart.day);
    if (dayOnly.isBefore(startOnly)) return null; // before user started the app

    if (_smokedDays.contains(key)) return const Color(0xFFEF4444); // red
    if (_crisisDays.contains(key)) return const Color(0xFFF59E0B); // yellow
    return const Color(0xFF22C55E); // green (smoke-free)
  }

  int _calculateMaxStreak(DateTime firstStart) {
    DateTime start = DateTime(firstStart.year, firstStart.month, firstStart.day);
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    if (_smokedDays.isEmpty) {
      return today.difference(start).inDays;
    }
    
    List<DateTime> relapses = _smokedDays.map((d) {
       final parts = d.split('-');
       return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }).toList();
    relapses.sort();
    
    int maxDays = 0;
    DateTime currentStart = start;
    
    for (var relapse in relapses) {
      int streak = relapse.difference(currentStart).inDays;
      if (streak > maxDays) maxDays = streak;
      currentStart = relapse.add(const Duration(days: 1)); // New streak starts day after relapse
    }
    
    int currentStreak = today.isBefore(currentStart) ? 0 : today.difference(currentStart).inDays;
    if (currentStreak > maxDays) maxDays = currentStreak;
    
    return maxDays;
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final userData = db.localUserData;
    final firstStart = db.firstRegistrationDate; // Use first start for history
    
    DateTime currentStartDate = DateTime.now();
    if (userData != null && userData['registrationDate'] != null) {
      try {
        currentStartDate = DateTime.parse(userData['registrationDate'].toString());
      } catch (_) {}
    }

    final maxStreak = _calculateMaxStreak(firstStart);

    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final monthEnd = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = monthStart.weekday % 7; // 0=Sun, 6=Sat (Mon=1 so Mon%7=1)
    // Use Monday as first day: 1=Mon..7=Sun -> shift so Mon=0
    final firstDayOffset = (monthStart.weekday - 1) % 7;
    final totalCells = firstDayOffset + monthEnd.day;
    final rowCount = (totalCells / 7).ceil();

    final monthNames = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    final dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Aktivite Takvimi',
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF064E3B))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF064E3B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF064E3B)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    // Month navigator
                    _buildMonthNavigator(monthNames),
                    const SizedBox(height: 16),

                    // Calendar card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Day labels row
                          Row(
                            children: dayLabels.map((d) => Expanded(
                              child: Center(
                                child: Text(d,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.secondaryText,
                                        letterSpacing: 0.5)),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 8),

                          // Calendar grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                            ),
                            itemCount: rowCount * 7,
                            itemBuilder: (context, index) {
                              final dayNum = index - firstDayOffset + 1;
                              if (dayNum < 1 || dayNum > monthEnd.day) {
                                return const SizedBox.shrink();
                              }
                              final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                              final color = _dayColor(day, firstStart);
                              final isSelected = _selectedDay != null &&
                                  _selectedDay!.year == day.year &&
                                  _selectedDay!.month == day.month &&
                                  _selectedDay!.day == day.day;
                              final isToday = day.year == DateTime.now().year &&
                                  day.month == DateTime.now().month &&
                                  day.day == DateTime.now().day;

                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedDay = day);
                                  _showDayDetail(context, day, firstStart);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: color?.withOpacity(isSelected ? 1.0 : 0.85) ??
                                        (isToday
                                            ? AppColors.primary.withOpacity(0.08)
                                            : Colors.transparent),
                                    borderRadius: BorderRadius.circular(10),
                                    border: isSelected
                                        ? Border.all(color: const Color(0xFF064E3B), width: 2)
                                        : isToday && color == null
                                            ? Border.all(color: AppColors.primary, width: 1.5)
                                            : null,
                                    boxShadow: color != null && isSelected
                                        ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$dayNum',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isToday || isSelected
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                        color: color != null
                                            ? Colors.white
                                            : isToday
                                                ? AppColors.primary
                                                : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Legend
                    _buildLegend(),
                    const SizedBox(height: 20),

                    // Record Card
                    _buildRecordCard(maxStreak),
                    const SizedBox(height: 20),

                    // Stats summary
                    _buildMonthStats(monthEnd, firstStart),
                    const SizedBox(height: 154), // Spacing for BottomNavBar + Ad
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMonthNavigator(List<String> monthNames) {
    final isCurrentMonth = _focusedMonth.year == DateTime.now().year &&
        _focusedMonth.month == DateTime.now().month;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _prevMonth,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF064E3B), size: 22),
          ),
        ),
        Column(
          children: [
            Text(
              monthNames[_focusedMonth.month - 1],
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF064E3B)),
            ),
            Text(
              '${_focusedMonth.year}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
            ),
          ],
        ),
        IconButton(
          onPressed: isCurrentMonth ? null : _nextMonth,
          icon: AnimatedOpacity(
            opacity: isCurrentMonth ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF064E3B), size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(const Color(0xFF22C55E), 'Temiz Gün'),
          _legendItem(const Color(0xFFF59E0B), 'Kriz Günü'),
          _legendItem(const Color(0xFFEF4444), 'Sigara İçildi'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
      ],
    );
  }

  Widget _buildRecordCard(int maxStreak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE), // Very light blue
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7DD3FC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0EA5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'En Uzun Sigarasız Süreç',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0369A1),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$maxStreak',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0C4A6E),
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        'Gün',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStats(DateTime monthEnd, DateTime startDate) {
    int freeCount = 0, smokedCount = 0, crisisCount = 0;
    for (int d = 1; d <= monthEnd.day; d++) {
      final day = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      if (day.isAfter(DateTime.now())) continue;
      final dayOnly = DateTime(day.year, day.month, day.day);
      final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
      if (dayOnly.isBefore(startOnly)) continue;

      final key = _dateKey(day);
      if (_smokedDays.contains(key)) {
        smokedCount++;
      } else if (_crisisDays.contains(key)) {
        crisisCount++;
        freeCount++;
      } else {
        freeCount++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bu Ay İstatistikleri',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF064E3B))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statCard('$freeCount', 'Temiz\nGün', const Color(0xFF22C55E))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('$crisisCount', 'Kriz\nGünü', const Color(0xFFF59E0B))),
              const SizedBox(width: 12),
              Expanded(child: _statCard('$smokedCount', 'Sigara\nİçilen', const Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569), height: 1.3)),
        ],
      ),
    );
  }

  void _showDayDetail(BuildContext context, DateTime day, DateTime startDate) {
    final key = _dateKey(day);
    final dayOnly = DateTime(day.year, day.month, day.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final isFuture = day.isAfter(DateTime.now());
    final isBeforeStart = dayOnly.isBefore(startOnly);

    String status;
    Color statusColor;
    IconData statusIcon;

    if (isFuture) {
      status = 'Henüz gelmedi';
      statusColor = AppColors.secondaryText;
      statusIcon = Icons.schedule_rounded;
    } else if (isBeforeStart) {
      status = 'Bırakmadan önceki dönem';
      statusColor = AppColors.secondaryText;
      statusIcon = Icons.history_rounded;
    } else if (_smokedDays.contains(key)) {
      status = '❌ Bu gün sigara içildi';
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel_rounded;
    } else if (_crisisDays.contains(key)) {
      status = '⚠️ Kriz yaşandı ama direndi!';
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.warning_amber_rounded;
    } else {
      status = '✅ Temiz bir gün!';
      statusColor = const Color(0xFF22C55E);
      statusIcon = Icons.check_circle_rounded;
    }

    final dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final monthNames = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, -5)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(statusIcon, size: 48, color: statusColor),
            const SizedBox(height: 12),
            Text(
              '${dayNames[day.weekday - 1]}, ${day.day} ${monthNames[day.month - 1]} ${day.year}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: statusColor, height: 1.3),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
