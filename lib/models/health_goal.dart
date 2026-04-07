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
    title: 'Kalp Ritmi Düzelir',
    description: 'Kan basıncı ve nabız normale döner. El ve ayak sıcaklığı artar.',
    baseDuration: Duration(minutes: 20),
  ),
  HealthGoal(
    title: 'Karbonmonoksit Temizlenir',
    description: 'Kandaki karbonmonoksit seviyesi normale döner, oksijen seviyesi artar.',
    baseDuration: Duration(hours: 8),
  ),
  HealthGoal(
    title: 'Kalp Krizi Riski Azalır',
    description: 'Vücut sistemleri rahatlar, kalp krizi geçirme riski düşmeye başlar.',
    baseDuration: Duration(hours: 24),
  ),
  HealthGoal(
    title: 'Tat ve Koku Alma Artar',
    description: 'Sinir uçları kendini onarmaya başlar. Tat ve koku alma yeteneği güçlenir.',
    baseDuration: Duration(hours: 48),
  ),
  HealthGoal(
    title: 'Rahat Nefes Alınır',
    description: 'Akciğer kapasitesi artar ve solunum yolları gevşer. Nefes darlığı azalır.',
    baseDuration: Duration(hours: 72),
  ),
  HealthGoal(
    title: 'Kan Dolaşımı İyileşir',
    description: 'Kan dolaşımı ve akciğer fonksiyonları %30 oranında artış gösterir.',
    baseDuration: Duration(days: 14),
  ),
  HealthGoal(
    title: 'Hastalık Riski Yarıya İner',
    description: 'Koroner kalp hastalığı riski, sigara içen birine göre yarı yarıya düşer.',
    baseDuration: Duration(days: 365),
  ),
];
