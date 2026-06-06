import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match.dart';

class AlertService {
  static const String _alertsKey = 'wc2026_alerts';

  /// Load all alerts from SharedPreferences. Returns a Map of matchId -> alertType.
  static Future<Map<String, String>> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_alertsKey);
    if (jsonStr == null) return {};

    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final Map<String, String> alerts = decoded.map((key, value) => MapEntry(key, value.toString()));

      bool migrated = false;
      final keys = List<String>.from(alerts.keys);
      for (final key in keys) {
        if (key.startsWith('m')) {
          final idNum = int.tryParse(key.substring(1));
          if (idNum != null && idNum <= 72) {
            final val = alerts.remove(key);
            if (val != null) {
              alerts['g_$key'] = val;
              migrated = true;
            }
          }
        }
      }
      if (migrated) {
        await prefs.setString(_alertsKey, jsonEncode(alerts));
      }
      return alerts;
    } catch (_) {
      return {};
    }
  }

  /// Save or remove a match alert.
  static Future<Map<String, String>> saveAlert(String matchId, String alertType) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await loadAlerts();

    alerts[matchId] = alertType;

    final jsonStr = jsonEncode(alerts);
    await prefs.setString(_alertsKey, jsonStr);
    return alerts;
  }

  /// Automatically set 1hour alerts for a team's matches if no alert exists.
  static Future<Map<String, String>> activateAlertsForTeam(String teamCode, List<WorldCupMatch> matches) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await loadAlerts();
    
    bool changed = false;
    final lowerTeamCode = teamCode.toLowerCase();
    for (final match in matches) {
      if (match.t1.toLowerCase() == lowerTeamCode || match.t2.toLowerCase() == lowerTeamCode) {
        if (!alerts.containsKey(match.id)) {
          alerts[match.id] = '1hour';
          changed = true;
        }
      }
    }
    
    if (changed) {
      final jsonStr = jsonEncode(alerts);
      await prefs.setString(_alertsKey, jsonStr);
    }
    return alerts;
  }
}
