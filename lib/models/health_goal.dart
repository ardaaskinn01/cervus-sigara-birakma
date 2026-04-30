class HealthGoal {
  final String title;
  final String description;
  final Duration baseDuration;

  const HealthGoal({
    required this.title,
    required this.description,
    required this.baseDuration,
  });

  /// İyileşme süresini karesel artış (quadratic) modeliyle ayarlar.
  /// Sigara içilen yıl arttıkça hasar katlanarak arttığı için iyileşme de o oranda yavaşlar.
  /// Formül: base * (1 + (years^2 / 400))
  /// Örn: 10 yıl -> %25 gecikme, 20 yıl -> %100 (2x) gecikme, 40 yıl -> %400 (5x) gecikme.
  Duration getAdjustedDuration(int yearsSmoking) {
    double penaltyFactor = (yearsSmoking * yearsSmoking) / 400.0;
    
    // Güvenlik sınırı: İyileşme süresini en fazla 10 katına çıkarıyoruz (Örn: 50+ yıl içenler için)
    if (penaltyFactor > 9.0) penaltyFactor = 9.0; 
    
    int originalSeconds = baseDuration.inSeconds;
    int adjustedSeconds = (originalSeconds * (1.0 + penaltyFactor)).toInt();
    
    return Duration(seconds: adjustedSeconds);
  }
}

const List<HealthGoal> healthGoals = [
  HealthGoal(
    title: 'health.goal_0_title',
    description: 'health.goal_0_desc',
    baseDuration: Duration(minutes: 20),
  ),
  HealthGoal(
    title: 'health.goal_1_title',
    description: 'health.goal_1_desc',
    baseDuration: Duration(hours: 8),
  ),
  HealthGoal(
    title: 'health.goal_2_title',
    description: 'health.goal_2_desc',
    baseDuration: Duration(hours: 24),
  ),
  HealthGoal(
    title: 'health.goal_3_title',
    description: 'health.goal_3_desc',
    baseDuration: Duration(hours: 48),
  ),
  HealthGoal(
    title: 'health.goal_4_title',
    description: 'health.goal_4_desc',
    baseDuration: Duration(hours: 72),
  ),
  HealthGoal(
    title: 'health.goal_5_title',
    description: 'health.goal_5_desc',
    baseDuration: Duration(days: 14),
  ),
  HealthGoal(
    title: 'health.goal_6_title',
    description: 'health.goal_6_desc',
    baseDuration: Duration(days: 365),
  ),
  HealthGoal(
    title: 'health.goal_7_title',
    description: 'health.goal_7_desc',
    baseDuration: Duration(days: 1825), // 5 Yıl
  ),
  HealthGoal(
    title: 'health.goal_8_title',
    description: 'health.goal_8_desc',
    baseDuration: Duration(days: 3650), // 10 Yıl
  ),
  HealthGoal(
    title: 'health.goal_9_title',
    description: 'health.goal_9_desc',
    baseDuration: Duration(days: 5475), // 15 Yıl
  ),
];
