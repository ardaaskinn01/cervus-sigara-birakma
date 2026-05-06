import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// 🚀 DASHBOARD SERVICE (ULTRA-SAFE REST EDITION)
/// Bu servis ikincil Firebase projesine Flutter SDK (native) üzerinden DEĞİL,
/// doğrudan Google Cloud REST API üzerinden erişir. 
/// Bu sayede iOS tarafındaki "Multiple Firebase App" çakışması ve çökme (Abort Trap 6) 
/// riski fiziksel olarak imkansız hale getirilmiştir.
class DashboardService with WidgetsBindingObserver {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  bool _isInitialized = false;
  final String _projectId = "dashboard-baf3f";
  
  // Oturum takibi değişkenleri
  DateTime? _sessionStartTime;
  String? _currentUserId;
  String? _currentVisitId;
  int _totalSecondsThisSession = 0;
  Timer? _heartbeatTimer;

  Future<void> init() async {
    if (_isInitialized) return;
    
    // Gecikmeli başlatma (UI'ı yormamak için)
    await Future.delayed(const Duration(seconds: 2));
    
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    debugPrint('✅ Dashboard REST API Servisi Hazır (ID: $_projectId)');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopHeartbeat();
      _updateCurrentSessionDuration();
    } else if (state == AppLifecycleState.resumed) {
      _sessionStartTime = DateTime.now();
      _startHeartbeat();
    }
  }

  void startSession(String userId, String visitId) {
    _currentUserId = userId;
    _currentVisitId = visitId;
    _sessionStartTime = DateTime.now();
    _totalSecondsThisSession = 0;
    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _updateCurrentSessionDuration();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Firestore REST API üzerinden veri günceller
  Future<void> _updateCurrentSessionDuration() async {
    if (_currentUserId == null || _currentVisitId == null || _sessionStartTime == null) return;

    final now = DateTime.now();
    final int elapsedSeconds = now.difference(_sessionStartTime!).inSeconds;
    
    if (elapsedSeconds > 0) {
      _totalSecondsThisSession += elapsedSeconds;
      _sessionStartTime = now;
    }

    final String url = "https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/users/$_currentUserId/visits/$_currentVisitId?updateMask.fieldPaths=durationSeconds&updateMask.fieldPaths=lastUpdate";

    try {
      await http.patch(
        Uri.parse(url),
        body: jsonEncode({
          "fields": {
            "durationSeconds": {"integerValue": _totalSecondsThisSession.toString()},
            "lastUpdate": {"timestampValue": DateTime.now().toUtc().toIso8601String()}
          }
        }),
      );
    } catch (e) {
      debugPrint('⚠️ REST Süre Kaydı Hatası: $e');
    }
  }

  /// Firestore REST API üzerinden kullanıcı senkronizasyonu yapar
  Future<void> syncExistingUser(String userId, Map<dynamic, dynamic> userData) async {
    try {
      final String url = "https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/users/$userId";
      
      // Önce kullanıcının varlığını kontrol et
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 404) {
        // Kullanıcı yoksa oluştur
        await http.patch(
          Uri.parse(url),
          body: jsonEncode({
            "fields": {
              "originalName": {"stringValue": userData['originalName'] ?? ""},
              "age": {"stringValue": userData['age']?.toString() ?? ""},
              "platform": {"stringValue": Platform.isIOS ? 'iOS' : 'Android'},
              "appId": {"stringValue": 'quitly'},
              "isMigrated": {"booleanValue": true},
              "migratedAt": {"timestampValue": DateTime.now().toUtc().toIso8601String()},
              "createdAt": {"timestampValue": DateTime.now().toUtc().toIso8601String()},
            }
          }),
        );
        debugPrint('✅ Yeni kullanıcı Dashboard REST API ile kaydedildi.');
      }
    } catch (e) {
      debugPrint('⚠️ REST Sync Hatası: $e');
    }
  }

  /// Dashboard projesine doğrudan ziyaret kaydı atar
  Future<void> logVisit({
    required String userId,
    required String visitId,
    required String appVersion,
    required String platform,
    required String time,
    required String date,
  }) async {
    final String url = "https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/users/$userId/visits/$visitId";

    try {
      await http.patch(
        Uri.parse(url),
        body: jsonEncode({
          "fields": {
            "appVersion": {"stringValue": appVersion},
            "platform": {"stringValue": platform},
            "time": {"stringValue": time},
            "date": {"stringValue": date},
            "appId": {"stringValue": 'quitly'},
            "timestamp": {"timestampValue": DateTime.now().toUtc().toIso8601String()},
          }
        }),
      );
    } catch (e) {
      debugPrint('⚠️ REST Visit Log Hatası: $e');
    }
  }
}
