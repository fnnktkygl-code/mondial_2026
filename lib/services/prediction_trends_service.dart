import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/prediction_trend.dart';

class PredictionTrendsService {
  static final ValueNotifier<Map<String, PredictionTrend>> trendsNotifier = ValueNotifier({});
  static StreamSubscription? _subscription;

  static void init() {
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('system')
        .doc('prediction_trends')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final newTrends = <String, PredictionTrend>{};
        data.forEach((matchId, matchData) {
          if (matchData is Map<String, dynamic>) {
            newTrends[matchId] = PredictionTrend.fromJson(matchData);
          }
        });
        trendsNotifier.value = newTrends;
      }
    });
  }

  static void dispose() {
    _subscription?.cancel();
  }

  static PredictionTrend? getTrend(String matchId) {
    return trendsNotifier.value[matchId];
  }
}
