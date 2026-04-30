import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Box _userBox;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _userBox = await Hive.openBox('userBox');
    _initialized = true;
  }

  /// Finds a unique ID by appending a number if the base name already exists.
  Future<String> _getUniqueFirebaseId(String baseName) async {
    String currentName = baseName.trim().replaceAll(' ', '_').toLowerCase();
    int suffix = 2; 
    bool isUnique = false;
    String candidateName = currentName;

    while (!isUnique) {
      final docSnapshot = await _firestore.collection('users').doc(candidateName).get();
      if (!docSnapshot.exists) {
        isUnique = true;
      } else {
        candidateName = '$currentName$suffix';
        suffix++;
      }
    }

    return candidateName;
  }

  /// Registers user without auth, saves to Firestore and Hive
  Future<String> registerUser({
    required String name,
    required int age,
    required int yearsSmoking,
    required int dailyCigarettes,
    required double packPrice,
    required int daysSinceQuitting,
    String currency = 'TRY',
  }) async {
    try {
      final String uniqueId = await _getUniqueFirebaseId(name);

      final now = DateTime.now();
      final registrationDate = now.subtract(Duration(days: daysSinceQuitting));

      final Map<String, dynamic> userData = {
        'id': uniqueId,
        'originalName': name,
        'age': age,
        'yearsSmoking': yearsSmoking,
        'dailyCigarettes': dailyCigarettes,
        'packPrice': packPrice,
        'currency': currency,
        'registrationDate': Timestamp.fromDate(registrationDate),
        'isPrivacyAccepted': true,
      };

      await _firestore.collection('users').doc(uniqueId).set(userData);

      final localData = Map<String, dynamic>.from(userData);
      localData['registrationDate'] = registrationDate.toIso8601String(); 
      
      await _userBox.put('userData', localData);
      await _userBox.put('firebaseId', uniqueId);
      await _userBox.put('isRegistered', true);

      return uniqueId;
    } catch (e) {
      throw Exception('Kullanıcı kaydedilirken bir hata oluştu: $e');
    }
  }

  /// Resets the user's smoke-free timer to now in both Hive and Firestore
  Future<void> resetSmokingTimer() async {
    try {
      final String? uniqueId = currentFirebaseId;
      final Map<dynamic, dynamic>? currentLocalData = localUserData;

      if (uniqueId == null || currentLocalData == null) return;

      final now = DateTime.now();
      final nowStr = now.toIso8601String();

      await _firestore.collection('users').doc(uniqueId).update({
        'registrationDate': FieldValue.serverTimestamp(),
      });

      final newLocalData = Map<String, dynamic>.from(currentLocalData);
      newLocalData['registrationDate'] = nowStr;
      await _userBox.put('userData', newLocalData);
    } catch (e) {
      throw Exception('Sayaç sıfırlanırken hata oluştu: $e');
    }
  }

  // Getters for Local Data
  bool get isRegistered => _userBox.get('isRegistered', defaultValue: false);
  bool get isPrivacyAccepted => _userBox.get('isPrivacyAccepted', defaultValue: false);
  String? get currentFirebaseId => _userBox.get('firebaseId');
  Map<dynamic, dynamic>? get localUserData => _userBox.get('userData');

  // Setters
  Future<void> setPrivacyAccepted(bool value) async => _userBox.put('isPrivacyAccepted', value);

  // Preferences
  bool get notificationsEnabled => _userBox.get('notificationsEnabled', defaultValue: true);
  Future<void> setNotificationsEnabled(bool value) async => _userBox.put('notificationsEnabled', value);

  // Localization & Currency
  String? get localeCode => _userBox.get('localeCode');
  Future<void> setLocale(String code) async => _userBox.put('localeCode', code);

  String get currency => localUserData?['currency'] ?? 'TRY';
  
  String get currencySymbol {
    switch (currency) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'TRY':
      default: return '₺';
    }
  }

  /// Güncellemeleri Kaydet (Profil Ekranı İçin)
  Future<void> updateProfile({
    String? name,
    int? age,
    int? yearsSmoking,
    int? dailyCigarettes,
    double? packPrice,
    String? currency,
  }) async {
    final String? uniqueId = currentFirebaseId;
    final Map<dynamic, dynamic>? currentLocalData = localUserData;

    if (uniqueId == null || currentLocalData == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['originalName'] = name;
    if (age != null) updates['age'] = age;
    if (yearsSmoking != null) updates['yearsSmoking'] = yearsSmoking;
    if (dailyCigarettes != null) updates['dailyCigarettes'] = dailyCigarettes;
    if (packPrice != null) updates['packPrice'] = packPrice;
    if (currency != null) updates['currency'] = currency;

    if (updates.isEmpty) return;

    await _firestore.collection('users').doc(uniqueId).update(updates);

    final newLocalData = Map<String, dynamic>.from(currentLocalData);
    newLocalData.addAll(updates);
    await _userBox.put('userData', newLocalData);
  }

  Stream<void> get userChanges => _userBox.watch(key: 'userData');

  Future<void> logAppEntry() async {
    try {
      final String? uniqueId = currentFirebaseId;
      if (uniqueId == null) return;

      final now = DateTime.now();
      final String dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final String timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      final String docId = "${dateStr}_${timeStr.replaceAll(':', '-')}";

      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String version = "${packageInfo.version}+${packageInfo.buildNumber}";

      await _firestore.collection('users').doc(uniqueId).update({
        'enterCount': FieldValue.increment(1),
      });

      await _firestore
          .collection('users')
          .doc(uniqueId)
          .collection('visits')
          .doc(docId)
          .set({
        'appVersion': version,
        'date': dateStr,
        'platform': Platform.isIOS ? 'iOS' : (Platform.isAndroid ? 'Android' : 'Other'),
        'time': timeStr,
        'timestamp': Timestamp.fromDate(now),
      });
    } catch (e) {
      print('❌ Ziyaret kaydı tutulurken hata: $e');
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      final String? uniqueId = currentFirebaseId;
      if (uniqueId == null) return;

      await _firestore.collection('users').doc(uniqueId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ FCM Token güncellenirken hata: $e');
    }
  }

  Future<void> updateFcmSubscription({required String token, required String topic}) async {
    try {
      final String? uniqueId = currentFirebaseId;
      if (uniqueId == null) return;

      await _firestore.collection('users').doc(uniqueId).update({
        'fcmToken': token,
        'fcmTopic': topic,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ FCM Abonelik güncellenirken hata: $e');
    }
  }
}
