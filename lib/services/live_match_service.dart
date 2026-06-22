import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveMatchData {
  final String score;
  final String clock;
  final String period;
  final String status;
  final String detail;

  LiveMatchData({
    required this.score,
    required this.clock,
    required this.period,
    required this.status,
    required this.detail,
  });

  factory LiveMatchData.fromJson(Map<String, dynamic> json) {
    return LiveMatchData(
      score: json['score']?.toString() ?? '',
      clock: json['clock']?.toString() ?? '',
      period: json['period']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
    );
  }
}

class LiveMatchService {
  // A reactive notifier containing the map of espnId -> LiveMatchData
  static final ValueNotifier<Map<String, LiveMatchData>> liveScoresNotifier = ValueNotifier({});

  /// Fetches the current live scores from Firestore to initialize the state
  /// before the first FCM data message arrives.
  static Future<void> initialize() async {
    try {
      final docSnap = await FirebaseFirestore.instance.collection('system').doc('live_scores').get();
      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        final Map<String, LiveMatchData> initialScores = {};
        data.forEach((key, value) {
          if (value is Map) {
            initialScores[key] = LiveMatchData.fromJson(Map<String, dynamic>.from(value));
          } else if (value is String) {
             // Fallback for old string format
             initialScores[key] = LiveMatchData(score: value, clock: '', period: '', status: '', detail: '');
          }
        });
        liveScoresNotifier.value = initialScores;
      }
    } catch (e) {
      debugPrint("Error initializing LiveMatchService: $e");
    }
  }

  /// Called by WCNotificationService when a silent 'live_ticker' message arrives
  static void updateFromPayload(String payloadStr) {
    try {
      final Map<String, dynamic> payload = jsonDecode(payloadStr);
      final Map<String, LiveMatchData> newScores = Map.from(liveScoresNotifier.value);
      
      payload.forEach((key, value) {
        if (value is Map) {
          newScores[key] = LiveMatchData.fromJson(Map<String, dynamic>.from(value));
        }
      });

      liveScoresNotifier.value = newScores;
    } catch (e) {
      debugPrint("Error parsing live_ticker payload: $e");
    }
  }

  /// Helper to get live data for a specific espnId
  static LiveMatchData? getLiveData(String? espnId) {
    if (espnId == null) return null;
    return liveScoresNotifier.value[espnId];
  }
}
