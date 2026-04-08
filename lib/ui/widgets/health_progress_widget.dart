import 'package:flutter/material.dart';
import '../../models/health_goal.dart';

class HealthProgressWidget extends StatelessWidget {
  final Duration timeElapsed;
  final HealthGoal goal;

  final int yearsSmoking;

  const HealthProgressWidget({
    super.key,
    required this.timeElapsed,
    required this.goal,
    required this.yearsSmoking,
  });

  @override
  Widget build(BuildContext context) {
    final adjustedTarget = goal.getAdjustedDuration(yearsSmoking);
    
    // Linear progress (0.0 to 1.0)
    double rawProgress = timeElapsed.inSeconds / adjustedTarget.inSeconds;
    if (rawProgress > 1.0) rawProgress = 1.0;
    if (rawProgress < 0.0) rawProgress = 0.0;
    
    // Quadratic Progress: t^2 modeli ile daha gerçekçi hız
    // Bu sayede %100'e ulaşmak aynı vakti alır ama ara değerler daha yavaş artar.
    double displayProgress = rawProgress * rawProgress;
    final int percentage = (displayProgress * 100).toInt();
    final bool isCompleted = rawProgress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isCompleted ? const Color(0xFF4CAF50).withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Kısım: Başlık ve Yüzde
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: isCompleted ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF4CAF50) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? '100%' : '%$percentage',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isCompleted ? Colors.white : const Color(0xFF2E7D32),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            // Orta Kısım: Açıklama
            Text(
              goal.description,
              style: TextStyle(
                color: isCompleted ? Colors.grey.shade700 : Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            // Alt Kısım: Progress Bar ve Kalan Süre
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: displayProgress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? const Color(0xFF4CAF50) : const Color(0xFF81C784),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCompleted ? 'Hedefe Ulaşıldı 🎉' : 'Hedef: ${_formatDuration(adjustedTarget)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? const Color(0xFF4CAF50) : Colors.grey.shade400,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays >= 365) return '${d.inDays ~/ 365} YIL';
    if (d.inDays > 0) return '${d.inDays} GÜN';
    if (d.inHours > 0) return '${d.inHours} SAAT';
    return '${d.inMinutes} DAKİKA';
  }
}
